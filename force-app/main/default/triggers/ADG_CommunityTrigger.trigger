/**************************************************************
 * Name:         ADG_CommunityTrigger
 * Author:       Pushkar
 * ==================================================
 * History:
 * VERS   DATE         INITIALS    DESCRIPTION/FEATURES ADDED
 * 1.0    Dec 29 2020  pushkar     Initial Development
 **************************************************************/
trigger ADG_CommunityTrigger on Community__c(after update) {
  if (
    SG_ApexActivator.isDisabled('Disable_Community_Triggers__c') ||
    ADG_CommunitiesHelper_Test.isTest
  ) {
    System.debug('---> this trigger has been disabled via Custom Setting');
    return;
  }
  ADG_CommunitiesHelper.invokeAfterUpdate(
    Trigger.operationType,
    Trigger.new,
    Trigger.oldMap
  );
}