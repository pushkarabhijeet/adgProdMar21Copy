/**********************************************************************
* Name:     SG_VFC_RetailLead
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
* 1.0       30-Jan-2020     rwd           Initial Development           
*   
***********************************************************************/


public with sharing class SG_VFC_RetailLead {

// ************************           PUBLIC VARIABLES          **************************
	public Lead theLead { get; set; }

	public String householdRTName {get; set;}
	public Id householdRtId {get; set;}
	public Boolean isSaved {get; set;}

// ************************           PRIVATE VARIABLES       **************************
	private ApexPages.StandardController controller;


// ************************           CONSTRUCTOR                                 **************************           
	public SG_VFC_RetailLead(ApexPages.StandardController controller)
	{
		System.debug('---> starting SG_VFC_RetailLead constructor');
		this.controller = controller;
		theLead = (Lead) controller.getRecord();
		init();
	}

	public void init()
	{
		System.debug(LoggingLevel.WARN, '---> start init');
		theLead = new Lead();
		householdRTName = Label.Household_RTName;
		if ( isSaved == null ) isSaved = false;
		try
		{
			householdRtId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(householdRTName).getRecordTypeId();
		}
		catch ( Exception e )
		{
			System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );
		}

	}

	public PageReference customSave()
	{
		System.debug(LoggingLevel.WARN, '---> start customSave');
		// todo: match existing account??

		try
		{
			//Account a = new Account();
			//a.Name = theLead.FirstName + theLead.LastName;
			//if ( householdRtId != null )
			//{
			//	a.RecordTypeId = householdRtId;
			//}
			//insert a;

			theLead.Company = theLead.LastName + ', ' + theLead.FirstName;
			theLead.RecordTypeId = householdRtId;
			insert theLead;
			isSaved = true;
			init();


		}
		catch (Exception e )
		{
			System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );
			SG_DisplayUtils.addError('There was a problem submitting your form. For reference, the error was: ' + e.getMessage() );
			isSaved = false;
		}


		return null;
	}

	public PageReference startOver()
	{
		isSaved = false;
		return null;
	}
	
}