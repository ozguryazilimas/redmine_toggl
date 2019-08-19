class CreateTogglProjects < ActiveRecord::Migration[4.2]

  def change
    create_table :toggl_projects do |t|
      t.integer :toggl_id
      t.string :name
      t.integer :wid
      t.integer :toggl_workspace_id
      t.string :hex_color
      t.boolean :active
      t.boolean :billable

      t.timestamps null: false
    end

    add_index :toggl_projects, :toggl_id, :unique => true
  end

end

