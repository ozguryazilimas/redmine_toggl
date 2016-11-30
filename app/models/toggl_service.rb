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
    @toggl_time_entries = []
    @toggl_workspaces = []
    @toggl_projects = []
    @toggl_tasks = []

    @user = cfg[:user]
    @apikey = cfg[:apikey]
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
    @toggl_time_entries = @toggl.get_time_entries
    # @toggl_time_entries = JSON.parse(IO.read('/tmp/sil/toggl/sample_time_entry.json'))
  end

  def get_toggl_workspaces
    @toggl_workspaces = @toggl.workspaces
  end

  def get_toggl_projects
    @toggl_projects = []

    TogglWorkspace.pluck(:toggl_id).each do |ws_id|
      @toggl_projects += @toggl.projects(ws_id)
    end
  end

  def get_toggl_tasks
    @toggl_tasks = []

    TogglWorkspace.pluck(:toggl_id).each do |ws_id|
      @toggl_tasks += @toggl.tasks(ws_id)
    end
  end

  def format_time_entry(entry)
    entry.delete('duronly')
    entry['toggl_id'] = entry.delete('id')
    entry['user_id'] = @user.id

    entry
  end

  def populate_toggl_base
    @workspaces = Hash[TogglWorkspace.pluck(:toggl_id, :id)]
    @projects = Hash[TogglProject.pluck(:toggl_id, :id)]
    @tasks = Hash[TogglTask.pluck(:toggl_id, :id)]
  end

  def save_toggl_entry_from_toggl_data(raw_entry)
    entry = format_time_entry(raw_entry)

    toggl_entry = TogglEntry.find_or_initialize_by(:toggl_id => entry['toggl_id'])
    toggl_entry.assign_attributes(entry)
    toggl_entry.user_id = @user.id

    toggl_entry.toggl_workspace_id = @workspaces[entry['wid']]
    toggl_entry.toggl_project_id = @projects[entry['pid']]
    toggl_entry.toggl_task_id = @tasks[entry['tid']]

    toggl_entry.save_if_changed
  end

  def save_toggl_time_entries
    populate_toggl_base

    @toggl_time_entries.each do |entry|
      # skip if user requested workspace and time entry workspace does not match
      next if @filter_workspace_id && entry['wid'] != @filter_workspace_id
      save_toggl_entry_from_toggl_data(entry)
    end
  end

  def sync_time_entries
    get_toggl_time_entries
    save_toggl_time_entries
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
      entry = @toggl.create_time_entry(time_entry_opts)
      save_toggl_entry_from_toggl_data(entry)
    end
  end

  def update_time_entry(opts)
    toggl_id = opts[:toggl_id]
    time_entry_opts = parse_api_opts(opts)
    populate_toggl_base

    ActiveRecord::Base.transaction do
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

  def self.sync_toggl_time_entries
    workspaces = Hash[TogglWorkspace.all.map{|k| [k.name, k.toggl_id]}]

    User.active.each do |user|
      next if user.locked?

      apikey = user.toggl_api_key
      next if apikey.blank?

      workspace_name = user.toggl_workspace
      workspace_id = workspaces[workspace_name]

      TogglService.new(
        :user => user,
        :apikey => apikey,
        :toggl_workspace_id => workspace_id
      ).sync_time_entries
    end
  end

  def self.sync_workspaces(apikey)
    toggl_service = TogglService.new(:apikey => apikey)
    toggl_service.get_toggl_workspaces

    toggl_service.toggl_workspaces.each do |ws|
      t_workspace = TogglWorkspace.find_or_initialize_by(:toggl_id => ws['id'])

      t_workspace.assign_attributes(
        :name => ws['name'],
        :logo_url => ws['logo_url'],
        :ical_url => ws['ical_url']
      )

      t_workspace.save! if t_workspace.changed?
    end
  end

  def self.sync_projects(apikey)
    workspaces = Hash[TogglWorkspace.pluck(:toggl_id, :id)]

    toggl_service = TogglService.new(:apikey => apikey)
    toggl_service.get_toggl_projects

    toggl_service.toggl_projects.each do |pr|
      t_project = TogglProject.find_or_initialize_by(:toggl_id => pr['id'])

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
  end

  def self.sync_tasks(apikey)
    workspaces = Hash[TogglWorkspace.pluck(:toggl_id, :id)]
    projects = Hash[TogglProject.pluck(:toggl_id, :id)]

    toggl_service = TogglService.new(:apikey => apikey)
    toggl_service.get_toggl_tasks

    toggl_service.toggl_tasks.each do |tt|
      t_task = TogglTask.find_or_initialize_by(:toggl_id => tt['id'])

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
  end

  def self.sync_base_data(apikey)
    ActiveRecord::Base.transaction do
      TogglService.sync_workspaces(apikey)
      TogglService.sync_projects(apikey)
      TogglService.sync_tasks(apikey)
    end
  end
end

