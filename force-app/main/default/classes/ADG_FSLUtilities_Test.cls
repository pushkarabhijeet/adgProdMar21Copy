/***********************************************************************************
* Name:     	ADG_FSLUtilities_Test
* Author:   	Pushkar
* Main Class:  ADG_FSLUtilities
* ======================================================
* History:
* VER   DATE          INITIALS      DESCRIPTION/FEATURES ADDED
* 1.0   May 18 2021   pushkar       Initial Development for FSL 
*
***********************************************************************************/
@isTest
public class ADG_FSLUtilities_Test {
    
    @TestSetup
    public static void setupData() {
        SG_WorkOrderHelper_Test.createDataForFSL();

        // create/query objects to test
        Account installer = [
                SELECT ID
                FROM Account
                WHERE Name LIKE 'Installer%'
                LIMIT 1
        ];

        Asset anAsset = [
                SELECT ID, Field_Service_Manager__c, AccountID
                FROM Asset
                WHERE Name = '1313 Mockingbird'
                LIMIT 1
        ];

        SG_ServiceAppointment.recordIdsAlreadyProcessedSet = new Set<ID>();

        WorkOrder wo = new WorkOrder();
        wo.AssetId = anAsset.ID;
        wo.Installer_Account__c = installer.ID;
        wo.Job_Type__c = 'QC Pre-Walk';
        wo.Start_Day__c = Date.today().addDays( 1 );
        wo.Job_End_Day__c = Date.today().addDays( 3 );

        system.debug( 'inserting test WO= ' + wo );
        insert wo;
        
        Quality_Control__c qc = [
                SELECT ID, House_Unit__c, Work_Order__c, Most_Recent_Case_Created__c
                FROM Quality_Control__c
                WHERE House_Unit__r.Name = '1313 Mockingbird'
                AND Work_Order__r.Job_Type__c = 'QC Pre-Walk'
                LIMIT 1
        ];
       	String originalTitle = 'Test';
		String docPath = 'Test.jpg';
        
        // add a file...
		ContentVersion cv = new ContentVersion(
				Title = 'Test.jpg',
				PathOnClient = docPath,
				VersionData = blob.valueof('Test Content Data'),
				IsMajorVersion = true);
		insert cv;
        
        ContentDocument docs = [SELECT Id, Title, FileType, FileExtension, LatestPublishedVersionId FROM ContentDocument];
             
        ContentDocumentLink contentlink=new ContentDocumentLink();
		contentlink.LinkedEntityId= qc.Id;
		contentlink.ShareType= 'I';
		contentlink.ContentDocumentId= docs.Id ;
		contentlink.Visibility = 'AllUsers';
		insert contentlink;
    }
    
    static testMethod void renameFiles_test(){
        Test.startTest();
        Quality_Control__c qcTest = [
                SELECT ID, House_Unit__c, Work_Order__c, Most_Recent_Case_Created__c
                FROM Quality_Control__c
                WHERE House_Unit__r.Name = '1313 Mockingbird'
                AND Work_Order__r.Job_Type__c = 'QC Pre-Walk'
                LIMIT 1
        ];
        ContentDocument docTest = [SELECT Id, Title, FileType, FileExtension, LatestPublishedVersionId FROM ContentDocument LIMIT 1];
        
        system.debug('@QCId' + qcTest.Id);
        ADG_FSLUtilities.FlowInputs fslinp = new ADG_FSLUtilities.FlowInputs();
        fslinp.fileNames = docTest.Title;
        fslinp.prefix = 'Pre_Walk';
        fslinp.recId = qcTest.Id;
        List<ADG_FSLUtilities.FlowInputs> listinp = new List<ADG_FSLUtilities.FlowInputs>();
        listinp.add(fslinp);
        ADG_FSLUtilities.renameFiles(listinp);
        Test.stopTest();
    }
}