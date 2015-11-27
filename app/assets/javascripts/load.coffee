# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class PageStructureBuilder
  constructor: (@loadController) ->
    @pageStructure = new PageStructure()
    @loadController.setPageStructure(@pageStructure)

  addReopenLoadButton: (buttonId)->
    button = $('#' + buttonId)
    @pageStructure.setReopenLoadButton(button)
    button.click =>
      @loadController.reopenLoad()
    this

  addSplitAvOrderButton: (buttonId) ->
    button = $('#' + buttonId)
    @pageStructure.setSplitAvOrderButton(button)
    table = @pageStructure.availableOrdersTable
    this.addSplitOrderButton(button, table)
    this

  addSplitPlanOrderButton: (buttonId) ->
    button = $('#' + buttonId)
    @pageStructure.setSplitPlanOrderButton(button)
    table = @pageStructure.planningOrdersTable
    this.addSplitOrderButton(button, table)
    this

  addSplitOrderButton: (button, table) ->
    button.click =>
      @loadController.openSplitOrderDialog(table)

  addLoadStatusLabel: (loadStatusLabelId) ->
    @pageStructure.setLoadStatusLabelId(loadStatusLabelId)
    this

  addSubmitOrdersButton: (buttonId)->
    button = $('#' + buttonId)
    @pageStructure.setSubmitButton(button)
    button.click =>
      @loadController.submitOrders()
    this

  addCompleteLoadButton: (buttonId)->
    button = $('#' + buttonId)
    @pageStructure.setCompleteLoadButton(button)
    button.click =>
      @loadController.completeLoad()
    this

  addReturnOrdersButton: (buttonId)->
    button = $('#' + buttonId)
    @pageStructure.setReturnButton(button)
    button.click =>
      @loadController.returnOrders()
    this

  addTruckVolumeLabel: (truckVolumeLabelId)->
    @pageStructure.setTruckVolumeLabelId(truckVolumeLabelId)
    this

  addDeliveryDateInput: (deliveryDateInputId)->
    @pageStructure.setDeliveryDateInputId(deliveryDateInputId)
    $('#' + deliveryDateInputId).change =>
      @loadController.changeDate()
    this

  addTruckSelect: (truckInputId)->
    truckSelect = $('#' + truckInputId)
    @pageStructure.setTruckSelect(truckSelect)
    truckSelect.change =>
      @loadController.changeTruckForLoad()
    this

  addDeliveryShiftSelect: (deliveryShiftSelectId) ->
    @pageStructure.setDeliveryShiftSelectId(deliveryShiftSelectId)
    $('#' + deliveryShiftSelectId).change =>
      @loadController.changeShift()
    this

  addAvailableOrdersTable: (tableId) ->
    if !Table.isDataTableInit(tableId)
      avOrdersTable = this.constructEntireTable(tableId, '/get_available_orders', 'av_orders_checkbox', true, false)
      @pageStructure.setAvailableOrdersTable(avOrdersTable)
    this

  addPlanningOrdersTable: (tableId)->
    if !Table.isDataTableInit(tableId)
      planOrdersTable = this.constructEntireTable(tableId, '/get_load_data', 'plan_orders_checkbox', false, true)
      this.addRowReorderListener(planOrdersTable).addRefreshTableListener(planOrdersTable)
      @pageStructure.setPlanningOrdersTable(planOrdersTable)
    this

  constructEntireTable: (tableId, ajaxUrl, allOrdersCheckboxId, paging, dnd) ->
    table = this.createDataTable(tableId, ajaxUrl, allOrdersCheckboxId, paging, dnd)
    this.addNextPageTableListener(table).addSelectAllOrdersListener(table)
    table

  addNextPageTableListener: (table) ->
    table.API.on 'page.dt', =>
      @loadController.toNextPage(table)
    this

  addSelectAllOrdersListener: (table) ->
    $('#' + table.allOrdersCheckbox.checkboxId).click =>
      @loadController.checkAllOrders(table)
    this

