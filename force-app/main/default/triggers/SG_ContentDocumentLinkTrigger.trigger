/**********************************************************************
* Name:     SG_ContentDocumentLinkTrigger
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
* 1.0       28-May-2020     rwd           Initial Development           
*   
***********************************************************************/


trigger SG_ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {

    if ( SG_ApexActivator.isDisabled('Disable_ContentDocumentLink_Triggers__c') || SG_ContentDocumentHelper_Test.isTest )
	{
		System.debug('---> SG_ContentDocumentLinkTrigger; this trigger has been disabled via Custom Setting');
		return;
	}

	
	SG_ContentDocumentHelper.addFileToAsset( Trigger.operationType, Trigger.new, Trigger.oldMap );
	SG_ContentDocumentHelper.setFileNamesFromCDLUpload( Trigger.operationType, Trigger.new, Trigger.oldMap );
}