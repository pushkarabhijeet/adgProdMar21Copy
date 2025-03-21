/**********************************************************************
* Name:     SG_OpportunityTrigger
* Author:   Strategic Growth, Inc. (www.strategicgrowthinc.com)
*  
* ======================================================
* ======================================================
* Purpose:                                                      
* 
* ======================================================
* ======================================================
* History:                                                            
* VERSION   DATE            INITIALS      DESCRIPTION/FEATURES ADDED
* 1.0       23-Oct-2019     rwd           Initial Development           
*   
***********************************************************************/


trigger SG_OpportunityTrigger on Opportunity (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isUpdate) {
            OpportunityTriggerHandler.validateStagesBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        } else if (Trigger.isInsert) {
            
        } else {
            
        }
    } else {
        
    }
    
    if ( SG_ApexActivator.isDisabled('Disable_Opportunity_Triggers__c') || SG_OpportunityHelper.isTest )
    {
        System.debug('---> SG_OpportunityTrigger; this trigger has been disabled via Custom Setting');
        return;
    }
    
    // set up a Zip Code-based geo location
    SG_OpportunityHelper.doZipLocation( Trigger.operationType, Trigger.new, Trigger.oldMap );
    
    // re-establish prod schedules
    List<TriggerOperation> establishOperations = new List<TriggerOperation>{TriggerOperation.AFTER_INSERT, TriggerOperation.AFTER_UPDATE};
        SG_OpportunityHelper.doReestablishSchedules( Trigger.operationType, Trigger.new, Trigger.oldMap, establishOperations);
}