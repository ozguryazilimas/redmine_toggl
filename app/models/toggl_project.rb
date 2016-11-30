class TogglProject < ActiveRecord::Base
  unloadable

  has_many :toggl_entries
  has_many :toggl_tasks, -> {order(:name)}

  belongs_to :toggl_workspace

end

