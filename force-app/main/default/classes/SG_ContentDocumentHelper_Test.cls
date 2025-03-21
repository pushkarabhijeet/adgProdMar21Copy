/**********************************************************************
* Name:     SG_ContentDocumentHelper_Test
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
* 1.0       23-Jun-2020     rwd           Initial Development           
*   
***********************************************************************/


@IsTest
public class SG_ContentDocumentHelper_Test {
	private static SG_TestDataGenerator td;
	private static List<Account> accounts;
	private static List<Asset> assets;
	private static List<WorkOrder> workOrders;
	private static List<Quality_Control__c> qcs;
	private static List<ContentDocument> docs;


	public static Boolean isTest = false;

	// simulate uploading file from a LWC
	// from upload of CDL with a hidden field
	// add file to asset
	static testMethod void testAddFile()
	{
		System.debug(LoggingLevel.WARN, '---> in test; start testAddFile');
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
		resetTriggerBools();

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
		resetTriggerBools();

		String originalTitle = 'Test';
		String docPath = 'Test.jpg';
		List<Schema.FieldSetMember> pictureFieldNames = SG_SchemaUtils.getFieldSetMembers( 'Picture_Upload_Fields', 'Quality_Control__c');
		Schema.FieldSetMember field = pictureFieldNames[0];


		Quality_Control__c qc = new Quality_Control__c();
		qc.Work_Order__c = wo.Id;
		qc.House_Unit__c = assets[0].Id;
		qc.put(field.getFieldPath(), originalTitle );
		qc.QC_Date__c = Date.today();
		System.debug(LoggingLevel.WARN, '---> in test; test pic field: ' + field.getFieldPath() );
		System.debug(LoggingLevel.WARN, '---> in test; test pic title: ' + qc.get( field.getFieldPath() ) );
		insert qc;



		// add a file...
		ContentVersion cv = new ContentVersion(
				Title = originalTitle,
				PathOnClient = docPath,
				VersionData = blob.valueof('Test Content Data'),
				IsMajorVersion = true);
		insert cv;

		System.debug(LoggingLevel.WARN, '---> cv in test: ' + cv );

		//List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
		refreshData();
		resetTriggerBools();

		System.debug(LoggingLevel.WARN, '---> documents in test: ' + docs );

		ContentDocumentLink contentlink=new ContentDocumentLink();
		contentlink.LinkedEntityId=qc.Id;
		contentlink.ShareType= 'I';
		contentlink.ContentDocumentId=docs[0].Id;
		contentlink.Visibility = 'AllUsers';
		insert contentlink;

		refreshData();
		resetTriggerBools();
		for ( ContentDocument cd : docs )
		{
			System.debug(LoggingLevel.WARN, '---> in test; doc title: ' + cd.Title );
			System.assertNotEquals( originalTitle, cd.Title );
		}

		refreshData();
		resetTriggerBools();
		update qc;


		// test setting a hidden field on the QC; these could change, so let's just assume it's the Comments field for the test...

		Boolean isSuccess_Rename = SG_ContentDocumentHelper.setHiddenPictureFieldForQC(qc.Id, 'Comment__c', 'TEST_' );
	//	System.assertEquals( true, isSuccess_Rename );

		// test the activator
		isTest = true;

		ContentVersion cv2 = new ContentVersion(
				Title = 'Test',
				PathOnClient = docPath,
				VersionData = blob.valueof('Test Content Data'),
				IsMajorVersion = true);
		insert cv2;
		refreshData();
		resetTriggerBools();

		System.debug(LoggingLevel.WARN, '---> cv2 in test: ' + cv2 );
		System.debug(LoggingLevel.WARN, '---> docs in test: ' + docs );

		ContentDocumentLink contentlink2=new ContentDocumentLink();
		contentlink2.LinkedEntityId=qc.Id;
		contentlink2.ShareType= 'I';
		contentlink2.ContentDocumentId=docs[1].Id;
		contentlink2.Visibility = 'AllUsers';
		insert contentlink2;

		resetTriggerBools();
		SG_QualityControlHelper_Test.isTest = true;
		update qc;
	}

	static testMethod void testFileRename()
	{
		// add a file...
		String docTitle = 'Test.jpg';
		String prefix = 'Renamed_';
		ContentVersion cv = new ContentVersion(
				Title = 'Test',
				PathOnClient = docTitle,
				VersionData = blob.valueof('Test Content Data'),
				IsMajorVersion = true);
		insert cv;

		System.debug(LoggingLevel.WARN, '---> cv in test: ' + cv );

		refreshData();
		resetTriggerBools();
		String fileIds = docs[0].Id;

		System.debug(LoggingLevel.WARN, '---> in test; fileIds: ' + fileIds );


		Boolean isSuccess_Rename = SG_ContentDocumentHelper.doCustomQcFileName(fileIds, prefix );
		System.assertEquals( true, isSuccess_Rename );
	}

	public static void refreshData() {
		accounts = [SELECT Id, Name, RecordTypeId FROM Account];
		assets = [SELECT Id, Name, AccountId FROM Asset];
		workOrders = [SELECT Id, Description, AssetId FROM WorkOrder];
		qcs = [SELECT Id, Name FROM Quality_Control__c];
		docs = [SELECT Id, Title, FileType, FileExtension, LatestPublishedVersionId FROM ContentDocument];
	}

	public static void resetTriggerBools()
	{
		SG_ContentDocumentHelper.hasSetAsset = false;
		SG_ContentDocumentHelper.hasSetFileNames = false;
		SG_ContentDocumentHelper.hasSetFileNames_CDL = false;
		SG_QualityControlHelper.hasSetFileNames = false;
		SG_QualityControlHelper.hasDoneQcRollups = false;
	}
}