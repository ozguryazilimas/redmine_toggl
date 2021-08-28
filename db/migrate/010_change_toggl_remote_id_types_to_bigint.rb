class ChangeTogglRemoteIdTypesToBigint < ActiveRecord::Migration[5.1]

  def change
    change_column :toggl_entries, :toggl_id, :bigint
    change_column :toggl_entries, :wid, :bigint
    change_column :toggl_entries, :pid, :bigint
    change_column :toggl_entries, :tid, :bigint
    change_column :toggl_entries, :uid, :bigint
  end

end