#todo it is performed after ajax request has been sent. Maybe it is incorrect
  addRefreshTableListener: (table) ->
    table.API.on 'xhr.dt', (e, settings, json, xhr) =>
      @loadController.updatePageDataSync(json)
    this

  addRowReorderListener: (table) ->
    table.API.on 'row-reorder', (e, diff, edit) =>
      orderId = edit.triggerRow.data().id
      for rowChange in diff
        if (rowChange != undefined && rowChange.node != undefined && parseInt(rowChange.node.id) == orderId)
          console.log (orderId + '_' + rowChange.oldPosition + '_' + rowChange.newPosition)
          @loadController.reorderPlanningOrders(orderId, rowChange.oldPosition, rowChange.newPosition)
          break
    this

  createDataTable: (tableId, ajaxUrl, allOrdersCheckboxId, paging, dnd) ->
    table = new Table(tableId)
    table.setAllOrdersCheckbox(Checkbox.createAllOrdersCheckbox(allOrdersCheckboxId))
    commonData = {
      scrollY: '400px'
      scrollX: false
      processing: false
      serverSide: true
      ordering: false
      pageLength: 12
      bPaginate: paging
      bInfo: paging
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

      rowCallback: (row, data, dataIndex)=>
        orderId = data.id
        checkbox = Checkbox.createOrderCheckbox(orderId)
        firstTd = $(row).find('td:first')
        firstTd.html(checkbox.toHTMLInput())
        table.addCheckbox(checkbox)
        firstTd.change '#' + checkbox.checkboxId, ->
          console.log (orderId)

      columns: [
        {data: "purchase_order_number"}
        {data: "purchase_order_number"}
        {data: "delivery_date"}
        {data: "delivery_shift"}
        {data: "delivery_type"}
        {data: "volume"}
        {data: "handling_unit_quantity"}
        {data: "origin_raw_line_1"}
        {data: "destination_raw_line_1"}
      ]
    }
    if (dnd)
      commonData['rowReorder'] = {selector: 'tr td:not(:first-child)'}

    table.setAPI($('#' + tableId).DataTable(commonData))
    table

  addSplitOrderDialog: (splitOrderDialogId) ->
    dialog = $('#' + splitOrderDialogId).dialog({
      autoOpen: false
      height: 250
      width: 350
      modal: true
      buttons: {
        "Split Order": =>
          orderData = @pageStructure.splitOrderDialog.jqueryDialog.data('orderData')
          @loadController.splitOrderFromDialog(orderData)
        Cancel: =>
          @pageStructure.splitOrderDialog.jqueryDialog.dialog("close")
      }
      close: =>
        splitOrderDialog = @pageStructure.splitOrderDialog
        splitOrderDialog.form[0].reset()
        splitOrderDialog.allFields.removeClass("ui-state-error");
    })
    splitDialog = new SplitDialog('new_volume', 'new_quantity', dialog)
    @pageStructure.setSplitOrderDialog(splitDialog)
    this

class Checkbox
  constructor: (@orderId, @checkboxId)->

  toHTMLInput: ->
    '<td class="order-checkbox"><input  type="checkbox" id =' + @checkboxId + '></td>'

  isChecked: ->
    $('#' + @checkboxId).is(':checked')

  setChecked: (checked)->
    $('#' + @checkboxId).prop('checked', checked)

  @createOrderCheckbox: (orderId) ->
    new Checkbox(orderId, 'cb_' + orderId)

  @createAllOrdersCheckbox: (checkboxId) ->
    new Checkbox(null, checkboxId)

