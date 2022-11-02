
class ConvertTogglEntriesSerializedToJson < ActiveRecord::Migration[5.2]

  SELECT_ID_SQL = 'SELECT id FROM %s;'
  SELECT_DATA_SQL = 'SELECT %s FROM %s WHERE id IN (%s);'
  UPDATE_SQL = "UPDATE %s SET %s WHERE id = %s;"
  LIMIT = 1000


  def convert_serialized_to_json(table_name, column_names)
    all_ids = select_values(format(SELECT_ID_SQL, table_name))

    all_ids.each_slice(LIMIT) do |sliced_ids|
      select_sql = format(SELECT_DATA_SQL, (column_names + [:id]).join(','), table_name, sliced_ids.join(','))
      rows = select_rows(select_sql)

      rows.each do |column_data|
        column_offset = -1
        processed_columns = []
        id = column_data.pop

        column_data.each do |k|
          column_offset += 1
          next if k.to_s.strip.blank?

          val = quote(YAML.load(k).to_json)
          processed_columns << format('%s = %s', column_names[column_offset], val)
        end

        next if processed_columns.empty?

        update_sql = format(UPDATE_SQL, table_name, processed_columns.join(','), id)
        execute(update_sql)
      end
    end
  end


  def up
    convert_serialized_to_json(:toggl_entries, [:toggl_tags])
  end

  def down
  end

end

