# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class OrdersPageStructure
  setTable: (@table_id)->

  setUploadInput: (@upload_input_id)->

  isDataTableInit: ->
    $.fn.dataTable.isDataTable('#' + @table_id)

class PageStructureBuilder
  constructor: ->
    @page_structure = new OrdersPageStructure()

  addOrdersTable: (table_id, search = false, itemsCount = false) ->
    @page_structure.setTable(table_id)
    if !@page_structure.isDataTableInit()
      $('#' + table_id).dataTable
        bJQueryUI: true
        bInfo: itemsCount
        bFilter: search
        scrollX: true
        paging: false
        ordering: false
    this

  addButtonListener: (button_id, action)->
    $('#' + button_id).click action
    this

  addUploadInput: (upload_input_id)->
    @page_structure.setUploadInput(upload_input_id)
    this

  addUploadInputChangeListener: (action)->
    $('#' + @page_structure.upload_input_id).on 'change', action
    this

  addInLineEditForTable: ->
    $('#' + @page_structure.table_id).editableTableWidget();
    this

class OrdersController

  constructor: (@page_structure)->

  upload_orders_from_csv_file: (file) ->
    if (file.type.match('csv.*'))
      Papa.parse(file,
        header: true
        worker: true
        skipEmptyLines: true
        complete: (results, file) =>
#console.log ('completed')
#console.log (results.data)
          this.try_upload JSON.stringify(results.data)
      )
    else
      alert('file is not *.csv')

  upload_orders_from_table: () ->
    table = $('#' + @page_structure.table_id)
    orders_json = JSON.stringify(table.tableToJSON())
    console.log (orders_json)
    this.try_upload orders_json

  try_upload: (orders_as_json)  ->
    upload_form = $('<form>', {
      'action': '/save_orders',
      'method': 'post'
      'target': '_top'
      'encrypt': 'application/json'
    }).append($('<input>', {
      'name': 'data'
      'value': orders_as_json.replace(new RegExp("client name", 'g'), "destination_name")
#'value': orders_as_json
    })).append($('<input>', {
      'type': 'hidden',
      'name': 'authenticity_token',
      'value': window._token
    }));
    upload_form.submit();

$(document).on "page:change", ->
  if (top.location.pathname == '/order_releases')
    page_structure_builder = new PageStructureBuilder()
    page_structure = page_structure_builder
    .addOrdersTable('order_releases_list')
    .addButtonListener('upload_button', ->
      $('#upload_input').click()
    )
    .addUploadInput('upload_input')
    .addUploadInputChangeListener((event)->
      event.preventDefault()
      orders_controller.upload_orders_from_csv_file($('#upload_input').prop('files')[0])
    ).page_structure
    orders_controller = new OrdersController(page_structure)


  else if (top.location.pathname == '/save_orders')
    page_structure_builder_2 = new PageStructureBuilder()
    page_structure_2 = page_structure_builder_2.addOrdersTable("order_releases_upload", false, true)
    .addButtonListener('proceed_button', ->
      orders_controller_2.upload_orders_from_table()
    ).addInLineEditForTable().page_structure
    orders_controller_2 = new OrdersController(page_structure_2)
