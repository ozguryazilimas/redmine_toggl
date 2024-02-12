require 'redmine'
require_dependency File.join(File.dirname(__FILE__), 'lib/redmine_toggl')

Redmine::Plugin.register :redmine_toggl do
  name 'Redmine Toggl Plugin'
  author 'Onur Kucuk'
  description 'Sync and Manage Toggl Entries with Redmine'
  version '2.9.5'
  url 'http://www.ozguryazilim.com.tr'
  author_url 'http://www.ozguryazilim.com.tr'
  requires_redmine :version_or_higher => '4.0.0'

  permission :view_toggl_entries, {
    :toggl_entries => [
      :index,
      :all_entries,
      :filter_by_user,
      :show,
      :new,
      :create,
      :edit,
      :update,
      :destroy
    ]
  },
  :require => :loggedin

  permission :edit_all_toggl_entries, {
    :toggl_entries => [
      :update,
      :destroy
    ]
  },
  :require => :loggedin

  permission :toggl_log_time_to_all_issues, {
    :toggl_entries => [
      :update,
      :destroy
    ]
  },
  :require => :loggedin

  menu :top_menu, :toggl_entries, {
    :controller => 'toggl_entries',
    :action => 'index'
  },
  :caption => :toggl_entries_title,
  :if => Proc.new{User.current.toggl_can_view_main_menu}

  settings :partial => 'redmine_toggl/settings',
    :default => {
      'activity' => {}
    }
end

# Rails.configuration.to_prepare do
RedmineApp::Application.config.after_initialize do
  [
    [User, RedmineToggl::Patches::UserPatch],
    [Mailer, RedmineToggl::Patches::MailerPatch],
    [TogglV8::Connection, RedmineToggl::Patches::Togglv8ConnectionPatch]
  ].each do |classname, modulename|
    unless classname.included_modules.include?(modulename)
      classname.send(:include, modulename)
    end
  end
end

