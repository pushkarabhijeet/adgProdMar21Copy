/***************************************************
* Name:         SG_WorkOrderTrigger
* Author:       Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date:         26 May 2020
* ==================================================
* ==================================================
* Purpose:      ...
*
* ==================================================
* ==================================================
* History:
* VERSION   DATE            INITIALS    DESCRIPTION/FEATURES ADDED
* 1.0       26 May 2020     FMF     Initial Development
* 
****************************************************/

trigger SG_WorkOrderTrigger on WorkOrder ( before insert, before update, before delete
                            , after insert, after update )
{
    if(SG_ApexActivator.isDisabled('Disable WorkOrder Triggers'))
	{
		System.debug('SG_WorkOrderTrigger disabled by Apex Activation Settings Custom Setting.');
		return;
	}
    
    // Before
    if (Trigger.isBefore && Trigger.isDelete){
    	SG_WorkOrderHelper.deleteRelatedQualityControl( Trigger.operationType, Trigger.oldMap );    
    }
	//Added to delete QC on Job Change
   	if (Trigger.isBefore && Trigger.isUpdate){
        SG_WorkOrderHelper.deleteQCOnJobTypeChange(Trigger.new, Trigger.oldMap);
    }
    SG_WorkOrderHelper.populateWorkOrder( Trigger.operationType, Trigger.new, Trigger.oldMap );
    if (Trigger.isBefore && Trigger.isUpdate){
        SG_WorkOrderHelper.syncFieldServiceManagerChanges( Trigger.operationType, Trigger.new, Trigger.oldMap );
    }
	SG_WorkOrderHelper.calculateJobQCDates( Trigger.operationType, Trigger.new, Trigger.oldMap );

	// After
	//Added to delete QC on Job Change
   /*if (Trigger.isAfter && Trigger.isUpdate){
        SG_WorkOrderHelper.deleteQCOnJobTypeChange(Trigger.new, Trigger.oldMap);
    }*/
    //End delete QC on Job Change
    SG_WorkOrderHelper.createQualityControl( Trigger.operationType, Trigger.new, Trigger.oldMap );
    SG_WorkOrderHelper.upsertAppointments( Trigger.operationType, Trigger.new, Trigger.oldMap );
	SG_WorkOrderHelper.checkBlankStartDate( Trigger.operationType, Trigger.new, Trigger.oldMap );
}