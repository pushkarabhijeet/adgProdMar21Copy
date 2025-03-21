trigger ADG_HandleJobPath on Asset (after insert, after update, after delete, after undelete) {

    if ( SG_ApexActivator.isDisabled('Disable_Asset_Triggers__c') || SG_Asset_LU_Test.isTest)
    {
        System.debug('---> SG_Asset_LU; this trigger has been disabled via Custom Setting');
        return;
    }

    ADG_JobPathUtils.createJobPaths(Trigger.operationType, Trigger.newMap, Trigger.oldMap);
    SG_AssetHelper.doAssetRollups( Trigger.operationType, Trigger.new, Trigger.oldMap );
}