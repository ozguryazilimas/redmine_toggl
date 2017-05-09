
class TogglEntriesDatatable < ServerSideDatatables
  delegate :toggl_entry_path, :time_tag, :rt_issue_link, :rt_time_entry_link, :rt_user_link, :rt_format_duration, :rt_project_display, :format_time, :to => :@view

  private

  def filtered_list
    @user = view_variable('@user')

    # TODO: make this smarter if we support more filtering
    if @for_user
      @klass.eager_load(:toggl_project, :issue).includes(:toggl_task, :user).for_user(@for_user)
    else
      @klass.eager_load(:toggl_project, :issue).includes(:toggl_task, :user)
    end
  end

  def data
    items.map do |toggl_entry|
      cols = [
        link_to(toggl_entry.description, toggl_entry_path(toggl_entry)),
        rt_project_display(toggl_entry),
        rt_issue_link(toggl_entry.issue),
        rt_format_duration(toggl_entry.duration),
        format_time(toggl_entry.start),
        toggl_entry.toggl_tags.join(',')
      ]

      cols << rt_user_link(toggl_entry.user) unless @for_user
      cols
    end
  end

  def columns
    cols = [
      'toggl_entries.description',
      'toggl_projects.name',
      'issues.subject',
      'duration',
      'start',
      'toggl_entries.toggl_tags'
    ]

    cols << 'users.firstname' unless @for_user
    cols
  end

end

