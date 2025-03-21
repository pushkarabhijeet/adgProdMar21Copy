/**********************************************************************
* Name:     SG_VFC_LRHSetup_Test
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
* 1.0       12-Sep-2018     rwd           Initial Development           
*   
***********************************************************************/


@IsTest
private class SG_VFC_LRHSetup_Test
{

	private static SG_TDG_LookupRollupSummary td;
	private static List<Account> accounts;
	private static List<Contact> contacts;
	private static List<RollupConfigs__c> rollupConfigs;


	@testSetup static void setupTestData()
	{
		td = new SG_TDG_LookupRollupSummary();
		td.accountNum = 1;
		accounts = td.getAccounts(true);
		contacts = td.getContacts(true);


	}

	static testMethod void testCreate()
	{
		td = new SG_TDG_LookupRollupSummary();
		refreshData();


		RollupConfigs__c config = new RollupConfigs__c();
		PageReference theScreen = Page.SG_LRHSetup;
    	Test.setCurrentPage(theScreen);
    	//System.currentPageReference().getParameters().put('acctId', a.Id);
    	
    	ApexPages.StandardController con = new ApexPages.Standardcontroller( config );
    	SG_VFC_LRHSetup controller = new SG_VFC_LRHSetup( con );

		// create a new mapping
		controller.doShowCreateSection();
		controller.childObject = 'Contact';
		controller.parentObject = 'Account';
		controller.setObjects();

		System.assertNotEquals(null, controller.theConfig );
		System.assertNotEquals( null, controller.theConfig.Name );

		controller.doShowTriggerReload();

		// configure the mapping
		controller.theConfig.queryField_parentRelationshipName__c = 'AccountId';
		controller.theConfig.parentRowCount__c = 'NumberOfEmployees';

		controller.saveConfig();

		refreshData();
		System.assertEquals( rollupConfigs[0].Parent_Object__c, 'Account' );
		System.assertEquals( rollupConfigs[0].Child_Object_Name__c, 'Contact' );

		List<Contact> newContacts = new List<Contact>();
		for ( Contact c : contacts )
		{
			c.FirstName = 'Test';
			newContacts.add( c );
		}
		upsert newContacts;

		// fire the rollup...
		//Pass in the API name of the child object, for example 'Contact' and the API name of the parent object, for example 'Account';
		SG_LookupRollupHelper lh = new SG_LookupRollupHelper( 'Contact', 'Account');

		// take care of assigning the correct lists based on the trigger type (Insert vs Update vs Delete vs Undelete)
		lh.setTriggerLists(true, false, newContacts, contacts);

		// do the rollup(s) -- will execute all active rollups for current child/parent configuration
		lh.doRollupSummary();


	}

	static testMethod void testEdit()
	{
		td = new SG_TDG_LookupRollupSummary();
		refreshData();

		RollupConfigs__c config = new RollupConfigs__c();
		PageReference theScreen = Page.SG_LRHSetup;
		Test.setCurrentPage(theScreen);
		//System.currentPageReference().getParameters().put('acctId', a.Id);

		ApexPages.StandardController con = new ApexPages.Standardcontroller( config );
		SG_VFC_LRHSetup controller = new SG_VFC_LRHSetup( con );

		// create a new mapping
		controller.doShowCreateSection();
		controller.childObject = 'Contact';
		controller.parentObject = 'Account';
		controller.setObjects();

		System.assertNotEquals(null, controller.theConfig );
		System.assertNotEquals( null, controller.theConfig.Name );

		// configure the mapping
		controller.theConfig.queryField_parentRelationshipName__c = 'AccountId';
		controller.saveConfig();

		refreshData();

		// edit the existing mapping
		controller.childObject = rollupConfigs[0].Child_Object_Name__c;
		controller.parentObject = rollupConfigs[0].Parent_Object__c;
		controller.selectedConfigName = rollupConfigs[0].Name;
		controller.doEdit = 'true';
		controller.editConfiguration();

		// make it inactive and show a trigger...
		System.assertEquals(true, controller.theConfig.Active__c);

		controller.theConfig.Active__c = false;
		//controller.theConfig.Create_Trigger__c = true;
		controller.saveConfig();

		refreshData();
		System.assertNotEquals(true, controller.theConfig.Active__c);

		// now lets click some boxes to fire the refresh methods...
		controller.theConfig.Do_Math_Query__c = true;
		controller.doMathQuerySelect();

		controller.theConfig.Do_Date_Query__c = true;
		controller.doDateSelect();

		controller.theConfig.Do_Date_Time_Query__c = true;
		controller.doDateTimeSelect();

		controller.customCancel();
	}