class Table
  constructor: (tableId)->
    @checkboxesMap = {}
    @tableId = tableId

  @isDataTableInit: (tableId) ->
    tableId != undefined && $.fn.dataTable.isDataTable('#' + tableId)

  checkAll: ->
    checked = @allOrdersCheckbox.isChecked()
    $.map(@checkboxesMap, (checkbox)=>
      checkbox.setChecked(checked))
    console.log (this.getCheckedOrderIds())

  getOrdersCount: ->
    @API.rows()[0].length

  getCheckedOrderIds: ->
    result = []
    $.map(@checkboxesMap, (checkbox)=>
      if (checkbox.isChecked())
        result.push(checkbox.orderId))
    result

  getCheckedOrdersData: ->
    result = []
    $.map(@checkboxesMap, (checkbox)=>
      if (checkbox.isChecked())
        rowData = @API.row('#' + checkbox.orderId).data()
        result.push rowData)
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
    @checkboxesMap[checkbox.orderId] = checkbox

  setAllOrdersCheckbox: (@allOrdersCheckbox)->

  isInit: ->
    $.fn.dataTable.isDataTable(@tableId)

class SplitDialog
  constructor: (newVolumeId, newQuantityId, @jqueryDialog)->
    @newVolume = $('#' + newVolumeId)
    @newQuantity = $('#' + newQuantityId)
    @allFields = $([]).add(@newVolume).add(@newQuantity)
    @tips = $(".validateTips");
    @dialogId = @jqueryDialog.id
    @form = @jqueryDialog.find("form")

  setVolume: (volume) ->
    @newVolume.val

  getNewVolume: ->
    @newVolume.val()

  getNewQuantity: ->
    @newQuantity.val()

  setNewVolume: (volume) ->
    @newVolume.val(volume)

  setNewQuantity: (quantity) ->
    @newQuantity.val(quantity)

  isVolumeValid: (currentVolume) ->
    valid = this.isDataValid("volume", this.getNewVolume(), currentVolume)
    if (valid && !this.isNum(this.getNewVolume()))
      this.setTips("Volume should be number")
      valid = false
    valid

  isQuantityValid: (currentQuantity) ->
    valid = this.isDataValid("quantity", this.getNewQuantity(), currentQuantity)
    if (valid && !this.isInt(this.getNewQuantity()))
      this.setTips("Quantity should be integer")
      valid = false
    valid

  setTips: (message)->
    @tips.text(message).addClass("ui-state-highlight");
    setTimeout =>
      @tips.removeClass("ui-state-highlight", 1500)
    , 500

  isDataValid: (fieldName, value, currentValue) ->
    if (value == null || value == undefined || value == "")
      this.setTips("New #{fieldName} can't be empty")
      return false
    if (value <= 0)
      this.setTips("New #{fieldName} should be positive")
      return false
    if (value >= currentValue)
      this.setTips("New #{fieldName} should be less than orignal #{fieldName}")
      return false
    true

  isInt: (n)->
    result = parseInt(n, 10)
    !isNaN(result) && (Math.floor(n) == result)

  isNum: (n)->
    !isNaN(parseFloat(n))


