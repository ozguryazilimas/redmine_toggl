require_dependency 'mailer'

module RedmineToggl
  module Patches
    module MailerPatch
      def self.included(base) # :nodoc:
        # base.extend(ClassMethods)
        base.send(:include, InstanceMethods)

        base.class_eval do
          helper :toggl_entries
        end
      end

      module InstanceMethods

        def toggl_report_without_issue(_user, recipients, report_results, language = nil, started_after = nil, stopped_before = nil)
          Rails.logger.info "Sending Toggl entry without issue report to #{recipients.inspect}"
          @report_data = report_results
          I18n.locale = language if language
          redmine_headers 'Report' => 'toggl_entries_without_issue'

          subject = toggl_add_time_to_subject(t('toggl.toggl_report_without_issue_subject'), started_after, stopped_before)
          mail :to => recipients, :subject => subject
        end

        def toggl_report_without_project(_user, recipients, report_results, language = nil, started_after = nil, stopped_before = nil)
          Rails.logger.info "Sending Toggl entry without project report to #{recipients.inspect}"
          @report_data = report_results
          I18n.locale = language if language
          redmine_headers 'Report' => 'toggl_entries_without_project'

          subject = toggl_add_time_to_subject(t('toggl.toggl_report_without_project_subject'), started_after, stopped_before)
          mail :to => recipients, :subject => subject
        end


        def toggl_add_time_to_subject(subject_base, started_after = nil, stopped_before = nil)
          return subject_base if started_after.blank? && stopped_before.blank?

          start_str = started_after.strftime('%Y-%m-%d %H:%M') if started_after.present?
          stop_str = (stopped_before || Time.now).strftime('%Y-%m-%d %H:%M')

          "#{subject_base} (#{start_str} - #{stop_str})"
        end
      end
    end
  end
end

