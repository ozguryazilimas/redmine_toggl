class TogglEntry < ActiveRecord::Base

  ISSUE_MATCHER = /\s*#(\d+)\s*/
  DEFAULT_COLOR = '#000000'.freeze
  EMAIL_VALIDATOR = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  TOGGL_TAG_SEPARATOR = ','.freeze
  TOGGL_MULTI_TAG_SEPARATOR = '|'.freeze


  serialize :toggl_tags, JSON

  belongs_to :user
  belongs_to :issue
  belongs_to :time_entry

  belongs_to :toggl_workspace
  belongs_to :toggl_project
  belongs_to :toggl_task

  scope :without_issue, -> {where(:issue_id => nil)}
  scope :without_project, -> {where(:pid => nil)}
  scope :for_user, -> (user) {where(:user_id => user)}
  scope :for_issue, -> (issue) {where(:issue_id => issue)}
  scope :order_by_start, -> {order(:start)}
  scope :order_by_user, -> {joins(:user).order('users.firstname, users.lastname')}
  scope :started_after, -> (timeval) {where('start > ?', timeval) if timeval}
  scope :stopped_before, -> (timeval) {where('stop <= ?', timeval) if timeval}
  scope :missing_issue, -> {without_issue.order_by_start.order_by_user}
  scope :missing_project, -> {without_project.order_by_start.order_by_user}

  validates_presence_of :user_id, :toggl_id


  def self.report_without_issue(started_after = nil, stopped_before = nil)
    missing_issue.started_after(started_after).stopped_before(stopped_before).group_by{|k| k.user.name}
  end

  def self.report_without_issue_for_user(user, started_after = nil, stopped_before = nil)
    for_user(user).missing_issue.started_after(started_after).stopped_before(stopped_before).group_by{|k| k.user.name}
  end

  def self.report_without_project(started_after = nil, stopped_before = nil)
    includes(:user, :toggl_workspace).missing_project.started_after(started_after).stopped_before(stopped_before).
      reject{|k| k.user.try(:toggl_workspace)}.
      group_by{|k| k.user.name}
  end

  def self.report_without_project_for_user(user, started_after = nil, stopped_before = nil)
    for_user(user).missing_project.started_after(started_after).stopped_before(stopped_before).group_by{|k| k.user.name}
  end

  def self.export_to_csv(args)
    start_date = args[:start_date]
    end_date = args[:end_date]
    data = eager_load(:toggl_project, :issue).includes(:toggl_task, :user).
      started_after(start_date).stopped_before(end_date).order_by_start

    raw_csv = CSV.generate :force_quotes => true do |csv|
      data.each do |toggl_entry|
        csv << [
          toggl_entry.description,
          toggl_entry.toggl_project_name,
          toggl_entry.formatted_issue,
          toggl_entry.formatted_duration,
          format_time(toggl_entry.start),
          toggl_entry.clean_toggl_tags.join(','),
          toggl_entry.user.try(:name)
        ]
      end
    end

    raw_csv
  end

  def clean_toggl_tags
    return [] if toggl_tags.blank?

    toggl_tags
  end

  def formatted_duration
    Time.at(duration || 0).utc.strftime('%H:%M:%S')
  end

  def formatted_issue
    return nil unless issue

    "#{issue.tracker} ##{issue.id}: #{issue.subject}"
  end

  def toggl_project_color
    toggl_project.try(:hex_color) || DEFAULT_COLOR
  end

  def toggl_workspace_name
    toggl_workspace.try(:name)
  end

  def toggl_project_name
    toggl_project.try(:name)
  end

  def toggl_task_name
    toggl_task.try(:name)
  end

  def toggl_params
    duration ||= (stop - start).ceil

    opts = {
      'description' => description,
      'start' => start.try(:iso8601),
      'duration' => duration
    }

    opts['wid'] = toggl_workspace.try(:toggl_id)
    opts['pid'] = toggl_project.try(:toggl_id)
    opts['tid'] = toggl_task.try(:toggl_id)
    opts['tags'] = clean_toggl_tags

    opts
  end

  def detect_issue
    if description.blank?
      self.issue_id = nil
      return
    end

    self.issue_id = description.scan(ISSUE_MATCHER).first.try(:last).try(:to_i)
  end

  def delete_time_entry
    return unless issue_id_changed?

    self.time_entry.destroy if self.time_entry
    self.time_entry_id = nil
  end

  def update_time_entry
    self.issue = Issue.find_by_id(issue_id)

    if self.issue &&
      (self.user.allowed_to?(:log_time, self.issue.project) ||
       self.user.toggl_can_log_time_to_all_issues)

      time_entry_attributes = {
        :project_id => self.issue.project.id,
        :issue_id => self.issue.id,
        :user => self.user,
        :hours => duration.to_f / 3600,
        :spent_on => start,
        :comments => description.gsub(ISSUE_MATCHER, ' ').strip
      }

      related_activity = RedmineToggl.activity_for_tags(clean_toggl_tags) || TimeEntryActivity.default.try(:id)
      time_entry_attributes[:activity_id] = related_activity if related_activity.present?

      self.time_entry ||= build_time_entry
      self.time_entry.assign_attributes(time_entry_attributes)
      self.time_entry.save! if self.time_entry.changed?
    else
      # we only create time_entries for issues, so if no issue, no time_entry
      self.time_entry.destroy if self.time_entry
      self.time_entry_id = nil
      self.issue_id = nil
    end
  end

  def save_if_changed
    detect_issue
    return unless changed?

    transaction do
      delete_time_entry
      update_time_entry
      save!
    end

    self
  end

  def sync_and_destroy
    transaction do
      toggl = TogglService.new(:user => user)
      toggl.delete_time_entry(toggl_id)
      time_entry.destroy if time_entry
      destroy
    end
  end
end

