# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class PageStructureBuilder
  constructor: (@load_controller) ->
    @page_structure = new PageStructure()
    @load_controller.setPageStructure(@page_structure)

  addSplitOrderDialog: (split_order_dialog_id, split_action) ->
    dialog = $('#' + split_order_dialog_id).dialog({
      autoOpen: false
      height: 250
      width: 350
      modal: true
      buttons: {
        "Split Order": ->
          console.log('aaaa')
          split_action()
        Cancel: ->
          dialog.dialog("close")
      }
      close: ->
        dialog.find("form")[0].reset()
    })

  addLoadStatusLabel: (loadStatusLabelId) ->
    @page_structure.setLoadStatusLabelId(loadStatusLabelId)
    this

  addSubmitOrdersListener: (button_id)->
    @page_structure.setSubmitButtonId(button_id)
    $('#' + button_id).click =>
      @load_controller.submitOrders()
    this

  addCompleteLoadListener: (button_id)->
    @page_structure.setCompleteLoadButtonId(button_id)
    $('#' + button_id).click =>
      @load_controller.completeLoad()
    this

  addReturnOrdersListener: (button_id)->
    @page_structure.setReturnButtonId(button_id)
    $('#' + button_id).click =>
      @load_controller.returnOrders()
    this

  addTruckVolumeLabel: (truck_volume_label_id)->
    @page_structure.setTruckVolumeLabelId(truck_volume_label_id)
    this

  addDeliveryDateInput: (delivery_date_input_id)->
    @page_structure.setDeliveryDateInputId(delivery_date_input_id)
    $('#' + delivery_date_input_id).change =>
      @load_controller.changeDate()
    this

  addTruckInput: (truck_input_id)->
    @page_structure.setTruckSelectId(truck_input_id)
    this

  addDeliveryShiftSelect: (delivery_shift_select_id) ->
    @page_structure.setDeliveryShiftSelectId(delivery_shift_select_id)
    $('#' + delivery_shift_select_id).change =>
      @load_controller.changeShift()
    this

  addAvailableOrdersTable: (table_id) ->
    if !Table.isDataTableInit(table_id)
      av_orders_table = this.constructEntireTable(table_id, '/get_available_orders', 'av_orders_checkbox', true, false)
      @page_structure.setAvailableOrdersTable(av_orders_table)
    this

  addPlanningOrdersTable: (table_id)->
    if !Table.isDataTableInit(table_id)
      plan_orders_table = this.constructEntireTable(table_id, '/get_planning_orders', 'plan_orders_checkbox', false, true)
      this.addRowReorderListener(plan_orders_table).addRefreshTableListener(plan_orders_table)
      @page_structure.setPlanningOrdersTable(plan_orders_table)
    this

  constructEntireTable: (table_id, ajax_url, all_orders_checkbox_id, paging, dnd) ->
    table = this.createDataTable(table_id, ajax_url, all_orders_checkbox_id, paging, dnd)
    this.addNextPageTableListener(table).addSelectAllOrdersListener(table)
    table

  addNextPageTableListener: (table) ->
    table.API.on 'page.dt', =>
      @load_controller.toNextPage(table)
    this

  addSelectAllOrdersListener: (table) ->
    $('#' + table.allOrdersCheckbox.checkbox_id).click =>
      @load_controller.checkAllOrders(table)
    this

#todo it is performed after ajax request has been sent. it is incorrect
  addRefreshTableListener: (table) ->
    table.API.on 'xhr.dt', (e, settings, json, xhr) =>
      @load_controller.updatePageData(json)
    this

  addRowReorderListener: (table) ->
    table.API.on 'row-reorder', (e, diff, edit) =>
      order_id = edit.triggerRow.data().id
      for row_change in diff
        if (row_change != undefined && row_change.node != undefined && parseInt(row_change.node.id) == order_id)
          console.log (order_id + '_' + row_change.oldPosition + '_' + row_change.newPosition)
          @load_controller.reorder_planning_orders(order_id, row_change.oldPosition, row_change.newPosition)
          break
    this

  finish: ->
    @page_structure

  createDataTable: (table_id, ajax_url, all_orders_checkbox_id, paging, dnd) ->
    table = new Table(table_id)
    table.setAllOrdersCheckbox(Checkbox.createAllOrdersCheckbox(all_orders_checkbox_id))
    common_data = {
      scrollY: '400px'
      processing: true
      serverSide: true
      ordering: false
      pageLength: 10
      bPaginate: paging
      bInfo: paging
      bLengthChange: false
      autoWidth: false
      bFilter: false
      bSort: false
      rowId: 'id'
      ajax: {
        url: ajax_url
        data: (d)=>
          d.columns = null
          d.seatch = null
          d.delivery_date = @page_structure.getDeliveryDate()
          d.delivery_shift = @page_structure.getDeliveryShift()
          d
      }

      rowCallback: (row, data, dataIndex)=>
        order_id = data.id
        checkbox = Checkbox.createOrderCheckbox(order_id)
        first_td = $(row).find('td:first')
        first_td.html(checkbox.toHTMLInput())
        table.addCheckbox(checkbox)
        first_td.change '#' + checkbox.checkbox_id, ->
          console.log (order_id)

      columns: [
        {data: "purchase_order_number"}
        {data: "purchase_order_number"}
        {data: "delivery_date"}
        {data: "delivery_shift"}
        {data: "delivery_type"}
        {data: "volume"}
        {data: "handling_unit_quantity"}
        {data: "destination_raw_line_1"}
        {data: "origin_raw_line_1"}]
    }
    if (dnd)
      common_data['rowReorder'] = {selector: 'tr td:not(:first-child)'}

    table.setAPI($('#' + table_id).DataTable(common_data))
    table


