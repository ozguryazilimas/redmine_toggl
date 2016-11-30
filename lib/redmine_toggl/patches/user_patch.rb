require_dependency 'user'

module RedmineToggl
  module Patches
    module UserPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
        end
      end

      module InstanceMethods

        def toggl_api_key
          custom_field_value(TogglService.custom_field_api_key)
        end

        def toggl_workspace
          custom_field_value(TogglService.custom_field_workspace)
        end

      end

    end
  end
end

