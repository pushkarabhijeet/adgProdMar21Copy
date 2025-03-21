/**********************************************************************
* Name:     SG_CaseTrigger
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
* 1.0       25-Jun-2020     rwd           Initial Development           
*   
***********************************************************************/


trigger SG_CaseTrigger on Case (after insert, after update, after delete, after undelete) {

    if ( SG_ApexActivator.isDisabled('Disable_Case_Triggers__c') || SG_Case_LU_Test.isTest)
	{
		System.debug('---> SG_CaseTrigger; this trigger has been disabled via Custom Setting'); 
		return;
	}

	SG_CaseHelper.doCaseRollups( Trigger.operationType, Trigger.new, Trigger.oldMap );

    if(Trigger.isAfter && Trigger.isInsert && System.isFuture() == false)
    {
        Set<Id> caseIdsToAssign = new Set<Id>();
        for(Case c : Trigger.new)
        {
            if(c.Fire_Assignment_Rule__c == true)
            {
                caseIdsToAssign.add(c.Id);
            }
        }
        SG_CaseAssignmentRuleActivation.applyAssignmentRules_ATFUTURE(caseIdsToAssign);
    }
    
}