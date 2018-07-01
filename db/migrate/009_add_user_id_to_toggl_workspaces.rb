class AddUserIdToTogglWorkspaces < ActiveRecord::Migration

  def change
    add_column :toggl_workspaces, :user_id, :integer
  end

end


