require 'redmine_toggl'

Redmine::Plugin.register :redmine_toggl do
  name 'Redmine Toggl Plugin'
  author 'Onur Kucuk'
  description 'Sync and Manage Toggl Entries with Redmine'
  version '0.5.0'
  url 'http://www.ozguryazilim.com.tr'
  author_url 'http://www.ozguryazilim.com.tr'
  requires_redmine :version_or_higher => '3.0.3'

  permission :view_toggl_entries, {
    :toggl_entries => [
      :index,
      :all_entries,
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

  menu :top_menu, :toggl_entries, {
    :controller => 'toggl_entries',
    :action => 'index'
  },
  :caption => :toggl_entries_title,
  :if => Proc.new{User.current.toggl_can_view_main_menu}

end

Rails.configuration.to_prepare do
  [
    [User, RedmineToggl::Patches::UserPatch]
  ].each do |classname, modulename|
    unless classname.included_modules.include?(modulename)
      classname.send(:include, modulename)
    end
  end

end

