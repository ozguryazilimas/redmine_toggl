class CreateTogglApiKeyCustomField < ActiveRecord::Migration[4.2]

  TOGGL_API_KEY = 'Toggl API Key'

  def up
    custom_field = CustomField.find_by_name(TOGGL_API_KEY)
    return if custom_field

    custom_field = CustomField.new_subclass_instance(
      'UserCustomField',
      {
        :name => TOGGL_API_KEY,
        :field_format => :string,
        :min_length => 32,
        :max_length => 32,
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
    custom_field = CustomField.find_by_name(TOGGL_API_KEY)
    custom_field.destroy if custom_field
  end

end

