class CreateTogglTasks < ActiveRecord::Migration[4.2]

  def change
    create_table :toggl_tasks do |t|
      t.integer :toggl_id
      t.string :name
      t.integer :wid
      t.integer :pid
      t.boolean :active
      t.integer :toggl_workspace_id
      t.integer :toggl_project_id

      t.timestamps null: false
    end

    add_index :toggl_tasks, :toggl_id, :unique => true
  end

end

