class TogglTask < ActiveRecord::Base

  has_many :toggl_entries

  belongs_to :toggl_workspace
  belongs_to :toggl_project

end

