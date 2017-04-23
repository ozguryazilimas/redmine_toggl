class AddTagsToTogglEntries < ActiveRecord::Migration

  def change
    add_column :toggl_entries, :toggl_tags, :text
  end

end

