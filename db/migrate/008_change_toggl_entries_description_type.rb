class ChangeTogglEntriesDescriptionType < ActiveRecord::Migration[4.2]

  def change
    change_column :toggl_entries, :description, :text
  end

end

