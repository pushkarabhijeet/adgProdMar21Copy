/**********************************************************************
 * Name:     ADG_OrderLineReport_Test
 * Author:
 *
 * ======================================================
 * ======================================================
 * Purpose:
 *
 * ======================================================
 * ======================================================
 * History:
 * VERSION   DATE            INITIALS      DESCRIPTION/FEATURES ADDED
 * 1.0       10-Dec-2020                   Initial Development
 *
 ***********************************************************************/
@isTest
public class ADG_OrderLineReport_Test {
  @TestSetUP
  public static void setupData() {
    ADG_TestSetup.Setup(); //SetUp Accounts and Workorders
  }

  static testMethod void loadWorkOrderLineItems_test() {
    List<WorkOrder> woList = [SELECT Id FROM WorkOrder LIMIT 1];
    Test.startTest();
    ADG_OrderLineReport.loadWorkOrderLineItems(woList[0].Id);
    Test.stopTest();
  }

  static testMethod void ResponseWrapper_test() {
    Test.startTest();
    ADG_OrderLineReport.ResponseWrapper obj = new ADG_OrderLineReport.ResponseWrapper();
    ADG_OrderLineReport.LineItemsWrapper lineWrapper = new ADG_OrderLineReport.LineItemsWrapper();
    lineWrapper.expanded = true;
    lineWrapper.hasNotes = true;
    lineWrapper.lineItemsListRecord = null;
    Test.stopTest();
  }
}