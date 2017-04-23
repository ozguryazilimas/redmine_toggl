require 'server_side_datatables'
require 'toggl_entries_datatable'

module RedmineToggl

  SETTING_ACTIVITY = 'activity'

  def self.settings
    Setting[:plugin_redmine_toggl]
  end

  def self.activity_for_tags(tags)
    return nil if tags.blank?

    activity_settings = RedmineToggl.settings[RedmineToggl::SETTING_ACTIVITY]
    return nil if activity_settings.blank?

    activity_settings.each do |activity_id, vals_raw|
      vals = vals_raw.split(TogglEntry::TOGGL_TAG_SEPARATOR)
      return activity_id if (tags & vals).any?
    end

    return nil
  end

end

