/**********************************************************************
* Name:     SG_ProjectLocation_Test
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


@IsTest
private class SG_ProjectLocation_Test {

	private static SG_TestDataGenerator td;
	private static List<Account> accounts;
	private static List<Opportunity> opps;
	private static List<Project_Location_GEO__c> geos;


	@testSetup static void setupTestData()
	{
		td = new SG_TestDataGenerator();
		accounts = td.getAccounts(true);
		opps = td.getOpportunities(true);
		geos = td.getGeos(true);

	}

	static testMethod void testBehavior()
	{
		refreshData();

		// set the opp...
		Opportunity o = opps[0];
		System.assertEquals( o.Project_Location_City__c, null);

		SG_OpportunityHelper.hasDoneZip = false;
		o.Project_Location_Zip__c = geos[0].Id;
		o.Entity__c = 'Arlun';
		update o;

		refreshData();

		o = opps[0];
		System.debug(LoggingLevel.WARN, '---> in test; o: ' + o );
		System.debug(LoggingLevel.WARN, '---> opp city: ' + o.Project_Location_City__c );
		System.debug(LoggingLevel.WARN, '---> geos city: ' + geos[0].City__c );
		System.assertEquals( o.Project_Location_City__c, geos[0].City__c);

		// now test the page...
		PageReference theScreen = Page.SG_ProjectLocation;
		Test.setCurrentPage( theScreen );
		System.currentPageReference().getParameters().put('id', o.Id);

		ApexPages.StandardController con = new ApexPages.Standardcontroller( o );
		SG_VFC_ProjectLocation controller = new SG_VFC_ProjectLocation( con );

		// blank out the entity and re-run
		System.debug(LoggingLevel.WARN, '---> blank out entity and retest');
		o.Entity__c = null;
		update o;
		refreshData();
		o = opps[0];
		ApexPages.StandardController con2 = new ApexPages.Standardcontroller( o );
		SG_VFC_ProjectLocation controller2 = new SG_VFC_ProjectLocation( con2 );
		controller2.doQuery();

		// finally - blank out the opp location
		o.Project_Location_Zip__c = null;
		SG_OpportunityHelper.hasDoneZip = false;
		update o;
		refreshData();

		o = opps[0];
		System.assertEquals( o.Project_Location_City__c, null);

		// verify trigger shut off...
		SG_OpportunityHelper.isTest = true;
		SG_OpportunityHelper.hasDoneZip = false;
		o.Project_Location_Zip__c = geos[0].Id;
		update o;
		refreshData();

		o = opps[0];
		System.assertEquals( o.Project_Location_City__c, null);
	}

	public static void refreshData() {

		accounts = [SELECT Id, Name FROM Account];
		opps = [SELECT Id, Name, Project_Location_GEO__latitude__s,Project_Location_GEO__longitude__s, Project_Location_Zip__c, Project_Location_City__c, IsClosed, IsWon, Project_Location_State__c FROM Opportunity];
		geos = [SELECT Id, Name, City__c, County_Name__c, Lat__c, Long__c, State_Abbr__c, State_Name__c, Time_Zone__c FROM Project_Location_GEO__c];
	}


}