	static testMethod void testDelete()
	{
		td = new SG_TDG_LookupRollupSummary();
		refreshData();

		RollupConfigs__c config = new RollupConfigs__c();
		PageReference theScreen = Page.SG_LRHSetup;
		Test.setCurrentPage(theScreen);
		//System.currentPageReference().getParameters().put('acctId', a.Id);

		ApexPages.StandardController con = new ApexPages.Standardcontroller( config );
		SG_VFC_LRHSetup controller = new SG_VFC_LRHSetup( con );

		// create a new mapping
		controller.doShowCreateSection();
		controller.childObject = 'Contact';
		controller.parentObject = 'Account';
		controller.setObjects();

		System.assertNotEquals(null, controller.theConfig );
		System.assertNotEquals( null, controller.theConfig.Name );

		// configure the mapping
		controller.theConfig.queryField_parentRelationshipName__c = 'AccountId';
		controller.saveConfig();

		refreshData();

		// delete the existing mapping
		controller.deleteConfig();

		refreshData();
		//System.assertEquals(null, controller.theConfig);
	}

	static testMethod void testQueueable()
	{
		td = new SG_TDG_LookupRollupSummary();
		refreshData();


		//Pass in the API name of the child object, for example 'Contact' and the API name of the parent object, for example 'Account';
		SG_LookupRollupHelper lh = new SG_LookupRollupHelper( 'Contact', 'Account');

		List<Contact> contacts2 = new List<Contact>();
		for ( Contact c : contacts )
		{
			c.FirstName = 'NEW';
			contacts2.add( c );
		}

		// take care of assigning the correct lists based on the trigger type (Insert vs Update vs Delete vs Undelete)
		lh.setTriggerLists(false, false, contacts2, contacts);


		RollupConfigs__c config = new RollupConfigs__c();
		PageReference theScreen = Page.SG_LRHSetup;
		Test.setCurrentPage(theScreen);
		//System.currentPageReference().getParameters().put('acctId', a.Id);

		ApexPages.StandardController con = new ApexPages.Standardcontroller( config );
		SG_VFC_LRHSetup controller = new SG_VFC_LRHSetup( con );

		// create a new mapping
		controller.doShowCreateSection();
		controller.childObject = 'Contact';
		controller.parentObject = 'Account';
		controller.setObjects();

		System.assertNotEquals(null, controller.theConfig );
		System.assertNotEquals( null, controller.theConfig.Name );

		// configure the mapping
		controller.theConfig.queryField_parentRelationshipName__c = 'AccountId';
		controller.theConfig.Use_Queueable__c = true;
		controller.theConfig.Additional_Filter_Clause__c = ' AND CreatedDate != null ';
		controller.saveConfig();

		refreshData();
		// fire the rollup...
		lh.mappingToUse = controller.theConfig.Name;
		lh.doRollupSummary();

	}

	static testMethod void testDateRollup()
	{
		td = new SG_TDG_LookupRollupSummary();
		refreshData();


		RollupConfigs__c config = new RollupConfigs__c();
		PageReference theScreen = Page.SG_LRHSetup;
		Test.setCurrentPage(theScreen);
		//System.currentPageReference().getParameters().put('acctId', a.Id);

		ApexPages.StandardController con = new ApexPages.Standardcontroller( config );
		SG_VFC_LRHSetup controller = new SG_VFC_LRHSetup( con );

		// create a new mapping
		controller.doShowCreateSection();
		controller.childObject = 'Contact';
		controller.parentObject = 'Account';
		controller.setObjects();

		System.assertNotEquals(null, controller.theConfig );
		System.assertNotEquals( null, controller.theConfig.Name );

		// configure the mapping

		controller.theConfig.Use_Queueable__c = false;
		controller.theConfig.Additional_Filter_Clause__c = ' AND CreatedDate != null ';

		// set the right box
		controller.theConfig.Do_Date_Query__c = true;

		// let's get a bonus valiation test...
		controller.theConfig.queryField_parentRelationshipName__c = null;
		controller.theConfig.Date_Math_Query_Type__c = null;
		controller.saveConfig();

		refreshData();
		Map<String, RollupConfigs__c> configMap = RollupConfigs__c.getAll();
		System.debug(LoggingLevel.WARN, '---> in testDateRollup; configMap after failed validation test: ' + configMap );
		System.assertEquals( 0, configMap.keySet().size() );

		// let's save for real...
		controller.theConfig.queryField_parentRelationshipName__c = 'AccountId';
		controller.theConfig.Date_Math_Query_Type__c = 'MAX';
		controller.theConfig.parentQueryField1__c = 'Site';

		// set up some bogus fields...
		controller.theConfig.queryField1__c = 'Birthdate';
		controller.theConfig.parentQueryField1__c = 'NumberOfEmployees';
		controller.saveConfig();

		refreshData();

		configMap = RollupConfigs__c.getAll();
		System.debug(LoggingLevel.WARN, '---> in testDateRollup; configMap is now: ' + configMap );


		// fire the rollup...
		//Pass in the API name of the child object, for example 'Contact' and the API name of the parent object, for example 'Account';
		SG_LookupRollupHelper lh = new SG_LookupRollupHelper( 'Contact', 'Account');

		// take care of assigning the correct lists based on the trigger type (Insert vs Update vs Delete vs Undelete)
		lh.setTriggerLists(true, false, contacts, null);
		lh.doDateQuery = true;
		lh.dateMathQueryType = 'MAX';

		// do the rollup(s) -- will execute all active rollups for current child/parent configuration
		lh.doRollupSummary();

	}

