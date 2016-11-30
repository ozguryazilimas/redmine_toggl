class TogglEntry < ActiveRecord::Base
  unloadable

  ISSUE_MATCHER = /\s*#(\d+)\s*/
  DEFAULT_COLOR = '#000000'

  belongs_to :user
  belongs_to :issue
  belongs_to :time_entry

  belongs_to :toggl_workspace
  belongs_to :toggl_project
  belongs_to :toggl_task

  scope :without_issue, -> {where(:issue_id => nil)}
  scope :for_user, -> (user) {where(:user_id => user)}
  scope :for_issue, -> (issue) {where(:issue_id => issue)}

  validates_presence_of :user_id, :toggl_id


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
      'start' => start,
      'duration' => duration
    }

    opts['wid'] = toggl_workspace.try(:toggl_id)
    opts['pid'] = toggl_project.try(:toggl_id)
    opts['tid'] = toggl_task.try(:toggl_id)

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

    time_entry.destroy if time_entry
    self.time_entry_id = nil
  end

  def update_time_entry
    issue = Issue.find_by_id(issue_id)

    if issue
      time_entry_attributes = {
        :project_id => issue.project.id,
        :issue_id => issue.id,
        :user => user,
        :hours => duration.to_f / 3600,
        :spent_on => start,
        :comments => description
      }

      time_entry ||= build_time_entry
      time_entry.assign_attributes(time_entry_attributes)
      time_entry.save! if time_entry.changed?
    else
      # we only create time_entries for issues, so if no issue, no time_entry
      time_entry.destroy if time_entry
      self.time_entry_id = nil
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

