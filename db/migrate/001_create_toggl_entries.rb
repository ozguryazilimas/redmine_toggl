class CreateTogglEntries < ActiveRecord::Migration

  def change
    create_table :toggl_entries do |t|
      t.integer :toggl_id, :null => false
      t.string :description
      t.string :guid
      t.integer :wid
      t.integer :pid
      t.integer :tid
      t.datetime :start
      t.datetime :stop
      t.integer :duration
      t.boolean :billable
      t.datetime :at
      t.integer :uid
      t.integer :user_id, :null => false
      t.integer :issue_id
      t.integer :time_entry_id
      t.integer :toggl_workspace_id
      t.integer :toggl_project_id
      t.integer :toggl_task_id

      t.timestamps null: false
    end

    add_index :toggl_entries, :toggl_id, :unique => true
    add_index :toggl_entries, :user_id
  end

end

