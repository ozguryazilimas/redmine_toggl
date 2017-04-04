# super class for server side datatables
# frozen_string_literal: true

class ServerSideDatatables
  delegate :params, :h, :t, :raw, :link_to, :number_to_currency, :format_time, :to => :@view

  ASC = 'asc'
  DESC = 'desc'

  PINGBACK = :draw
  AND_STR = ' AND '
  OR_STR = ' OR '

  DEFAULT_LENGTH = 50
  SEARCH_DELIMITER = ' '
  LIKE_OPERATOR = (ActiveRecord::Base.connection.adapter_name =~ /PostgreSQL/i).nil? ? 'LIKE' : 'ILIKE'

  def initialize(klass, view, for_user = nil)
    @klass = klass
    @view = view
    @for_user = for_user if for_user.present?
  end

  def as_json(_options = {})
    {
      PINGBACK => params[PINGBACK].to_i,
      :recordsTotal => @klass.count,
      :recordsFiltered => items.total_entries,
      :data => data
    }
  end

  def view_variable(varname)
    @view.instance_variable_get(varname)
  end

  private

  # singleton
  def data
    []
  end

  # singleton
  def columns
    []
  end

  def items
    @items ||= fetch_items
  end

  def fetch_items
    items = filtered_list
    items = selected_columns(items)
    items = items.order(sort_order)
    items = items.page(page).per_page(per_page)
    items = items.where(quick_search) if search_value.present?

    items
  end

  # singleton
  def filtered_list
    @klass.all
  end

  def selected_columns(items)
    items
  end

  def quick_search
    search_for = search_value.split(SEARCH_DELIMITER)
    terms = {}
    current_ix = -1

    criteria_search_for = search_for.inject([]) do |criteria, atom|
      current_ix += 1
      terms["search#{current_ix}".to_sym] = "%#{atom}%"
      criteria << "(#{search_columns.map{|col| "#{col} #{LIKE_OPERATOR} :search#{current_ix}"}.join(OR_STR)})"
    end.join(AND_STR)

    [criteria_search_for, terms]
  end

  def page
    params[:start].to_i / per_page + 1
  end

  def per_page
    params[:length].to_i.positive? ? params[:length].to_i : DEFAULT_LENGTH
  end

  # TODO: enable multicolumn order and use columns other than 0
  def sort_order
    order_data = params[:order]['0']
    column_name = columns[order_data['column'].to_i]
    direction = order_data['dir'] == DESC ? DESC : ASC

    "#{column_name} #{direction}"
  end

  def search_columns
    cols = []

    params['columns'].each do |k, v|
      cols << columns[k.to_i] if v['searchable'] == 'true'
    end

    cols
  end

  def search_value
    params[:search][:value] rescue ''
  end

  def link_if_exists(data)
    return '' if data.blank?
    link_to data
  end
end