	static testMethod void testDateTimeRollup()
	{
		td = new SG_TDG_LookupRollupSummary();
		refreshData();


		RollupConfigs__c config = new RollupConfigs__c();
		PageReference theScreen = Page.SG_LRHSetup;
		Test.setCurrentPage(theScreen);
		//System.currentPageReference().getParameters().put('acctId', a.Id);

		ApexPages.StandardController con = new ApexPages.Standardcontroller( config );
		SG_VFC_LRHSetup controller = new SG_VFC_LRHSetup( con );

		// create a new mapping
		controller.doShowCreateSection();
		controller.childObject = 'Contact';
		controller.parentObject = 'Account';
		controller.setObjects();

		System.assertNotEquals(null, controller.theConfig );
		System.assertNotEquals( null, controller.theConfig.Name );

		// configure the mapping

		controller.theConfig.Use_Queueable__c = false;
		controller.theConfig.Additional_Filter_Clause__c = ' AND CreatedDate != null ';

		// set the right box
		controller.theConfig.Do_Date_Time_Query__c = true;

		controller.theConfig.queryField_parentRelationshipName__c = 'AccountId';
		controller.theConfig.Date_Math_Query_Type__c = 'MAX';

		// set up some bogus fields...
		controller.theConfig.queryField1__c = 'CreatedDate';
		controller.theConfig.parentQueryField1__c = 'NumberOfEmployees';

		controller.saveConfig();

		refreshData();

		// fire the rollup...
		//Pass in the API name of the child object, for example 'Contact' and the API name of the parent object, for example 'Account';
		SG_LookupRollupHelper lh = new SG_LookupRollupHelper( 'Contact', 'Account');

		// take care of assigning the correct lists based on the trigger type (Insert vs Update vs Delete vs Undelete)
		lh.setTriggerLists(true, false, contacts, null);


		// do the rollup(s) -- will execute all active rollups for current child/parent configuration
		lh.doRollupSummary();

	}

	static testMethod void testMathRollup()
	{
		td = new SG_TDG_LookupRollupSummary();
		refreshData();


		RollupConfigs__c config = new RollupConfigs__c();
		PageReference theScreen = Page.SG_LRHSetup;
		Test.setCurrentPage(theScreen);
		//System.currentPageReference().getParameters().put('acctId', a.Id);

		ApexPages.StandardController con = new ApexPages.Standardcontroller( config );
		SG_VFC_LRHSetup controller = new SG_VFC_LRHSetup( con );

		// create a new mapping
		controller.doShowCreateSection();
		controller.childObject = 'Contact';
		controller.parentObject = 'Account';
		controller.setObjects();

		System.assertNotEquals(null, controller.theConfig );
		System.assertNotEquals( null, controller.theConfig.Name );

		// configure the mapping

		controller.theConfig.Use_Queueable__c = false;
		controller.theConfig.Additional_Filter_Clause__c = ' AND CreatedDate != null ';

		// set the right box
		controller.theConfig.Do_Math_Query__c = true;

		controller.theConfig.queryField_parentRelationshipName__c = 'AccountId';
		controller.theConfig.Date_Math_Query_Type__c = 'MAX';
		// set up some bogus fields...
		controller.theConfig.queryField1__c = 'Birthdate';
		controller.theConfig.parentQueryField1__c = 'NumberOfEmployees';
		controller.saveConfig();


		refreshData();

		// fire the rollup...
		//Pass in the API name of the child object, for example 'Contact' and the API name of the parent object, for example 'Account';
		SG_LookupRollupHelper lh = new SG_LookupRollupHelper( 'Contact', 'Account');

		// take care of assigning the correct lists based on the trigger type (Insert vs Update vs Delete vs Undelete)
		lh.setTriggerLists(true, false, contacts, null);

		// do the rollup(s) -- will execute all active rollups for current child/parent configuration
		lh.doRollupSummary();
	}

