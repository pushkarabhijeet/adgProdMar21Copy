/**********************************************************************
* Name:     SG_ServiceResourceHelper
* Author:   Strategic Growth, Inc. (www.strategicgrowthinc.com)
*  
* ======================================================
* ======================================================
* Purpose:  Populate Service User field
* 
* ======================================================
* ======================================================
* History:                                                            
* VERSION   DATE            INITIALS      DESCRIPTION/FEATURES ADDED
* 1.0       23-Mar-2020     rwd           Initial Development           
*   
***********************************************************************/


public class SG_ServiceResourceHelper {
	public static Boolean hasRun = false;
	public static Boolean isTest = false;


	// the "User" field (really RelatedRecordId) is not visible to Workflow/Process Builder. Populate a custom field with the relatedRecordId so we can use it
    public static void setUserId(System.TriggerOperation triggerEvent, List<ServiceResource> newResources, Map<Id, ServiceResource> oldResources)
	{
		System.debug(LoggingLevel.WARN, '---> start setUserId');

		// set the enum of allowed trigger operations (before insert, after update, etc)
		List<TriggerOperation> triggerTypes = new List<TriggerOperation>{
				TriggerOperation.BEFORE_INSERT
				, TriggerOperation.BEFORE_UPDATE
		};
		if ( !canFireTrigger( triggerEvent, triggerTypes, hasRun ) )
		{
			System.debug(LoggingLevel.WARN, '---> already hasRun: ' + hasRun + ' or wrong trigger type; skip');
			return;
		}

		// prevents recursive triggers
		hasRun = true;
		if ( newResources != null && newResources.size() > 0 )
		{
			// set the custom field with the User (relatedRecordId)
			for ( ServiceResource res : newResources )
			{
				res.Service_Resource_User_ID__c = res.RelatedRecordId;
			}
		}
	}
	
	public static Boolean canFireTrigger(TriggerOperation type, List<TriggerOperation> allowedTypes, Boolean isRecursive )
	{
		Boolean canFire = false;
		if ( !isRecursive && type != null && allowedTypes != null && allowedTypes.contains(type))
		{
			System.debug(LoggingLevel.WARN, '---> allowed type...');
			canFire = true;
		}

		return canFire;
	}


}