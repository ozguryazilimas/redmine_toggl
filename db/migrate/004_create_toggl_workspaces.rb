class CreateTogglWorkspaces < ActiveRecord::Migration

  def change
    create_table :toggl_workspaces do |t|
      t.integer :toggl_id
      t.string :name
      t.string :logo_url
      t.string :ical_url

      t.timestamps null: false
    end

    add_index :toggl_workspaces, :toggl_id, :unique => true
  end

end

