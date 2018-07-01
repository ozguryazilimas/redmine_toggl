class TogglWorkspace < ActiveRecord::Base
  unloadable

  has_many :toggl_entries
  has_many :toggl_projects, -> {order(:name)}
  has_many :toggl_tasks, -> {order(:name)}

  belongs_to :user

  scope :with_user, -> {where.not(:user_id => nil)}
  scope :without_user, -> {where(:user_id => nil)}

end