class Checkbox
  constructor: (@order_id, @checkbox_id)->

  consturctor: (@checkbox_id)->

  toHTMLInput: ->
    '<td class="order-checkbox"><input  type="checkbox" id =' + @checkbox_id + '></td>'

  isChecked: ->
    $('#' + @checkbox_id).is(':checked')

  setChecked: (checked)->
    $('#' + @checkbox_id).prop('checked', checked)

  @createOrderCheckbox: (order_id) ->
    new Checkbox(order_id, 'cb_' + order_id)

  @createAllOrdersCheckbox: (checkbox_id) ->
    new Checkbox(null, checkbox_id)

class Table
  constructor: (table_id)->
    @checkboxesMap = {}
    @table_id = table_id

  @isDataTableInit: (table_id) ->
    table_id != undefined && $.fn.dataTable.isDataTable('#' + table_id)

  checkAll: ->
    checked = @allOrdersCheckbox.isChecked()
    $.map(@checkboxesMap, (checkbox)=>
      checkbox.setChecked(checked))
    console.log (this.getCheckedOrders())

  getOrdersCount: ->
    @API.rows()[0].length

  getCheckedOrders: ->
    result = []
    $.map(@checkboxesMap, (checkbox)=>
      if (checkbox.isChecked())
        result.push checkbox.order_id)
    result

  setAPI: (API) ->
    @API = API
    this

  resetCheckboxes: () ->
    @allOrdersCheckbox.setChecked(false)
    @checkboxesMap = {}

  refresh: (preservePaging) ->
    this.resetCheckboxes()
    @API.draw (!preservePaging)

  addCheckbox: (checkbox)->
    @checkboxesMap[checkbox.order_id] = checkbox

  setAllOrdersCheckbox: (@allOrdersCheckbox)->

  isInit: ->
    $.fn.dataTable.isDataTable(@table_id)


class PageStructure
  constructor: ->
  setPlanningOrdersTable: (@planned_orders_table)->
  setAvailableOrdersTable: (@available_orders_table)->
  setDeliveryShiftSelectId: (@delivery_shift_select_id)->
  setDeliveryDateInputId: (@delivery_date_input_id)->
  setTruckSelectId: (@truck_select_id)->
  setTruckVolumeLabelId: (@truck_load_volume_id)->
  setLoadStatusLabelId: (@loadStatusLabelId)->
  setSubmitButtonId: (@submit_button_id)->
  setReturnButtonId: (@return_button_id)->
  setCompleteLoadButtonId: (@complete_load_button_id)->

  isAlreadyInit: ->
    this.isTableInit(@planned_orders_table)
    this.isTableInit(@available_orders_table)

  isTableInit: (table) ->
    table != undefined && table.isInit()

  getDeliveryShift: ->
    $('#' + @delivery_shift_select_id).val()

  getDeliveryDate: ->
    $('#' + @delivery_date_input_id).val()

  getTruck: ->
    $('#' + @truck_select_id).val()

  setTruckVolume: (capacity) ->
    $('#' + @truck_load_volume_id).text(capacity);

  setLoadStatus: (load_status) ->
    $('#' + @loadStatusLabelId).text(load_status);
    if (load_status != 'Not planned')
      this.setPageDisabled(true)
    else
      this.setPageDisabled(false)

  setPageDisabled: (disabled)->
    $('#' + @truck_select_id).prop('disabled', disabled)
    $('#' + @submit_button_id).prop('disabled', disabled)
    $('#' + @return_button_id).prop('disabled', disabled)
    $('#' + @complete_load_button_id).prop('disabled', disabled)

  updatePageData: (page_data)->
    if (page_data != null && page_data != undefined)
      if (page_data.truck_volume != null)
        this.setTruckVolume(page_data.truck_volume)
      if (page_data.load_status != null)
        this.setLoadStatus (page_data.load_status)

  reloadTables: (save_pagination)->
    @planned_orders_table.refresh(save_pagination)
    @available_orders_table.refresh(save_pagination)

