/**********************************************************************
* Name:     SG_VFC_BuildMeasureTest
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
* 1.0       24-Nov-2020     rwd           Initial Development           
*   
***********************************************************************/


@IsTest
private class SG_VFC_BuildMeasureTest {

	private static SG_TestDataGenerator td;
	private static List<Account> accounts;
	private static List<Asset> assets;
	private static List<WorkOrder> workOrders;
	private static List<Quality_Control__c> qcs;
	private static List<QC_Build_Measure__c> measures;


	static testMethod void testBehavior() {
		refreshData();
		td = new SG_TestDataGenerator();
		td.accountNum = 2;
		td.assetNum = 1;
		accounts = td.getAccounts(false);
		ID standardAccountRTID = Schema.SObjectType.Account.getRecordTypeInfosByName().get( 'Standard' ).getRecordTypeId();
		ID installerRTID = Schema.SObjectType.Account.getRecordTypeInfosByName().get( 'Installer Company' ).getRecordTypeId();

		accounts[0].RecordTypeId = standardAccountRTID;
		accounts[1].RecordTypeId = installerRTID;
		insert accounts;
		System.debug(LoggingLevel.WARN, '---> accounts after insert in test: ' + accounts );

		refreshData();

		System.debug(LoggingLevel.WARN, '---> getting assets');
		assets = td.getAssets(false);
		assets[0].AccountId = accounts[0].Id; // make sure using the correct RTId
		insert assets;

		System.debug(LoggingLevel.WARN, '---> assets: ' + assets );
		System.debug(LoggingLevel.WARN, '---> accounts: ' + accounts );

		WorkOrder wo = new WorkOrder();
		wo.Installer_Account__c = accounts[1].Id;
		wo.Job_Type__c = 'QC Pre-Walk';
		wo.Start_Day__c = Date.today().addDays( 1 );
		wo.Job_End_Day__c = Date.today().addDays( 3 );
		wo.AccountID =  accounts[0].Id;
		wo.PrimaryIdentifier__c = assets[0].PrimaryIdentifier__c;
		insert wo;


		refreshData();


		Quality_Control__c qc = new Quality_Control__c();
		qc.Work_Order__c = wo.Id;
		qc.House_Unit__c = assets[0].Id;
		qc.QC_Date__c = Date.today();
		insert qc;

		System.assertEquals(0, measures.size(), 'Should have begun with 0 measurements');

		QC_Build_Measure__c measure = new QC_Build_Measure__c();
		PageReference theScreen = Page.BuildMeasure;
    	Test.setCurrentPage(theScreen);
    	System.currentPageReference().getParameters().put('Id', qc.Id );
    	
    	ApexPages.StandardController con = new ApexPages.Standardcontroller( qc );
    	SG_VFC_BuildMeasure controller = new SG_VFC_BuildMeasure( con );

		// should have blank rows...
		System.assertEquals( SG_VFC_BuildMeasure.INITIAL_MEASUREMENT_NUMBER, controller.measurements.size() );

		// start off by adding a couple blank rows
		controller.addMoreMeasurements();

		controller.getEdgeItems();

		// add a measurement
		controller.measurements[0].Name = 'Measure 1';
		controller.measurements[0].Length__c = '15';
		controller.measurements[0].Width__c = '25';
		controller.measurements[0].Material__c = 'Granite';
		controller.measurements[0].Do_edges_need_beveled_and_polished__c = 'Yes';
		controller.measurements[0].Comments__c = 'Comments, etc';
		controller.customSave();

		refreshData();
		System.assertEquals(1, measures.size(), 'Did not save measurement');

		// test with existing...
		ApexPages.StandardController con2 = new ApexPages.Standardcontroller( qc );
		SG_VFC_BuildMeasure controller2 = new SG_VFC_BuildMeasure( con2 );

		// add a second measurement
		controller2.measurements[1].Name = 'Measure 2';
		controller2.measurements[1].Length__c = '10';
		controller2.measurements[1].Width__c = '20';
		controller2.measurements[1].Material__c = 'Granite';
		controller2.measurements[1].Do_edges_need_beveled_and_polished__c = 'Yes';
		controller2.measurements[1].Comments__c = 'Comments 2, etc';
		System.debug(LoggingLevel.WARN, '---> in test; about to save...');
		controller2.customSave();

		refreshData();
		System.debug(LoggingLevel.WARN, '---> in test; measures: ' + measures );
		System.assertEquals(2, measures.size(), 'Did not save measurement');

	}

	public static void refreshData() {
		accounts = [SELECT Id, Name, RecordTypeId FROM Account];
		assets = [SELECT Id, Name, AccountId FROM Asset];
		workOrders = [SELECT Id, Description, AssetId FROM WorkOrder];
		qcs = [SELECT Id, Name FROM Quality_Control__c];
		measures = [SELECT Id, Name, Length__c, Width__c, Material__c, Do_edges_need_beveled_and_polished__c, Quality_Control__c, Comments__c FROM QC_Build_Measure__c ];

		//resetTriggerBools();
	}




}