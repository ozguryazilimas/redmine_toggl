
module TogglEntriesHelper

  def rt_issue_link(issue)
    return '' unless issue

    if issue.visible?(User.current)
      link_to_issue(issue)
    else
      "##{issue.id}"
    end
  end

  def rt_time_entry_link(time_entry)
    return '' unless time_entry

    if time_entry.editable_by?(User.current)
      link_to("##{time_entry.id}", edit_time_entry_path(time_entry))
    else
      "##{time_entry.id}"
    end
  end

  def rt_user_link(user)
    return '' if user.blank?
    return h(user.to_s) unless user.is_a?(User)

    name = h(user.name)
    return name unless user.active? || (User.current.admin? && user.logged?)

    link_to name, filter_by_user_toggl_entries_path(:filter_user_id => user.id), :class => user.css_classes
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

