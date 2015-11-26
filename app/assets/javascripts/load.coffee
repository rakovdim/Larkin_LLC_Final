# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class PageStructureBuilder
  constructor: (@loadController) ->
    @pageStructure = new PageStructure()
    @loadController.setPageStructure(@pageStructure)

  addSplitAvOrderButton: (buttonId) ->
    @pageStructure.setSplitAvOrderButtonId(buttonId)
    table = @pageStructure.availableOrdersTable
    this.addSplitOrderButton(buttonId, table)
    this

  addSplitPlanOrderButton: (buttonId) ->
    @pageStructure.setSplitPlanOrderButtonId(buttonId)
    table = @pageStructure.planningOrdersTable
    this.addSplitOrderButton(buttonId, table)
    this

  addSplitOrderButton: (buttonId, table) ->
    $('#' + buttonId).click =>
      @loadController.openSplitOrderDialog(table)

  addLoadStatusLabel: (loadStatusLabelId) ->
    @pageStructure.setLoadStatusLabelId(loadStatusLabelId)
    this

  addSubmitOrdersListener: (buttonId)->
    @pageStructure.setSubmitButtonId(buttonId)
    $('#' + buttonId).click =>
      @loadController.submitOrders()
    this

  addCompleteLoadListener: (buttonId)->
    @pageStructure.setCompleteLoadButtonId(buttonId)
    $('#' + buttonId).click =>
      @loadController.completeLoad()
    this

  addReturnOrdersListener: (buttonId)->
    @pageStructure.setReturnButtonId(buttonId)
    $('#' + buttonId).click =>
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

  addTruckInput: (truckInputId)->
    @pageStructure.setTruckSelect($('#' + truckInputId))
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
      planOrdersTable = this.constructEntireTable(tableId, '/get_planning_orders', 'plan_orders_checkbox', false, true)
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

#todo it is performed after ajax request has been sent. it is incorrect
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
        {data: "destination_raw_line_1"}
        {data: "origin_raw_line_1"}]
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
          console.log (orderData)
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
    if (!this.isFloat(this.getNewVolume()) && !this.isInt(this.getNewVolume()))
      this.setTips("Volume should be float")
      valid = false
    valid

  isQuantityValid: (currentQuantity) ->
    valid = this.isDataValid("quantity", this.getNewQuantity(), currentQuantity)
    if (!this.isInt(this.getNewQuantity()))
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
    console.log (n)
    console.log (Number(n) == n && n % 1 == 0)
    Number(n) == n && n % 1 == 0;

  isFloat: (n)->
    n == Number(n) && n % 1 != 0;