class LoadController
  setPageStructure: (@page_structure) ->

  toNextPage: (table)->
    table.resetCheckboxes()

  checkAllOrders: (table) ->
    table.checkAll()

  changeDate: ->
    @page_structure.reloadTables(false)

  changeShift: ->
    @page_structure.reloadTables(false)

  updatePageData: (data)->
    @page_structure.updatePageData(data)

  reorder_planning_orders: (order_id, oldPos, newPos) ->
    this.executeAjaxRequest('/reorder_planning_orders', this.reorderOrdersRequest(order_id, oldPos, newPos))

  completeLoad: ->
    if (@page_structure.planned_orders_table.getOrdersCount() > 0)
      this.executeAjaxRequest('/complete_load', this.completeLoadRequest(), 'Load has been successfully planned for delivery')
    else
      alert 'Cant complete load. No orders. Submit at least one order'

  submitOrders: ->
    av_orders_table = @page_structure.available_orders_table
    this.perfromSubmitReturnOrders(av_orders_table, '/submit_orders')

  returnOrders: ->
    plan_orders_table = @page_structure.planned_orders_table
    this.perfromSubmitReturnOrders(plan_orders_table, '/return_orders')

  perfromSubmitReturnOrders: (table, url, success_message = undefined)->
    checked_orders = table.getCheckedOrders()
    if (checked_orders.length > 0)
      this.executeAjaxRequest(url, this.submitReturnOrdersRequest(table), success_message)
    else
      alert "Please select at least one order"

  executeAjaxRequest: (request_url, request_data, success_message)->
    $.ajax({
      url: request_url,
      type: 'POST',
      data: request_data
      success: (data) =>
        this.processOrdersUpdate(data, success_message)
      error: (data)=>
        alert this.internalErrorMessage
    })

  processOrdersUpdate: (data, success_message) ->
    if (data.status == 'success')
      this.onUpdateSuccess(data, success_message)
    else
      this.onUpdateFail(data)

  onUpdateSuccess: (data, success_message) ->
    if (success_message != undefined )
      alert success_message
    @page_structure.reloadTables(true)

  onUpdateFail: (data) ->
    alert('Exception occurs: ' + data.message)

  internalErrorMessage: ->
    'Internal error occurs. Please contact to your administrator'

  completeLoadRequest: ->
    {
    delivery_date: @page_structure.getDeliveryDate(),
    delivery_shift: @page_structure.getDeliveryShift()
    }

  submitReturnOrdersRequest: (table)->
    {
    delivery_date: @page_structure.getDeliveryDate(),
    delivery_shift: @page_structure.getDeliveryShift(),
    orders: table.getCheckedOrders()
    truck: @page_structure.getTruck()
    }

  reorderOrdersRequest: (order, oldPos, newPos)->
    {order_id: order, old_position: oldPos, new_position: newPos}

class SubmitRequest
  cosntructor: (@delivery_date, @delivery_shift, @orders) ->

class LoadView
  setPageStructure: (@page_structure)->

  init_defaults: ->

  get_current_date: ->
    new Date().ddmmyyyy()

$(document).on "page:change", ->
  $('#delivery_date_input').datepicker()


  $('#split_av_order_button').click ->
    dialog.dialog("open");

  load_controller = new LoadController()

  page_builder = new PageStructureBuilder(load_controller)

  page_builder.addDeliveryShiftSelect('load_delivery_shift').
  addTruckVolumeLabel('truck_volume').
  addDeliveryDateInput('delivery_date_input').
  addTruckInput('load_truck').
  addAvailableOrdersTable('available_orders').
  addPlanningOrdersTable('planning_orders').
  addSubmitOrdersListener('submit_orders_button').
  addReturnOrdersListener('return_orders_button').
  addCompleteLoadListener('complete_load_button').
  addLoadStatusLabel('load_status_value').
  addSplitOrderDialog('split_order_dialog')


