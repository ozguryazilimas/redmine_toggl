# super class for server side datatables
# frozen_string_literal: true

class ServerSideDatatables

  delegate :params, :h, :t, :raw, :link_to, :number_to_currency, :format_time, :to => :@view

  AND_STR = ' AND '
  OR_STR = ' OR '
  DEFAULT_LENGTH = 25
  SEARCH_DELIMITER = ' '
  FORMAT_REGEX_COLUMN = "COALESCE(%s::text, '') ~ ?"

  ASC = 'asc'
  DESC = 'desc'
  PINGBACK = :draw
  RECORDS_TOTAL = :recordsTotal
  RECORDS_FILTERED = :recordsFiltered
  DATA = :data
  FULL_LENGTH = -1
  FULL_PAGE = 1
  FULL_PER_PAGE = 10_000_000
  START = :start
  LENGTH = :length
  ORDER = :order
  REGEX = :regex
  SEARCH = :search
  VALUE = :value
  COLUMN = 'column'
  COLUMNS = 'columns'
  SEARCHABLE = 'searchable'
  TRUE = 'true'
  DIR = 'dir'
  NEWLINE = "\n".freeze
  LIKE_OPERATOR = (ActiveRecord::Base.connection.adapter_name =~ /PostgreSQL/i).nil? ? 'LIKE' : 'ILIKE'


  def initialize(klass, view, for_user = nil)
    @klass = klass
    @view = view
    @for_user = for_user if for_user.present?
  end

  def as_json(_options = {})
    {
      PINGBACK => pingback,
      RECORDS_TOTAL => @klass.count,
      RECORDS_FILTERED => items.unscope(:select).total_entries,
      DATA => data
    }
  end

  def view_variable(varname)
    @view.instance_variable_get(varname)
  end


  private


  def data
    []
  end

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
    items = apply_column_filters(items)

    items
  end

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
      column_or_clause = search_columns.map{|col| "#{col} #{LIKE_OPERATOR} :search#{current_ix}"}.join(OR_STR)
      criteria << "(#{column_or_clause})"
    end.join(AND_STR)

    [criteria_search_for, terms]
  end

  def pingback
    params[PINGBACK].to_i
  end

  def page
    return FULL_PAGE if fulldata?
    params[START].to_i / per_page + 1
  end

  def per_page
    # default is 30 if you do not give per_page to will_paginage so we have to give something
    # https://github.com/mislav/will_paginate/wiki/API-documentation
    return FULL_PER_PAGE if fulldata?
    params[LENGTH].to_i.positive? ? params[LENGTH].to_i : DEFAULT_LENGTH
  end

  def sort_order
    return '' if params[ORDER].blank?

    order_ixs = params[ORDER].keys.sort_by(&:to_i)
    order_strs = []

    order_ixs.each do |ix|
      order_data = params[ORDER][ix]
      column_name = columns[order_data[COLUMN].to_i]
      direction = order_data[DIR] == DESC ? DESC : ASC

      order_strs << "#{column_name} #{direction}"
    end

    # mark raw SQL fragments explicitly for Rails 6
    Arel.sql(order_strs.join(','))
  end

  def search_columns
    cols = []

    params[COLUMNS].each do |k, v|
      cols << columns[k.to_i] if v[SEARCHABLE] == TRUE
    end

    cols
  end

  def column_filters
    cols = {}
    return cols if params[COLUMNS].blank?

    params[COLUMNS].each do |k, v|
      next if v[SEARCH].blank?

      val = v[SEARCH][VALUE]
      next if val.blank?

      # note that data is ActionController::Parameters
      cols[columns[k.to_i]] = v[SEARCH]
    end

    cols
  end

  def apply_column_filters(items)
    column_filters.each do |col, search_args|
      use_regex = search_args[REGEX] == TRUE
      val = search_args[VALUE]

      if use_regex
        items = items.where(format(FORMAT_REGEX_COLUMN, col), val)
      else
        items = items.where(col => val)
      end
    end

    items
  end

  def fulldata?
    params[LENGTH].to_i == FULL_LENGTH
  end

  def search_value
    return '' if params[SEARCH].blank?
    params[SEARCH][VALUE]
  end

  def link_if_exists(data)
    return '' if data.blank?
    link_to data
  end
end

