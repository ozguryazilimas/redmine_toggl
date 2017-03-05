require_dependency 'mailer'

module RedmineToggl
  module Patches
    module MailerPatch
      def self.included(base) # :nodoc:
        # base.extend(ClassMethods)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable  # to make sure plugin is loaded in development mode
          helper :toggl_entries
        end
      end

      module InstanceMethods

        def toggl_report_without_issue(recipients, report_results, language = nil)
          @report_data = report_results
          I18n.locale = language if language

          mail :to => recipients, :subject => t('toggl.toggl_report_without_issue_subject')
        end

      end
    end
  end
end

