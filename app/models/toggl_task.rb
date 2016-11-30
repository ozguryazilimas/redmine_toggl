class TogglTask < ActiveRecord::Base
  unloadable

  has_many :toggl_entries

  belongs_to :toggl_workspace
  belongs_to :toggl_project

end

