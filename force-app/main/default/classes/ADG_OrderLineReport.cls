public class ADG_OrderLineReport {
  @AuraEnabled
  public static ResponseWrapper loadWorkOrderLineItems(String workOrderId) {
    ResponseWrapper responseWrapper = new ResponseWrapper();
    try {
      WorkOrder workOrder = [
        SELECT
          Id,
          WorkOrderNumber,
          ERP_Order_Number__c,
          Account.Name,
          Job_Type__c,
          AccountId,
          PO_Number__c,
          Installer_Account__r.Name
        FROM WorkOrder
        WHERE Id = :workOrderId
      ];

      List<WorkOrderLineItem> lineItems = [
        SELECT
          Id,
          WorkOrderId,
          Color_Description__c,
          Style_Item__c,
          Line_Status__c,
          Quantity__c,
          Quantity,
          UnitOfMeasure__c,
          LineNumber__c,
          Notes__c,
          (
            SELECT
              id,
              Work_Order_Line_Item__c,
              Area_Quantity__c,
              Area_Name__c,
              Area_Note__c
            FROM Areas__r
          )
        FROM WorkOrderLineItem
        WHERE WorkOrderId = :workOrderId
        ORDER BY LineNumber__c
      ];
      responseWrapper.workOrderDetails = workOrder;
      list<LineItemsWrapper> listLineItems = new List<LineItemsWrapper>();
      for (WorkOrderLineItem wo : lineItems) {
        LineItemsWrapper rew = new LineItemsWrapper();
        if (String.isNotBlank(wo.Notes__c)) {
          rew.hasNotes = true;
        }
        rew.lineItemsListRecord = wo;
        for (Area__c area : wo.Areas__r) {
          if (String.isNotBlank(area.Area_Note__c)) {
            rew.hasNotes = true;
          }
        }
        listLineItems.add(rew);
      }
      responseWrapper.lineItemsList = listLineItems;
    } catch (exception e) {
      system.debug(
        'Exception occured : ' +
        e.getMessage() +
        ' : Line number : ' +
        e.getlineNumber()
      );
    }

    return responseWrapper;
  }
  public class ResponseWrapper {
    @AuraEnabled
    public WorkOrder workOrderDetails;
    @AuraEnabled
    public List<LineItemsWrapper> lineItemsList;
  }

  public class LineItemsWrapper {
    @AuraEnabled
    public WorkOrderLineItem lineItemsListRecord;
    @AuraEnabled
    public boolean expanded = false;
    @AuraEnabled
    public boolean hasNotes = false;
  }
}