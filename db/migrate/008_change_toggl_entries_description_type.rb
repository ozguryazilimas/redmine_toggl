class ChangeTogglEntriesDescriptionType < ActiveRecord::Migration

  def change
    change_column :toggl_entries, :description, :text
  end

end