class PageStructure
  constructor: ->
  setLoadId: (@loadId)->
  setPlanningOrdersTable: (@planningOrdersTable)->
  setAvailableOrdersTable: (@availableOrdersTable)->
  setDeliveryShiftSelectId: (@deliveryShiftSelectId)->
  setDeliveryDateInputId: (@deliveryDateInputId)->
  setTruckSelect: (@truckSelect)->
  setTruckVolumeLabelId: (@truckLoadVolumeId)->
  setLoadStatusLabelId: (@loadStatusLabelId)->
  setSubmitButton: (@submitButton)->
  setReturnButton: (@returnButton)->
  setCompleteLoadButton: (@completeLoadButton)->
  setSplitAvOrderButton: (@splitAvOrderButton)->
  setSplitPlanOrderButton: (@splitPlanOrderButton)->
  setSplitOrderDialog: (@splitOrderDialog)->
  setReopenLoadButton: (@reopenLoadButton)->

  isAlreadyInit: ->
    this.isTableInit(@planningOrdersTable)
    this.isTableInit(@availableOrdersTable)

  isTableInit: (table) ->
    table != undefined && table.isInit()

  getDeliveryShift: ->
    $('#' + @deliveryShiftSelectId).val()

  getDeliveryDate: ->
    $('#' + @deliveryDateInputId).val()

  getTruckId: ->
    @truckSelect.val()

  setTruck: (truckId) ->
    @truckSelect.val(truckId)

  setTruckVolume: (volume) ->
    $('#' + @truckLoadVolumeId).text(Number((volume).toFixed(1)))

  setLoadStatus: (loadStatus) ->
    $('#' + @loadStatusLabelId).text(loadStatus);
    if (loadStatus != 'Not planned')
      this.setPagePlanned(true)
    else
      this.setPagePlanned(false)

  setPagePlanned: (disabled)->
    @truckSelect.prop('disabled', disabled)
    @submitButton.prop('disabled', disabled)
    @returnButton.prop('disabled', disabled)
    @completeLoadButton.prop('disabled', disabled)
    @splitPlanOrderButton.prop('disabled', disabled)
    @reopenLoadButton.prop('disabled', !disabled)

  updatePageData: (pageData)->
    if (pageData != null && pageData != undefined)
      this.setLoadId(pageData.load_id)
      if (pageData.truck_volume != null)
        this.setTruckVolume(pageData.truck_volume)
      if (pageData.load_status != null)
        this.setLoadStatus (pageData.load_status)
      if (pageData.truck_id != null && pageData.truck_id != undefined)
        this.setTruck(pageData.truck_id)


  reloadTables: (savePagination)->
    @planningOrdersTable.refresh(savePagination)
    @availableOrdersTable.refresh(savePagination)

