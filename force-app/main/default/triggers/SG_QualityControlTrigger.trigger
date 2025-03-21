/***************************************************
* Name:         SG_QualityControlTrigger
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
* 1.1       01 Jun 2020     RD      Added setFileNames
* 
****************************************************/

trigger SG_QualityControlTrigger on Quality_Control__c ( before insert, before update, after insert, after update, after delete, after undelete ) {


    if ( SG_ApexActivator.isDisabled('Disable_Quality_Control_Triggers__c')  || SG_QualityControlHelper_Test.isTest)
    {
        System.debug('---> SG_Quality_Control_LU; this trigger has been disabled via Custom Setting');
        return;
    }

    SG_QualityControlHelper.setFileNames( Trigger.operationType, Trigger.new, Trigger.oldMap );


    //if( SG_QualityControlHelper.isNotBeforeInsertUpdate( Trigger.operationType ) ) {
    //    return;
    //}

    // TODO:  consider whether createCase() should be after assignCase()

    System.debug(LoggingLevel.WARN, '---> start qc trigger');


    SG_QualityControlHelper.populatePicklists( Trigger.operationType, Trigger.new, Trigger.oldMap );
    SG_QualityControlHelper.createCase( Trigger.operationType, Trigger.new, Trigger.oldMap );
    SG_QualityControlHelper.assignCase( Trigger.operationType, Trigger.new, Trigger.oldMap );
    SG_QualityControlHelper.updateWorkOrder( Trigger.operationType, Trigger.new, Trigger.oldMap );

    //SG_QualityControlHelper.doQCRollups( Trigger.operationType, Trigger.new, Trigger.oldMap );

}