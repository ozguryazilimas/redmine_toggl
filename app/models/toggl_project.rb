class TogglProject < ActiveRecord::Base

  has_many :toggl_entries
  has_many :toggl_tasks, -> {order(:name)}

  belongs_to :toggl_workspace

  scope :without_user, -> {where(:toggl_workspace => TogglWorkspace.without_user)}

end

