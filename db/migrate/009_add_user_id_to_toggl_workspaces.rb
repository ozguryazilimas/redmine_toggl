class AddUserIdToTogglWorkspaces < ActiveRecord::Migration[4.2]

  def change
    add_column :toggl_workspaces, :user_id, :integer
  end

end


