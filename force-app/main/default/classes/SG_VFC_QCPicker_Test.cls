/**********************************************************************
* Name:     SG_VFC_QCPicker_Test
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
* 1.0       26-Jun-2020     rwd           Initial Development           
*   
***********************************************************************/


@IsTest
private class SG_VFC_QCPicker_Test {

	private static SG_TestDataGenerator td;
	private static List<Account> accounts;
	private static List<Asset> assets;
	private static List<WorkOrder> workOrders;
	private static List<Quality_Control__c> qcs;



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

		refreshData();

		wo = workOrders[0];
		qc = qcs[0];

		PageReference theScreen = Page.QCPicker;
		System.currentPageReference().getParameters().put('Id', wo.Id);

		ApexPages.StandardController con = new ApexPages.Standardcontroller( wo );
		SG_VFC_QCPicker controller = new SG_VFC_QCPicker( con );

		controller.selectedQcId = qc.Id;
		controller.goToQc();

		// test without selecting...
		controller.selectedQcId = null;
		controller.goToQc();
		
	}

	public static void refreshData() {
		accounts = [SELECT Id, Name, RecordTypeId FROM Account];
		assets = [SELECT Id, Name, AccountId FROM Asset];
		workOrders = [SELECT Id, Description, AssetId FROM WorkOrder];
		qcs = [SELECT Id, Name FROM Quality_Control__c];
	}


}