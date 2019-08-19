class CreateTogglWorkspaceCustomField < ActiveRecord::Migration[4.2]

  TOGGL_WORKSPACE = 'Toggl Workspace'

  def up
    custom_field = CustomField.find_by_name(TOGGL_WORKSPACE)
    return if custom_field

    custom_field = CustomField.new_subclass_instance(
      'UserCustomField',
      {
        :name => TOGGL_WORKSPACE,
        :field_format => :string,
        :min_length => 0,
        :max_length => 255,
        :default_value => '',
        :visible => false,
        :editable => true,
        :is_required => false,
        :regexp => '',
        :is_filter => false
      }
    )

    custom_field.save!
  end

  def down
    custom_field = CustomField.find_by_name(TOGGL_WORKSPACE)
    custom_field.destroy if custom_field
  end

end

