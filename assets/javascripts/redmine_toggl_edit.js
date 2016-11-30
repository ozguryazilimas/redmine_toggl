
function filter_child_for_parent(parent_selector, child_selector, child_all_options) {
  var parent_selected = $(parent_selector + ' :selected').text();
  var parent_option_group = "optgroup[label='"+ parent_selected + "']";
  var child_filtered_options = $(child_all_options).filter(parent_option_group).html();

  $(child_selector).html(child_filtered_options).trigger('change');
}

function update_child_on_parent_change(parent_selector, child_selector) {
  var child_all_options = $(child_selector).html();

  $(parent_selector).on('change', function() {
    filter_child_for_parent(parent_selector, child_selector, child_all_options);
  });
}

$(function() {
  update_child_on_parent_change('#toggl_entry_toggl_workspace_id', '#toggl_entry_toggl_project_id');
  update_child_on_parent_change('#toggl_entry_toggl_project_id', '#toggl_entry_toggl_task_id');

  $('#toggl_entry_toggl_workspace_id').trigger('change');
});

