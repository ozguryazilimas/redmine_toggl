
var current_page_datatables;

var datatables_defaults = {
  // lengthMenu: [[20, 50, 100, 250, -1], [20, 50, 100, 250, datatable_str.all]],
  lengthMenu: [[20, 50, 100, 250], [20, 50, 100, 250]],
  pageLength: 50,
  order: [[datatable_order_index, 'desc']],
  columnDefs: [
    {
      targets: 'datatable_no_order',
      orderable: false
    },
    {
      targets: 'datatable_no_search',
      searchable: false
    }
  ],
  language: {
    search: '',
    lengthMenu: "_MENU_",
    emptyTable: datatable_str.empty_table,
    zeroRecords: datatable_str.empty_table,
    info: datatable_str.info,
    infoEmpty: '',
    infoFiltered: '',
    paginate: {
      first: datatable_str.first,
      last: datatable_str.last,
      next: datatable_str.next,
      previous: datatable_str.previous
    }
  }
};

function str_includes(full_str, search_str) {
  var matches = false;

  if (typeof search_str !== 'undefined' && search_str !== null &&
    typeof full_str !== 'undefined' && full_str !== null) {

    var search_str_lower = search_str.toLowerCase();
    var full_str_lower = full_str.toLowerCase();

    matches = full_str_lower.indexOf(search_str_lower) !== -1;
  }

  return matches;
}

$(function() {

  datatables_config = $.extend(
    {},
    datatables_defaults,
    {
      processing: true,
      serverSide: true,
      ajax: {
        // type: 'POST'
        url: $('.serverside_datatables').data('source')
      },
    }
  );

  current_page_datatables = $('.serverside_datatables').dataTable(datatables_config);
  $('.dataTables_filter input').attr('placeholder', datatable_str.search);

});

