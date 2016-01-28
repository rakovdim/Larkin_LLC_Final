# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class PageStructureBuilder
  constructor: (@loadController) ->
    @pageStructure = new PageStructure()
    @loadController.setPageStructure(@pageStructure)

  adddownloadButton: (buttonId) ->
    downloadButton = $('#' + buttonId)
    @pageStructure.setDownloadButton(downloadButton)
    downloadButton.click =>
      @loadController.downloadRoutingList()

    this


  addDeliveryDateInput: (deliveryDateInputId)->
    deliveryDateInput = $('#' + deliveryDateInputId)
    @pageStructure.setDeliveryDateInput(deliveryDateInput)
    deliveryDateInput.change =>
      @loadController.changeDate()
    this

  addDeliveryShiftSelect: (deliveryShiftSelectId) ->
    deliveryShiftSelect = $('#' + deliveryShiftSelectId)
    @pageStructure.setDeliveryShiftSelect(deliveryShiftSelect)
    deliveryShiftSelect.change =>
      @loadController.changeShift()
    this

  addDeliveryOrdersTable: (tableId)->
    if !Table.isDataTableInit(tableId)
      deliveryOrdersTable = this.createDataTable(tableId, '/get_delivery_data')
      @pageStructure.setDeliveryOrdersTable(deliveryOrdersTable)
    this


  createDataTable: (tableId, ajaxUrl) ->
    table = new Table(tableId)
    commonData = {
      scrollX: false
      processing: false
      serverSide: true
      ordering: false
      bPaginate: false
      bInfo: false
      bLengthChange: false
      autoWidth: false
      bFilter: false
      bSort: false
      rowId: 'id'
      ajax: {
        url: ajaxUrl
        data: (d)=>
          d.columns = null
          d.seatch = null
          d.delivery_date = @pageStructure.getDeliveryDate()
          d.delivery_shift = @pageStructure.getDeliveryShift()
          d
      }

      columns: [
        {data: "stop_order_number"}
        {data: "purchase_order_number"}
        {data: "delivery_type"}
        {data: "volume"}
        {data: "handling_unit_quantity"}
        {data: "origin_raw_line_1"}
        {data: "destination_raw_line_1"}
        {data: "phone_number"}]
    }

    table.setAPI($('#' + tableId).DataTable(commonData))
    table


class Table
  constructor: (@tableId)->

  @isDataTableInit: (tableId) ->
    tableId != undefined && $.fn.dataTable.isDataTable('#' + tableId)

  getOrdersCount: ->
    @API.rows()[0].length

  setAPI: (API) ->
    @API = API
    this

  isEmpty: ()->
    @API.rows().count() == 0

  refresh: ->
    @API.ajax.reload()

class PageStructure
  constructor: ->
  setDeliveryOrdersTable: (@deliveryOrdersTable)->
  setDeliveryShiftSelect: (@deliveryShiftSelect)->
  setDeliveryDateInput: (@deliveryDateInput)->
  setDownloadButton: (@downloadButton)->

  getDeliveryShift: ->
    @deliveryShiftSelect.val()

  getDeliveryDate: ->
    @deliveryDateInput.val()

class LoadController
  setPageStructure: (@pageStructure) ->

  downloadRoutingList: ->
    if @pageStructure.deliveryOrdersTable.isEmpty()
      alert 'There are no ready for delivery orders (for specified date and shift)'
    else
      download_form = $('<form>', {
        'action': '/download_routing_list.csv',
        'method': 'get'
      }).append($('<input>', {
        'name': 'delivery_date'
        'value': @pageStructure.getDeliveryDate()
      })).append($('<input>', {
        'name': 'delivery_shift'
        'value': @pageStructure.getDeliveryShift()
      }))
      .append($('<input>', {
        'type': 'hidden',
        'name': 'authenticity_token',
        'value': window._token
      }));
      download_form.submit();

  changeDate: ->
    @pageStructure.deliveryOrdersTable.refresh()

  changeShift: ->
    @pageStructure.deliveryOrdersTable.refresh()


$(document).on "page:change", ->
  if (top.location.pathname == '/orders_delivery')
    $('#delivery_date_input').datepicker()
    loadController = new LoadController()

    pageBuilder = new PageStructureBuilder(loadController)

    pageBuilder.addDeliveryShiftSelect('load_delivery_shift').
    addDeliveryDateInput('delivery_date_input').
    addDeliveryOrdersTable('orders_delivery_table').
    adddownloadButton('download_routing_list_button')
