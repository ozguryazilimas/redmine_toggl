require 'togglv8'
require 'json'

class TogglService
  unloadable

  TOGGL_API_KEY = 'Toggl API Key'
  TOGGL_WORKSPACE = 'Toggl Workspace'

  attr_accessor :toggl, :apikey, :user, :toggl_time_entries, :toggl_workspaces, :toggl_projects, :toggl_tasks,
                :custom_field_api_key, :custom_field_workspace

  def initialize(cfg = {})
    @config = cfg
    @debug = cfg[:debug] || false
    @remove_missing = cfg[:remove_missing] || false
    @toggl_time_entries = []
    @toggl_workspaces = []
    @toggl_projects = []
    @toggl_tasks = []

    @user = cfg[:user]
    @apikey = cfg[:apikey]
    @apiparams = cfg[:apiparams]
    @filter_workspace_id = cfg[:toggl_workspace_id]

    setup_initial_values
  end

  def setup_initial_values
    if @user && @apikey.blank?
      @apikey = @user.custom_field_value(TogglService.custom_field_api_key)
    end

    @toggl = TogglV8::API.new(@apikey) if @apikey.present?
  end

  def get_toggl_time_entries
    args = @apiparams || {}
    @toggl_time_entries = @toggl.get_time_entries(args)
  end

  def get_toggl_workspaces
    @toggl_workspaces = @toggl.workspaces
  end

  def get_toggl_projects
    @toggl_projects = []

    TogglWorkspace.pluck(:toggl_id).each do |ws_id|
      ws_projects = @toggl.projects(ws_id) rescue []
      @toggl_projects += ws_projects if ws_projects.present?
    end
  end

  def get_toggl_tasks
    @toggl_tasks = []

    TogglWorkspace.pluck(:toggl_id).each do |ws_id|
      ws_tasks = @toggl.tasks(ws_id) rescue []
      @toggl_tasks += ws_tasks if ws_tasks.present?
    end
  end

  def format_time_entry(entry)
    entry.delete('duronly')
    entry['toggl_id'] = entry.delete('id')
    entry['user_id'] = @user.id
    entry['toggl_tags'] = entry.delete('tags') || []

    entry
  end

  def populate_toggl_base
    @workspaces = Hash[TogglWorkspace.pluck(:toggl_id, :id)]
    @projects = Hash[TogglProject.pluck(:toggl_id, :id)]
    @tasks = Hash[TogglTask.pluck(:toggl_id, :id)]
  end

  def save_toggl_entry_from_toggl_data(raw_entry)
    entry = format_time_entry(raw_entry)
    return if entry['duration'].to_i < 1

    toggl_entry = TogglEntry.where(:toggl_id => entry['toggl_id']).first_or_initialize
    toggl_entry.assign_attributes(entry)
    toggl_entry.user_id = @user.id

    toggl_entry.toggl_workspace_id = @workspaces[entry['wid']]
    toggl_entry.toggl_project_id = @projects[entry['pid']]
    toggl_entry.toggl_task_id = @tasks[entry['tid']]

    toggl_entry.save_if_changed
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  def save_toggl_time_entries
    populate_toggl_base

    @toggl_time_entries.each do |entry|
      # skip if user requested workspace and time entry workspace does not match
      next if @filter_workspace_id.present? && entry['wid'] != @filter_workspace_id

      # ignore time entries that are not finished yet
      next if entry['stop'].to_s.empty?

      save_toggl_entry_from_toggl_data(entry)
    end
  end

  def remove_missing_toggl_time_entries
    # we will check integrity of data between first and last entries, if we have less
    # than 3 total data, then there is nothing in between that we care about
    return if @toggl_time_entries.count < 3

    start_time = @toggl_time_entries.first['start']
    end_time = @toggl_time_entries.last['start']
    remote_ids = @toggl_time_entries.map{|k| k['toggl_id']}

    # find entries that might be deleted from Toggl, but not from Redmine
    might_be_deleted = TogglEntry.where('start >= ?', Time.parse(start_time))
                                 .where('start <= ?', Time.parse(end_time))
                                 .where.not(:toggl_id => remote_ids)

    might_be_deleted.each do |entry|
      should_delete = false

      begin
        entry_data = @toggl.get_time_entry(entry.toggl_id)

        # if you fetch with get_time_entries, Toggl does not return deleted ones
        # but if get just one by hand you can detect if it was deleted
        should_delete = entry_data['server_deleted_at'].present?
      rescue => e
        Rails.logger.warn "Trying to detect if Toggl entry with toggl_id #{entry.toggl_id} was deleted " \
          "but instead received #{e.message}"
      end

      next unless should_delete

      TogglEntry.transaction do
        entry.time_entry.try(:destroy)
        entry.destroy
      end
    end
  end

  def sync_time_entries
    get_toggl_time_entries
    save_toggl_time_entries
    remove_missing_toggl_time_entries if @remove_missing
  end

  def delete_time_entry(entry_id)
    @toggl.delete_time_entry(entry_id)
  end

  def parse_api_opts(opts)
    Time.use_zone(@user.time_zone || 'UTC') do
      TogglEntry.new(opts).toggl_params
    end
  end

  def create_time_entry(opts)
    time_entry_opts = parse_api_opts(opts)
    populate_toggl_base

    ActiveRecord::Base.transaction do
      fail I18n.t('toggl.invalid_duration') if time_entry_opts['duration'].to_i < 1
      entry = @toggl.create_time_entry(time_entry_opts)
      save_toggl_entry_from_toggl_data(entry)
    end
  end

  def update_time_entry(opts)
    toggl_id = opts.with_indifferent_access[:toggl_id].to_i
    time_entry_opts = parse_api_opts(opts)
    populate_toggl_base

    ActiveRecord::Base.transaction do
      fail I18n.t('toggl.invalid_duration') if time_entry_opts['duration'].to_i < 1
      entry = @toggl.update_time_entry(toggl_id, time_entry_opts)
      save_toggl_entry_from_toggl_data(entry)
    end
  end

  def self.custom_field_api_key
    @custom_field_api_key ||= UserCustomField.find_by_name(TOGGL_API_KEY)
  end

  def self.custom_field_workspace
    @custom_field_workspace ||= UserCustomField.find_by_name(TOGGL_WORKSPACE)
  end

  def self.sync_toggl_time_entries(sync_args = {}, check_missing = false)
    workspaces = TogglWorkspace.without_user.pluck(:name, :toggl_id).to_h

    User.active.each do |user|
      next if user.locked?

      apikey = user.cf_toggl_api_key
      next if apikey.blank?

      if user.toggl_workspace
        workspace_id = user.toggl_workspace.toggl_id
      else
        workspace_name = user.cf_toggl_workspace
        workspace_id = workspaces[workspace_name] if workspace_name.present?
      end

      ts_params = {
        :user => user,
        :apikey => apikey,
        :toggl_workspace_id => workspace_id,
        :remove_missing => check_missing
      }

      ts_params[:apiparams] = sync_args if sync_args.present?
      TogglService.new(ts_params).sync_time_entries
    end
  end

  def self.sync_workspaces(apikey, workspace_to_sync = nil, user_to_sync = nil)
    toggl_service = TogglService.new(:apikey => apikey)
    toggl_service.get_toggl_workspaces

    toggl_service.toggl_workspaces.each do |ws|
      next if workspace_to_sync.present? && ws['name'] != workspace_to_sync

      t_workspace = TogglWorkspace.where(:toggl_id => ws['id']).first_or_initialize

      t_workspace.assign_attributes(
        :name => ws['name'],
        :logo_url => ws['logo_url'],
        :ical_url => ws['ical_url']
      )

      t_workspace.user = user_to_sync if user_to_sync
      t_workspace.save! if t_workspace.changed?
    end

    return if user_to_sync
    TogglWorkspace.where.not(:toggl_id => toggl_service.toggl_workspaces.map{|k| k['id']}).
                   where(:user_id => nil).destroy_all
  end

  def self.sync_projects(apikey)
    workspaces = Hash[TogglWorkspace.pluck(:toggl_id, :id)]

    toggl_service = TogglService.new(:apikey => apikey)
    toggl_service.get_toggl_projects

    toggl_service.toggl_projects.each do |pr|
      t_project = TogglProject.where(:toggl_id => pr['id']).first_or_initialize

      t_project.assign_attributes(
        :name => pr['name'],
        :wid => pr['wid'],
        :hex_color => pr['hex_color'],
        :billable => pr['billable'],
        :active => pr['active'],
        :toggl_workspace_id => workspaces[pr['wid'].to_i]
      )

      t_project.save! if t_project.changed?
    end

    TogglProject.where.not(:toggl_id => toggl_service.toggl_projects.map{|k| k['id']}).
                 where(:toggl_workspace => TogglWorkspace.without_user).destroy_all
  end

  def self.sync_tasks(apikey)
    workspaces = Hash[TogglWorkspace.pluck(:toggl_id, :id)]
    projects = Hash[TogglProject.pluck(:toggl_id, :id)]

    toggl_service = TogglService.new(:apikey => apikey)
    toggl_service.get_toggl_tasks

    toggl_service.toggl_tasks.each do |tt|
      t_task = TogglTask.where(:toggl_id => tt['id']).first_or_initialize

      t_task.assign_attributes(
        :name => tt['name'],
        :wid => tt['wid'],
        :pid => tt['pid'],
        :active => tt['active'],
        :toggl_workspace_id => workspaces[tt['wid'].to_i],
        :toggl_project_id => projects[tt['pid'].to_i]
      )

      t_task.save! if t_task.changed?
    end

    TogglTask.where.not(:toggl_id => toggl_service.toggl_tasks.map{|k| k['id']}).
              where(:toggl_workspace => TogglWorkspace.without_user).destroy_all
  end

  def self.sync_base_data(apikey, workspace_to_sync = nil, user_to_sync = nil)
    ActiveRecord::Base.transaction do
      TogglService.sync_workspaces(apikey, workspace_to_sync, user_to_sync)

      unless user_to_sync
        TogglService.sync_projects(apikey)
        TogglService.sync_tasks(apikey)
      end
    end
  end
end

