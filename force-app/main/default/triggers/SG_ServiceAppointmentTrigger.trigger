/***************************************************
* Name:         SG_ServiceAppointmentTrigger
* Author:       Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date:         27 May 2020
* ==================================================
* ==================================================
* Purpose:      ...
*
* ==================================================
* ==================================================
* History:
* VERSION   DATE            INITIALS    DESCRIPTION/FEATURES ADDED
* 1.0       27 May 2020     FMF     Initial Development
* 
****************************************************/

trigger SG_ServiceAppointmentTrigger on ServiceAppointment ( after insert, after update ) 
{
    
    if(SG_ApexActivator.isDisabled('Disable Service Appointment Triggers'))
	{
		System.debug('SG_ServiceAppointmentTrigger disabled by Apex Activation Settings Custom Setting.');
		return;
	}
    
    // NOTE:  we have to create resource after syncing work order because otherwise, the resource creation
    // would interfere causing recursion on sync work order
    SG_ServiceAppointment.syncWorkOrder( Trigger.operationType, Trigger.new, Trigger.oldMap );
    SG_ServiceAppointment.createResource( Trigger.operationType, Trigger.new, Trigger.oldMap );
}