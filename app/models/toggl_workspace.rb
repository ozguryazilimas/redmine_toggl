class TogglWorkspace < ActiveRecord::Base
  unloadable

  has_many :toggl_entries
  has_many :toggl_projects, -> {order(:name)}
  has_many :toggl_tasks, -> {order(:name)}

end

