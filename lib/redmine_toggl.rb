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

    activity_settings.each do |activity_id, activity_matcher|
      next if activity_matcher.blank?

      # we can have a string set as A,B|C,D which will match entries
      # that has tag A tag D or "both od B and C"
      setting_to_match = activity_matcher.split(TogglEntry::TOGGL_TAG_SEPARATOR).map do |k|
        k.split(TogglEntry::TOGGL_MULTI_TAG_SEPARATOR)
      end

      setting_to_match.each do |tag_setting|
        next if tag_setting.blank?

        # we want to make sure all configured tags exist in the entry data at the same time
        return activity_id if (tag_setting - tags).blank?
      end
    end

    return nil
  end

end

