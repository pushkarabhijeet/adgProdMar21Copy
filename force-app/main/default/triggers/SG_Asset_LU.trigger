trigger SG_Asset_LU on Asset (before insert, before update ) {
    // NOTE:  changed above to before ins/upd

    if ( SG_ApexActivator.isDisabled('Disable_Asset_Triggers__c') || SG_Asset_LU_Test.isTest)
    {
                System.debug('---> SG_Asset_LU; this trigger has been disabled via Custom Setting');
                return;
    }

    SG_AssetHelper.propagateAssetChanges( Trigger.operationType, Trigger.new, Trigger.oldMap );


    // NOTE:  this has been moved to the ADG_HandleJobPath trigger
    // SG_AssetHelper.doAssetRollups( Trigger.operationType, Trigger.new, Trigger.oldMap );

}