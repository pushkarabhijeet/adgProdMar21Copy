trigger SG_Account_LU on Account (after insert, after update, after delete, after undelete) {


    if ( SG_ApexActivator.isDisabled('Disable_Account_Triggers__c'))
    {
                System.debug('---> SG_Account_LU; this trigger has been disabled via Custom Setting');
                return;
    }


    //Pass in the API name of the child object, for example 'Account' and the API name of the parent object, for example 'Account';
    SG_LookupRollupHelper lh = new SG_LookupRollupHelper( 'Account', 'Account');

    // take care of assigning the correct lists based on the trigger type (Insert vs Update vs Delete vs Undelete)
    lh.setTriggerLists(Trigger.isUpdate, Trigger.isDelete, Trigger.new, Trigger.old);

    // do the rollup(s) -- will execute all active rollups for current child/parent configuration
    lh.doRollupSummary();


}