class LoadController
  setPageStructure: (@pageStructure) ->

  toNextPage: (table)->
    table.resetCheckboxes()

  checkAllOrders: (table) ->
    table.checkAll()

  changeDate: ->
    @pageStructure.reloadTables(false)

  changeShift: ->
    @pageStructure.reloadTables(false)

  changeTruckForLoad: ->
    if (@pageStructure.loadId != null && @pageStructure.loadId != undefined )
      this.executeAjaxRequest('/update_load_data', this.updateLoadRequest())

  updatePageDataSync: (data)->
    @pageStructure.updatePageData(data)

  reorderPlanningOrders: (orderId, oldPos, newPos) ->
    this.executeAjaxRequest('/reorder_planning_orders', this.reorderOrdersRequest(orderId, oldPos, newPos))

  openSplitOrderDialog: (table) ->
    ordersData = table.getCheckedOrdersData()
    if (ordersData.length != 1)
      alert 'Please select one order to split'
    else
      orderData = ordersData[0]
      if (orderData.handling_unit_quantity == 1 || orderData.volume == 0)
        alert "Quantity is 1 or volume is 0 for this order. You can't split it"
      else
        splitDialog = @pageStructure.splitOrderDialog
        splitDialog.setNewVolume(orderData.volume)
        splitDialog.setNewQuantity(orderData.handling_unit_quantity)
        splitDialog.jqueryDialog.data('orderData', orderData).dialog("open");

  splitOrderFromDialog: (orderData)->
    valid = true;
    splitDialog = @pageStructure.splitOrderDialog
    splitDialog.allFields.removeClass("ui-state-error");

    valid = valid && splitDialog.isQuantityValid(orderData.handling_unit_quantity);
    valid = valid && splitDialog.isVolumeValid(orderData.volume)

    if (valid)
      this.splitOrder(orderData.id, splitDialog.getNewQuantity(), splitDialog.getNewVolume())
      splitDialog.jqueryDialog.dialog('close')

    valid

  splitOrder: (orderId, newQuantity, newVolume)->
    console.log (orderId + '__' + newQuantity + '__' + newVolume)
    this.executeAjaxRequest('/split_order', this.splitOrderRequest(orderId, newQuantity, newVolume))

  reopenLoad: ->
    this.executeAjaxRequest('/reopen_load', this.genericLoadRequest(), 'Load has been successfully reopened')

  completeLoad: ->
    if (@pageStructure.planningOrdersTable.getOrdersCount() > 0)
      this.executeAjaxRequest('/complete_load', this.genericLoadRequest(), 'Load has been successfully planned for delivery')
    else
      alert 'Cant complete load. No orders. Submit at least one order'

  submitOrders: ->
    avOrdersTable = @pageStructure.availableOrdersTable
    this.perfromSubmitReturnOrders(avOrdersTable, '/submit_orders')

  returnOrders: ->
    planOrdersTable = @pageStructure.planningOrdersTable
    this.perfromSubmitReturnOrders(planOrdersTable, '/return_orders')

  perfromSubmitReturnOrders: (table, url, successMessage = undefined)->
    checkedOrders = table.getCheckedOrderIds()
    if (checkedOrders.length > 0)
      this.executeAjaxRequest(url, this.submitReturnOrdersRequest(table), successMessage)
    else
      alert "Please select at least one order"

  executeAjaxRequest: (requestURL, requestData, successMessage)->
    $.ajax({
      url: requestURL,
      type: 'POST',
      data: requestData
      success: (data) =>
        this.processOrdersUpdate(data, successMessage)
      error: (data)=>
        alert this.internalErrorMessage()
    })

  processOrdersUpdate: (data, successMessage) ->
    if (data.status == 'success')
      this.onUpdateSuccess(data, successMessage)
    else
      if (data.status == 'warning')
        this.onUpdateWarning(data)
      else
        this.onUpdateFail(data)

  onUpdateSuccess: (data, successMessage) ->
    if (successMessage != undefined )
      alert successMessage
    @pageStructure.reloadTables(true)

  onUpdateFail: (data) ->
    console.log ('called')
    alert('Exception occurs: ' + data.message)

  onUpdateWarning: (data) ->
    alert('Warning: ' + data.message)
    @pageStructure.reloadTables(true)


  internalErrorMessage: ->
    'Internal error occurs. Please contact to your administrator'

  genericLoadRequest: ->
    {
    delivery_date: @pageStructure.getDeliveryDate()
    delivery_shift: @pageStructure.getDeliveryShift()
    }

  updateLoadRequest: ->
    {
    delivery_date: @pageStructure.getDeliveryDate()
    delivery_shift: @pageStructure.getDeliveryShift()
    truck_id: @pageStructure.getTruckId()
    }

  submitReturnOrdersRequest: (table)->
    {
    delivery_date: @pageStructure.getDeliveryDate()
    delivery_shift: @pageStructure.getDeliveryShift()
    orders: table.getCheckedOrderIds()
    truck_id: @pageStructure.getTruckId()
    }

  splitOrderRequest: (orderId, newQuantity, newVolume) ->
    {order_id: orderId, new_quantity: newQuantity, new_volume: newVolume}

  reorderOrdersRequest: (orderId, oldPos, newPos)->
    {order_id: orderId, old_position: oldPos, new_position: newPos}



$(document).on "page:change", ->
  if (top.location.pathname == '/load_planning')
    $('#delivery_date_input').datepicker()

    loadController = new LoadController()

    pageBuilder = new PageStructureBuilder(loadController)

    pageBuilder.addDeliveryShiftSelect('load_delivery_shift').
    addTruckVolumeLabel('truck_volume').
    addDeliveryDateInput('delivery_date_input').
    addTruckSelect('load_truck').
    addAvailableOrdersTable('available_orders').
    addPlanningOrdersTable('planning_orders').
    addSubmitOrdersButton('submit_orders_button').
    addReturnOrdersButton('return_orders_button').
    addCompleteLoadButton('complete_load_button').
    addLoadStatusLabel('load_status_value').
    addSplitOrderDialog('split_order_dialog').
    addSplitAvOrderButton('split_av_order_button').
    addSplitPlanOrderButton('split_plan_order_button').
    addReopenLoadButton('reopen_load_button')


