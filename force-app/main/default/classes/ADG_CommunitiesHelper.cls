/***********************************************************************************
 * Name:     	ADG_CommunitiesHelper
 * Author:   	Pushkar
 * Test Class:	ADG_CommunitiesHelper_Test
 * ======================================================
 * History:
 * VER   DATE          INITIALS      DESCRIPTION/FEATURES ADDED
 * 1.0   Dec-29-2020   pushkar       Initial Development to be invoked from Trigger
 *
 ***********************************************************************************/

public with sharing class ADG_CommunitiesHelper {
  public static void invokeAfterUpdate(
    System.TriggerOperation operationType,
    List<Community__c> updList,
    Map<Id, Community__c> oldMap
  ) {
    if (operationType != TriggerOperation.AFTER_UPDATE) {
      //validate that this is only being executed from After Update trigger.
      return;
    }

    Set<Id> updFSMList = new Set<Id>();
    for (Community__c c : updList) {
      //Loop records to create List if FSM Changed
      if (
        c.Field_Service_Manager__c != oldMap.get(c.Id).Field_Service_Manager__c
      ) {
        updFSMList.add(c.Id);
      }
    }

    if (updFSMList.size() > 0) {
      List<Asset> assetIds = [
        SELECT
          ID,
          Community__r.Field_Service_Manager__c,
          Field_Service_Manager__c
        FROM ASSET
        WHERE
          Community__r.ID IN :updFSMList];
      if (assetIds.size() > 0) {
        List<Asset> assetUpdate = new List<Asset>();
        for (Asset a : assetIds) {
          a.Field_Service_Manager__c = a.Community__r.Field_Service_Manager__c;
          assetUpdate.add(a);
        }
        //update assetUpdate;
        try {
          Database.SaveResult[] res = Database.update(assetUpdate, false);
        } catch (Exception e) {
          system.debug('@@@Exception Type: ' + e.getTypeName());
          system.debug('@@@Exception Line: ' + e.getLineNumber());
          system.debug('@@@Exception Msg: ' + e.getMessage());
        }
      }
    }
  }
}