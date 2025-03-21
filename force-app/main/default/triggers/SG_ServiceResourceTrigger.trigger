/**********************************************************************
* Name:     SG_ServiceResourceTrigger
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
* 1.0       23-Mar-2020     rwd           Initial Development           
*   
***********************************************************************/


trigger SG_ServiceResourceTrigger on ServiceResource (before insert, before update) {

    if ( SG_ApexActivator.isDisabled('Disable_ServiceResource_Triggers__c') || SG_ServiceResourceHelper.isTest )
	{
		System.debug('---> SG_ServiceResourceTrigger; this trigger has been disabled via Custom Setting');
		return;
	}
	
	SG_ServiceResourceHelper.setUserId( Trigger.operationType, Trigger.new, Trigger.oldMap );

}