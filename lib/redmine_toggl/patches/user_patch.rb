require_dependency 'user'

module RedmineToggl
  module Patches
    module UserPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          scope :with_toggl_api_key, -> {
            toggl_api_key_field_id = TogglService.custom_field_api_key.id

            joins(:custom_values).
            where(:custom_values => {:custom_field_id => toggl_api_key_field_id}).
            where.not(:custom_values => {:value => [nil, '']})
          }
        end
      end

      module InstanceMethods

        def toggl_api_key
          custom_field_value(TogglService.custom_field_api_key)
        end

        def toggl_workspace
          custom_field_value(TogglService.custom_field_workspace)
        end

        def toggl_can_view_main_menu
          allowed_to_globally?(:view_toggl_entries)
        end

        def toggl_can_view_others_entries
          allowed_to_globally?(:view_toggl_entries) && allowed_to_globally?(:view_time_entries)
        end

        def toggl_can_create_toggl_entry
          toggl_api_key.present?
        end

        def toggl_can_log_time_to_all_issues
          allowed_to_globally?(:toggl_log_time_to_all_issues)
        end

      end

    end
  end
end

