/**********************************************************************
* Name:     SG_CaseHelper
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


public class SG_CaseHelper {

	public static Boolean hasDoneCaseRollups = false;

	// perform rollups...
	public static void doCaseRollups(System.TriggerOperation triggerEvent, List<Case> newCases, Map<Id, Case> oldCases)
	{
		System.debug(LoggingLevel.WARN, '---> start doCaseRollups');
		// set the enum of allowed trigger operations (before insert, after update, etc)
		List<TriggerOperation> triggerTypes = new List<TriggerOperation>{
				TriggerOperation.AFTER_INSERT
				, TriggerOperation.AFTER_UPDATE
				, TriggerOperation.AFTER_DELETE
				, triggerOperation.AFTER_UNDELETE
		};
		if (!SG_DisplayUtils.canFireTrigger(triggerEvent, triggerTypes, hasDoneCaseRollups)) {
			System.debug(LoggingLevel.WARN, '---> already hasDoneCaseRollups: ' + hasDoneCaseRollups + ' or wrong trigger type; skip');
			return;
		}

		// prevents recursive triggers...
		hasDoneCaseRollups = true;
		//Pass in the API name of the child object, for example 'Case' and the API name of the parent object, for example 'Asset';
		SG_LookupRollupHelper lh = new SG_LookupRollupHelper( 'Case', 'Asset');

		// take care of assigning the correct lists based on the trigger type (Insert vs Update vs Delete vs Undelete)
		List<Case> oldList;
		if ( oldCases != null ) oldList = oldCases.values();

		// take care of assigning the correct lists based on the trigger type (Insert vs Update vs Delete vs Undelete)
		lh.setTriggerLists(Trigger.isUpdate, Trigger.isDelete, newCases, oldList);

		// do the rollup(s) -- will execute all active rollups for current child/parent configuration
		lh.doRollupSummary();
	}

}