class AddTagsToTogglEntries < ActiveRecord::Migration[4.2]

  def change
    add_column :toggl_entries, :toggl_tags, :text
  end

end