	/*
	static testMethod void testCheckboxes()
	{
		td = new SG_TDG_LookupRollupSummary();
		refreshData();


		//Pass in the API name of the child object, for example 'Contact' and the API name of the parent object, for example 'Account';
		SG_LookupRollupHelper lh = new SG_LookupRollupHelper( 'Contact', 'Account');

		List<Contact> contacts2 = new List<Contact>();
		for ( Contact c : contacts )
		{
			c.FirstName = 'NEW';
			contacts2.add( c );
		}

		// take care of assigning the correct lists based on the trigger type (Insert vs Update vs Delete vs Undelete)
		lh.setTriggerLists(false, false, contacts2, contacts);


		RollupConfigs__c config = new RollupConfigs__c();
		PageReference theScreen = Page.SG_LRHSetup;
		Test.setCurrentPage(theScreen);
		//System.currentPageReference().getParameters().put('acctId', a.Id);

		ApexPages.StandardController con = new ApexPages.Standardcontroller( config );
		SG_VFC_LRHSetup controller = new SG_VFC_LRHSetup( con );

		// create a new mapping
		controller.doShowCreateSection();
		controller.childObject = 'Contact';
		controller.parentObject = 'Account';
		controller.setObjects();

		System.assertNotEquals(null, controller.theConfig );
		System.assertNotEquals( null, controller.theConfig.Name );

		// configure the mapping
		controller.theConfig.queryField_parentRelationshipName__c = 'AccountId';
		controller.theConfig.Use_Queueable__c = true;
		controller.theConfig.Additional_Filter_Clause__c = ' AND CreatedDate != null ';
		controller.saveConfig();


		refreshData();

		// now lets click some boxes to fire the refresh methods...
		controller.theConfig.Do_Math_Query__c = true;
		controller.theConfig.Do_Date_Query__c = false;
		controller.theConfig.Do_Date_Time_Query__c = false;
		controller.theConfig.Date_Math_Query_Type__c = 'MAX';
		controller.saveConfig();

		refreshData();
		// fire the rollup...
		lh.mappingToUse = controller.theConfig.Name;
		lh.doRollupSummary();

		controller.theConfig.Do_Math_Query__c = false;
		controller.theConfig.Do_Date_Query__c = true;
		controller.theConfig.Do_Date_Time_Query__c = false;
		controller.theConfig.Date_Math_Query_Type__c = 'MAX';
		controller.saveConfig();

		refreshData();
		// fire the rollup...
		lh.mappingToUse = controller.theConfig.Name;
		lh.doRollupSummary();

		controller.theConfig.Do_Math_Query__c = false;
		controller.theConfig.Do_Date_Query__c = false;
		controller.theConfig.Do_Date_Time_Query__c = true;
		controller.theConfig.Date_Math_Query_Type__c = 'MAX';
		controller.saveConfig();

		refreshData();
		// fire the rollup...
		lh.mappingToUse = controller.theConfig.Name;
		lh.doRollupSummary();

	}*/

	public static void refreshData()
	{
		accounts = [SELECT Id, Name FROM Account];
		contacts = [SELECT Id, Name, Email, AccountId FROM Contact ];
		rollupConfigs = [SELECT Id, Name, Child_Object_Name__c, Parent_Object__c, parentRowCount__c, queryField_parentRelationshipName__c, Active__c, Use_Queueable__c
				, queryField1__c, queryField2__c, queryField3__c, queryField4__c, queryField5__c
				, parentQueryField1__c, parentQueryField2__c, parentQueryField3__c, parentQueryField4__c, parentQueryField5__c,
				Config_Notes__c, Additional_Filter_Clause__c, Do_Date_Query__c, Do_Date_Time_Query__c, Do_Math_Query__c, Date_Math_Query_Type__c
				FROM RollupConfigs__c];

	}


}