class PageStructure
  constructor: ->
  setPlanningOrdersTable: (@planningOrdersTable)->
  setAvailableOrdersTable: (@availableOrdersTable)->
  setDeliveryShiftSelectId: (@deliveryShiftSelectId)->
  setDeliveryDateInputId: (@deliveryDateInputId)->
  setTruckSelect: (@truckSelect)->
  setTruckVolumeLabelId: (@truckLoadVolumeId)->
  setLoadStatusLabelId: (@loadStatusLabelId)->
  setSubmitButtonId: (@submitButtonId)->
  setReturnButtonId: (@returnButtonId)->
  setCompleteLoadButtonId: (@completeLoadButtonId)->
  setSplitAvOrderButtonId: (@splitAvOrderButtonId)->
  setSplitPlanOrderButtonId: (@splitPlanOrderButtonId)->
  setSplitOrderDialog: (@splitOrderDialog)->

  isAlreadyInit: ->
    this.isTableInit(@planningOrdersTable)
    this.isTableInit(@availableOrdersTable)

  isTableInit: (table) ->
    table != undefined && table.isInit()

  getDeliveryShift: ->
    $('#' + @deliveryShiftSelectId).val()

  getDeliveryDate: ->
    $('#' + @deliveryDateInputId).val()

  getTruck: ->
    @truckSelect.val()

  setTruck: (truckId) ->
    @truckSelect.val(truckId)

  setTruckVolume: (volume) ->
    $('#' + @truckLoadVolumeId).text(Number((volume).toFixed(1)))

  setLoadStatus: (loadStatus) ->
    $('#' + @loadStatusLabelId).text(loadStatus);
    if (loadStatus != 'Not planned')
      this.setPageDisabled(true)
    else
      this.setPageDisabled(false)

  setPageDisabled: (disabled)->
    console.log(@splitPlanOrderButtonId)
    @truckSelect.prop('disabled', disabled)
    $('#' + @submitButtonId).prop('disabled', disabled)
    $('#' + @returnButtonId).prop('disabled', disabled)
    $('#' + @completeLoadButtonId).prop('disabled', disabled)
    $('#' + @splitPlanOrderButtonId).prop('disabled', disabled)

  updatePageData: (pageData)->
    if (pageData != null && pageData != undefined)
      if (pageData.truck_volume != null)
        this.setTruckVolume(pageData.truck_volume)
      if (pageData.load_status != null)
        this.setLoadStatus (pageData.load_status)
      if (pageData.truck != null && pageData.truck != undefined )
        this.setTruck(pageData.truck)

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

  updatePageDataSync: (data)->
    @pageStructure.updatePageData(data)

  reorderPlanningOrders: (orderId, oldPos, newPos) ->
    this.executeAjaxRequest('/reorder_planning_orders', this.reorderOrdersRequest(orderId, oldPos, newPos))

  openSplitOrderDialog: (table) ->
    ordersData = table.getCheckedOrdersData()
    console.log (ordersData)
    if (ordersData.length != 1)
      alert 'Please select one order to split'
    else
      orderData = ordersData[0]
      if (orderData.handling_unit_quantity == 1 || orderData.volume == 0)
        alert "Handling unit quantity is 1 or volume is 0 for this order. You can't split it"
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

  completeLoad: ->
    if (@pageStructure.planningOrdersTable.getOrdersCount() > 0)
      this.executeAjaxRequest('/complete_load', this.completeLoadRequest(), 'Load has been successfully planned for delivery')
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
        alert this.internalErrorMessage
    })

  processOrdersUpdate: (data, successMessage) ->
    if (data.status == 'success')
      this.onUpdateSuccess(data, successMessage)
    else
      this.onUpdateFail(data)

  onUpdateSuccess: (data, successMessage) ->
    if (successMessage != undefined )
      alert successMessage
    @pageStructure.reloadTables(true)

  onUpdateFail: (data) ->
    alert('Exception occurs: ' + data.message)

  onUpdateWarning: (data) ->
    alert('Warning: ' + data.message)
    @pageStructure.reloadTables(true)


  internalErrorMessage: ->
    'Internal error occurs. Please contact to your administrator'

  completeLoadRequest: ->
    {
    delivery_date: @pageStructure.getDeliveryDate()
    delivery_shift: @pageStructure.getDeliveryShift()
    }

  submitReturnOrdersRequest: (table)->
    {
    delivery_date: @pageStructure.getDeliveryDate()
    delivery_shift: @pageStructure.getDeliveryShift()
    orders: table.getCheckedOrderIds()
    truck: @pageStructure.getTruck()
    }

  splitOrderRequest: (orderId, newQuantity, newVolume) ->
    {orderId: orderId, new_quantity: newQuantity, new_volume: newVolume}

  reorderOrdersRequest: (orderId, oldPos, newPos)->
    {orderId: orderId, old_position: oldPos, new_position: newPos}



$(document).on "page:change", ->
  $('#delivery_date_input').datepicker()

  loadController = new LoadController()

  pageBuilder = new PageStructureBuilder(loadController)

  pageBuilder.addDeliveryShiftSelect('load_delivery_shift').
  addTruckVolumeLabel('truck_volume').
  addDeliveryDateInput('delivery_date_input').
  addTruckInput('load_truck').
  addAvailableOrdersTable('available_orders').
  addPlanningOrdersTable('planning_orders').
  addSubmitOrdersListener('submit_orders_button').
  addReturnOrdersListener('return_orders_button').
  addCompleteLoadListener('complete_load_button').
  addLoadStatusLabel('load_status_value').
  addSplitOrderDialog('split_order_dialog').
  addSplitAvOrderButton('split_av_order_button').
  addSplitPlanOrderButton('split_plan_order_button')


