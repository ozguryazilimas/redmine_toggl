
module TogglEntriesHelper

  def rt_issue_link(issue)
    return '' unless issue
    link_to_issue(issue)
  end

  def rt_time_entry_link(time_entry)
    return '' unless time_entry
    link_to("##{time_entry.id}", edit_time_entry_path(time_entry))
  end

  def rt_user_link(user)
    link_to_user(user) if user
  end

  def rt_format_duration(total_seconds)
    Time.at(total_seconds || 0).utc.strftime('%H:%M:%S')
  end

  def rt_project_display(toggl_entry)
    return '' unless toggl_entry.toggl_project

    color = toggl_entry.toggl_project_color
    style = color.present? ? "style='color:#{color};'" : ''

    "<span title='#{toggl_entry.toggl_task_name}' #{style}>#{toggl_entry.toggl_project_name}</span>"
  end

end

