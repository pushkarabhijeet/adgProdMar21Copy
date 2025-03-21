/***************************************************
* Name:         SG_WorkOrderHelper_Test
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
* 
****************************************************/

@isTest
public with sharing class SG_WorkOrderHelper_Test {
    @TestSetup
    public static void setupData() {
        createDataForFSL();

    }

    public static void createDataForFSL() {
        SG_Asset_LU_Test.isTest = true;
        //TestAdgSetup.Setup();
        //ADG_SfapiConfig__c dummyConfig = new ADG_SfapiConfig__c();
        //dummyConfig.apiKey__c = 'ABC123';
        //dummyConfig.baseUrl__c = 'http://dummy.com/';
        //insert dummyConfig;

        ID installerRTID = Schema.SObjectType.Account.getRecordTypeInfosByName().get( 'Installer Company' ).getRecordTypeId();

        ID standardAccountRTID = Schema.SObjectType.Account.getRecordTypeInfosByName().get( 'Standard' ).getRecordTypeId();

        Account a = new Account();
        a.Name = 'Company Test One';
        a.RecordTypeID = standardAccountRTID;
        insert a;

        Account installer = new Account();
        installer.Name = 'Installer Test';
        installer.RecordTypeID = installerRTID;
        insert installer;

        String orgId = Userinfo.getOrganizationID();
        String uniqueEmail = 'test@' + orgId + '.net.test';
        User anUser = new User( Alias = 'TST'
                , CommunityNickname = 'TST'
                , Email = uniqueEmail
                , EmailEncodingKey = 'UTF-8'
                , FirstName = 'Joe'
                , LastName = 'Sixpack TEST'
                , LanguageLocaleKey = 'en_US'
                , LocaleSidKey = 'en_US'
                , Profile = new Profile( Name = '#Custom: Field Service Manager' )
                , TimezoneSidKey = 'America/Los_Angeles'
                , UserName = uniqueEmail );
        insert anUser;

        uniqueEmail = 'test2@' + orgId + '.net.test';
        User anUser2 = new User( Alias = 'TSTMARY'
                , CommunityNickname = 'TSTMARY'
                , Email = uniqueEmail
                , EmailEncodingKey = 'UTF-8'
                , FirstName = 'Mary'
                , LastName = 'Sixpack TEST'
                , LanguageLocaleKey = 'en_US'
                , LocaleSidKey = 'en_US'
                , Profile = new Profile( Name = '#Custom: Field Service Manager' )
                , TimezoneSidKey = 'America/Los_Angeles'
                , UserName = uniqueEmail );
        insert anUser2;

        OperatingHours theHours = new OperatingHours();
        theHours.Name = 'Sixpack hours';
        theHours.TimeZone = 'America/Chicago';
        insert theHours;

        ServiceTerritory aTerritory = new ServiceTerritory();
        aTerritory.Name = 'Sixpack TEST territory';
        aTerritory.OperatingHoursId = theHours.ID;
        aTerritory.IsActive = true;
        insert aTerritory;

        ServiceResource aResource = new ServiceResource();
        aResource.Name = 'Joe Sixpack, the main resource';
        aResource.RelatedRecordId = anUser.Id;
        aResource.Service_Resource_User_ID__c = anUser.Id;
        aResource.Territory_ID__c = aTerritory.ID;
        aResource.IsActive = true;
        insert aResource;

        ServiceResource aResource2 = new ServiceResource();
        aResource2.Name = 'Mary Sixpack, the second resource';
        aResource2.RelatedRecordId = anUser2.Id;
        aResource2.Service_Resource_User_ID__c = anUser2.Id;
        aResource2.Territory_ID__c = aTerritory.ID;
        aResource2.IsActive = true;
        insert aResource2;

        ServiceTerritoryMember serviceTerritoryMember1 = new ServiceTerritoryMember();
        serviceTerritoryMember1.ServiceTerritoryId = aTerritory.Id;
        serviceTerritoryMember1.ServiceResourceId = aResource.Id;
        serviceTerritoryMember1.TerritoryType = 'P';
        serviceTerritoryMember1.EffectiveStartDate = Date.today().addDays( -1 );
        insert serviceTerritoryMember1;

        ServiceTerritoryMember serviceTerritoryMember2 = new ServiceTerritoryMember();
        serviceTerritoryMember2.ServiceTerritoryId = aTerritory.Id;
        serviceTerritoryMember2.ServiceResourceId = aResource2.Id;
        serviceTerritoryMember2.TerritoryType = 'P';
        serviceTerritoryMember2.EffectiveStartDate = Date.today().addDays( -1 );
        insert serviceTerritoryMember2;

        BusinessHours bh = [
                SELECT ID
                FROM BusinessHours
                WHERE Name = 'Central Time Zone'
        ]; //'Eastern Time Zone Installers W Saturday'

        Community__c aCommunity = new Community__c();
        aCommunity.Name = 'Someone\'s community';
        aCommunity.EntityIntegration__c = 'ABC_123:';
        aCommunity.Control_Date_Tasks_Needed__c = 'Yes';
        aCommunity.Inspector__c = aResource.ID;
        aCommunity.Day_Count_Floor_Wall_Tile__c = 4;
        aCommunity.Day_Count_QC_End__c = 2;
        aCommunity.Business_Hours__c = bh.ID;
        aCommunity.Builder__c = a.ID;
        insert aCommunity;

        Asset anAsset = new Asset();
        anAsset.Name = '1313 Mockingbird';
        anAsset.Lot_Block__c = anAsset.Name;
        anAsset.City__c = 'Dallas';
        anAsset.State__c = 'TX';
        anAsset.Zip_Code__c = '76001';
        anAsset.AccountID = a.ID;
        anAsset.Community__c = aCommunity.ID;
        anAsset.Field_Service_Manager__c = aResource.ID;
        //anAsset.ContactID = aCustomer.ID;
        anAsset.Status = 'Pre-Start';
        anAsset.Integration_Key_Billing_Group__c = 'TEST123';
        anAsset.PrimaryIdentifier__c = 'ID-TEST123';
        insert anAsset;
    }

    public static TestMethod void workOrderDateCalculationTest() {
        Test.startTest();

        // create/query objects to test
        Account installer = [
                SELECT ID
                FROM Account
                WHERE Name LIKE 'Installer%'
                LIMIT 1
        ];

        Asset anAsset = [
                SELECT ID, Field_Service_Manager__c, AccountID, Community__c
                        , Field_Service_Manager_Territory_ID__c
                FROM Asset
                WHERE Name = '1313 Mockingbird'
                LIMIT 1
        ];

        WorkOrder wo = new WorkOrder();
        wo.AssetId = anAsset.ID;
        wo.Installer_Account__c = installer.ID;
        wo.Job_Type__c = 'TILE_COMBO';
        wo.Start_Day__c = Date.today().addDays( 1 );
        wo.Job_End_Day__c = Date.today().addDays( 3 );
        system.debug( 'new WO= ' + wo );
        insert wo;

        String qcRecTypeID = SG_WorkOrderHelper.jobTypeToQCRecordTypeIDMap.get( wo.Job_Type__c.toUpperCase() );
        Quality_Control__c qc = SG_WorkOrderHelper.createQualityControl( anAsset.Id
                                , qcRecTypeID, wo.Id );
        insert qc;

        wo.Start_Day__c = Date.newInstance( 2020, 11, 18 );
        update wo;

        wo = [
                SELECT ID, Job_End_Day_calculated__c, QC_Start_Date__c, QC_End_Date__c
                FROM WorkOrder
                WHERE ID = :wo.ID
        ];

        Test.stopTest();

        // Job_End_Day_calculated__c = start dt + Day_Count_Floor_Wall_Tile__c(4) - 1 = start dt + 3
        system.assertEquals( Date.newInstance( 2020, 11, 20 ), wo.Job_End_Day_calculated__c, 'job end day should be 3 days from start dt' );
        // QC_Start_Date__c = start dt + 4
        system.assertEquals( Date.newInstance( 2020, 11, 23 ), wo.QC_Start_Date__c, 'QC start should be 4 days from start dt' );
        // nbrDays = dayCount + QCEndCount - 1 = 4 + 2 - 1 = 5 days from start dt
        system.assertEquals( Date.newInstance( 2020, 11, 24 ), wo.QC_End_Date__c, 'QC end should be 5 days from start dt' );

    }

    public static TestMethod void changeAssetFSMTest() {
        Test.startTest();

        // create/query objects to test
        Account installer = [
                SELECT ID
                FROM Account
                WHERE Name LIKE 'Installer%'
                LIMIT 1
        ];

        Asset anAsset = [
                SELECT ID, Field_Service_Manager__c, AccountID, Community__c
                        , Field_Service_Manager_Territory_ID__c
                FROM Asset
                WHERE Name = '1313 Mockingbird'
                LIMIT 1
        ];

        WorkOrder wo = new WorkOrder();
        wo.AssetId = anAsset.ID;
        wo.Installer_Account__c = installer.ID;
        wo.Job_Type__c = 'QC Pre-Walk';
        wo.Start_Day__c = Date.today().addDays( 1 );
        wo.Job_End_Day__c = Date.today().addDays( 3 );
        insert wo;

        ServiceResource aResource2 = [
                SELECT ID
                FROM ServiceResource
                WHERE Name = 'Mary Sixpack, the second resource'
        ];

        // reset so the asset trigger can run again
        SG_AssetHelper.recordIdsAlreadyProcessedSet = new Set<ID>();

        anAsset.Field_Service_Manager__c = aResource2.ID;
        update anAsset;

        Test.stopTest();

        wo = [
                SELECT ID, ServiceTerritoryId, ServiceTerritory.Name
                        , OwnerID, Owner.LastName, Field_Service_Manager__c
                        , Job_Type__c, Start_Day__c, Job_End_Day__c, Community__c
                FROM WorkOrder
                WHERE ID = :wo.ID
        ];

        system.assertEquals( anAsset.Field_Service_Manager__c, wo.Field_Service_Manager__c, 'Test FSM assignment' );
    }

    public static TestMethod void serviceApptAndQualityControlSyncTest() {
        Test.startTest();

        // create/query objects to test
        Account installer = [
                SELECT ID
                FROM Account
                WHERE Name LIKE 'Installer%'
                LIMIT 1
        ];

        Asset anAsset = [
                SELECT ID, Field_Service_Manager__c, AccountID, Community__c
                    , Field_Service_Manager_Territory_ID__c
                FROM Asset
                WHERE Name = '1313 Mockingbird'
                LIMIT 1
        ];

        system.assert( anAsset.Field_Service_Manager_Territory_ID__c != null, 'Asset has FSM territory' );

        WorkOrder wo = new WorkOrder();
        wo.AssetId = anAsset.ID;
        wo.Installer_Account__c = installer.ID;
        wo.Job_Type__c = 'QC Pre-Walk';
        wo.Start_Day__c = Date.today().addDays( 1 );
        wo.Job_End_Day__c = Date.today().addDays( 3 );
        insert wo;

        ServiceAppointment servAppt = new ServiceAppointment();
        servAppt.ParentRecordId = wo.ID;
        servAppt.Work_Order__c = wo.ID;
        servAppt.House_Unit__c = anAsset.ID;
        servAppt.Status = 'None';
        servAppt.EarliestStartTime = DateTime.now();
        servAppt.SchedStartTime = DateTime.now().addDays( 1 );
        servAppt.SchedEndTime = DateTime.now().addDays( 3 );
        servAppt.DueDate = DateTime.now().addDays( 3 );
        insert servAppt;

        // reset trigger context
        SG_WorkOrderHelper.recordIdsAlreadyProcessedSet = new Set<ID>();

        // cause serv appt to be updated
        wo.ServiceAppointmentID__c = servAppt.ID;
        wo.Start_Day__c = Date.today().addDays( 2 );
        wo.Job_End_Day__c = Date.today().addDays( 4 );
        update wo;
        system.debug( 'wo with servApptID updated= ' + wo );

        Test.stopTest();

        wo = [
                SELECT ID, ServiceTerritoryId, ServiceTerritory.Name
                        , OwnerID, Owner.LastName, Field_Service_Manager__c
                        , Job_Type__c, Start_Day__c, Job_End_Day__c, Community__c
                FROM WorkOrder
                WHERE ID = :wo.ID
        ];

        system.assertEquals( 'Sixpack TEST territory', wo.ServiceTerritory.Name, 'Test territory assignment' );
        system.assertEquals( 'Sixpack TEST', wo.Owner.LastName, 'Test owner assignment' );
        system.assertEquals( anAsset.Field_Service_Manager__c, wo.Field_Service_Manager__c, 'Test FSM assignment' );
        system.assertEquals( anAsset.Community__c, wo.Community__c, 'Test community assignment' );

        Quality_Control__c qc = [
                SELECT ID, RecordTypeId, House_Unit__c
                FROM Quality_Control__c
                WHERE Work_Order__c = :wo.ID
                LIMIT 1
        ];

        String recTypeID = SG_WorkOrderHelper.jobTypeToQCRecordTypeIDMap.get( wo.Job_Type__c.toUpperCase() );

        system.assertEquals( anAsset.ID, qc.House_Unit__c, 'Test QC record asset' );
        system.assertEquals( recTypeID, qc.RecordTypeId, 'Test QC record asset' );

        servAppt = [
                SELECT ID, SchedStartTime, SchedEndTime
                FROM ServiceAppointment
                WHERE ID = :servAppt.ID
                LIMIT 1
        ];

        system.assertEquals( wo.Start_Day__c, servAppt.SchedStartTime.date(), 'Test serv appt sync 1' );
        system.assertEquals( wo.Job_End_Day__c, servAppt.SchedEndTime.date(), 'Test serv appt sync 2' );
    }

    public static TestMethod void workOrderNoApptTest() {
        Test.startTest();

        // create/query objects to test
        Account installer = [
                SELECT ID
                FROM Account
                WHERE Name LIKE 'Installer%'
                LIMIT 1
        ];

        Asset anAsset = [
                SELECT ID, Field_Service_Manager__c, AccountID
                    , Field_Service_Manager_Territory_ID__c
                FROM Asset
                WHERE Name = '1313 Mockingbird'
                LIMIT 1
        ];

        system.assert( anAsset.Field_Service_Manager_Territory_ID__c != null, 'Asset has FSM territory' );

        WorkOrder wo = new WorkOrder();
        wo.AssetId = anAsset.ID;
        wo.Installer_Account__c = installer.ID;
        wo.Job_Type__c = 'QC Pre-Walk';
        wo.Start_Day__c = Date.today().addDays( 1 );
        wo.Job_End_Day__c = Date.today().addDays( 3 );
        insert wo;

        Test.stopTest();

        wo = [
                SELECT ID, ServiceTerritoryId, ServiceTerritory.Name
                        , OwnerID, Owner.LastName, Field_Service_Manager__c
                        , Job_Type__c, Start_Day__c, Job_End_Day__c
                        , ServiceAppointmentID__c
                FROM WorkOrder
                WHERE ID = :wo.ID
        ];

        system.assertEquals( 'Sixpack TEST territory', wo.ServiceTerritory.Name, 'Test territory assignment' );
        system.assertEquals( 'Sixpack TEST', wo.Owner.LastName, 'Test owner assignment' );
        system.assertEquals( anAsset.Field_Service_Manager__c, wo.Field_Service_Manager__c, 'Test FSM assignment' );

        ServiceAppointment servAppt = [
                SELECT ID, SchedStartTime, SchedEndTime, ParentRecordId, Work_Order__c
                FROM ServiceAppointment
                WHERE Work_Order__c = :wo.ID
                LIMIT 1
        ];

        system.assertEquals( wo.ID, servAppt.ParentRecordId, 'Test serv appt new' );
        system.assertEquals( wo.Start_Day__c, servAppt.SchedStartTime.date(), 'Test serv appt sync 1' );
        system.assertEquals( wo.Job_End_Day__c, servAppt.SchedEndTime.date(), 'Test serv appt sync 2' );
    }

    public static TestMethod void workOrderAssignHouseTest() {
        Test.startTest();

        // create/query objects to test
        Account installer = [
                SELECT ID
                FROM Account
                WHERE Name LIKE 'Installer%'
                LIMIT 1
        ];

        Asset anAsset = [
                SELECT ID, Field_Service_Manager__c, AccountID
                        , Field_Service_Manager_Territory_ID__c
                        , Integration_Key_Billing_Group__c, PrimaryIdentifier__c
                FROM Asset
                WHERE Name = '1313 Mockingbird'
                LIMIT 1
        ];

        system.assert( anAsset.Field_Service_Manager_Territory_ID__c != null, 'Asset has FSM territory' );

        // expect match asset by billing group
        WorkOrder wo = new WorkOrder();
        wo.Installer_Account__c = installer.ID;
        wo.Job_Type__c = 'QC Pre-Walk';
        wo.Start_Day__c = Date.today().addDays( 1 );
        wo.Job_End_Day__c = Date.today().addDays( 3 );
        wo.Billing_Group__c = anAsset.Integration_Key_Billing_Group__c;
        insert wo;

        SG_BatchAssetWorkOrderControl.runMe();

        Test.stopTest();

        wo = [
                SELECT ID, ServiceTerritoryId, ServiceTerritory.Name
                        , OwnerID, Owner.LastName, Field_Service_Manager__c
                        , Job_Type__c, Start_Day__c, Job_End_Day__c
                        , ServiceAppointmentID__c
                FROM WorkOrder
                WHERE ID = :wo.ID
        ];

        system.assertEquals( 'Sixpack TEST territory', wo.ServiceTerritory.Name, 'Test territory assignment' );
        system.assertEquals( 'Sixpack TEST', wo.Owner.LastName, 'Test owner assignment' );
        system.assertEquals( anAsset.Field_Service_Manager__c, wo.Field_Service_Manager__c, 'Test FSM assignment' );
    }

    public static TestMethod void assignHousePrimaryIdentifierTest() {
        Test.startTest();

        // create/query objects to test
        Account installer = [
                SELECT ID
                FROM Account
                WHERE Name LIKE 'Installer%'
                LIMIT 1
        ];

        Asset anAsset = [
                SELECT ID, Field_Service_Manager__c, AccountID
                        , Field_Service_Manager_Territory_ID__c
                        , Integration_Key_Billing_Group__c, PrimaryIdentifier__c
                FROM Asset
                WHERE Name = '1313 Mockingbird'
                LIMIT 1
        ];

        system.assert( anAsset.Field_Service_Manager_Territory_ID__c != null, 'Asset has FSM territory' );

        // expect match asset by account id and primary id
        WorkOrder wo = new WorkOrder();
        wo.Installer_Account__c = installer.ID;
        wo.Job_Type__c = 'QC Pre-Walk';
        wo.Start_Day__c = Date.today().addDays( 1 );
        wo.Job_End_Day__c = Date.today().addDays( 3 );
        wo.AccountID = anAsset.AccountID;
        wo.PrimaryIdentifier__c = anAsset.PrimaryIdentifier__c;
        insert wo;

        SG_BatchAssetWorkOrderControl.runMe();

        Test.stopTest();

        wo = [
                SELECT ID, ServiceTerritoryId, ServiceTerritory.Name
                        , OwnerID, Owner.LastName, Field_Service_Manager__c
                        , Job_Type__c, Start_Day__c, Job_End_Day__c
                        , ServiceAppointmentID__c
                FROM WorkOrder
                WHERE ID = :wo.ID
        ];

        system.assertEquals( 'Sixpack TEST territory', wo.ServiceTerritory.Name, 'Test territory assignment' );
        system.assertEquals( 'Sixpack TEST', wo.Owner.LastName, 'Test owner assignment' );
        system.assertEquals( anAsset.Field_Service_Manager__c, wo.Field_Service_Manager__c, 'Test FSM assignment' );
    }

    public static TestMethod void multipleWorkOrdersTest() {
        Test.startTest();

        // create/query objects to test
        Account testAccount = [
                SELECT ID
                FROM Account
                WHERE Name LIKE 'Company Test One%'
                LIMIT 1
        ];

        ServiceTerritory aTerritory = [
                SELECT ID
                FROM ServiceTerritory
                WHERE Name = 'Sixpack TEST territory'
                LIMIT 1
        ];

        WorkType wt = new WorkType();
        wt.Name = 'Standard';
        wt.EstimatedDuration = 1;
        wt.DurationType = 'Hours';
        insert wt;

        List<WorkOrder> woList = new List<WorkOrder>();

        WorkOrder wo = new WorkOrder();
        wo.AccountId = testAccount.ID;
        wo.Street = '3109 MAYSILLEE STREETPULTE AUSTIN PRESTON PARK';
        wo.City = 'AUSTIN';
        wo.PostalCode = '78728';
        wo.StateCode = 'TX';
        wo.StartDate = Date.today().addMonths( -1 );
        wo.EndDate = Date.today().addMonths( -1 );
        wo.WorkTypeId = wt.ID;
        wo.ServiceTerritoryId = aTerritory.ID;
        wo.ERP_Order_Number__c = 'AU056587';
        // existing asset 'TEST123'
        wo.Billing_Group__c = 'TEST123'; // new billing group 'FLR_BLD_RFMS:155852';
        wo.Integration_Key_Work_Order__c = 'FLR_BLD_RFMS:1205957';
        wo.PO_Number__c = '4';
        wo.PrimaryIdentifier__c = '3109 MAYSILLEE STREET';
        wo.ScheduledCrewId__c = 'FLR_BLD_RFMS:529';
        wo.Job_Type__c = 'TILE_WALL';
        wo.Scheduled_Crew_Name__c = '529 - JOSE SANCHEZ TAMAYO';
        wo.Start_Day__c = Date.today().addMonths( -1 );
        wo.Job_End_Day__c = wo.Start_Day__c;
        woList.add( wo );

        WorkOrder wo1 = wo.clone( false );
        wo1.ERP_Order_Number__c = 'AU056588';
        wo1.Integration_Key_Work_Order__c = 'FLR_BLD_RFMS:1205956';
        wo1.Job_Type__c = 'TILE_FLOOR';
        woList.add( wo1 );

        WorkOrder wo2 = wo.clone( false );
        wo2.ERP_Order_Number__c = 'AU056589';
        wo2.Integration_Key_Work_Order__c = 'FLR_BLD_RFMS:1205955';
        wo2.Job_Type__c = 'TILE_BACKSPLASH';
        woList.add( wo2 );

        insert woList;

        // update same records expecting the asset will not be created again
        SG_WorkOrderHelper.recordIdsAlreadyProcessedOnCreateSet = new Set<ID>();
        update woList;

        SG_BatchAssetWorkOrderControl.runMe();

        Test.stopTest();

        wo = [
                SELECT ID, ServiceTerritoryId, ServiceTerritory.Name
                        , OwnerID, Owner.LastName, Field_Service_Manager__c
                        , Job_Type__c, Start_Day__c, Job_End_Day__c
                        , ServiceAppointmentID__c, AssetID
                FROM WorkOrder
                WHERE ID = :wo.ID
        ];

        system.assert( wo.AssetID != null, 'Test new asset for WO' );
        //system.assert( wo.AssetID == null, 'Test new asset for WO' );
    }

    public static TestMethod void updateWorkOrderTest() {
        Test.startTest();

        // create/query objects to test
        Account installer = [
                SELECT ID
                FROM Account
                WHERE Name LIKE 'Installer%'
                LIMIT 1
        ];

        Community__c aCommunity = [
                SELECT ID, EntityIntegration__c
                FROM Community__c
                LIMIT 1
        ];

        Asset anAsset = [
                SELECT ID, Field_Service_Manager__c, AccountID
                        , Field_Service_Manager_Territory_ID__c
                        , Integration_Key_Billing_Group__c, PrimaryIdentifier__c
                FROM Asset
                WHERE Name = '1313 Mockingbird'
                LIMIT 1
        ];

        // fetch territory in test context
        ServiceTerritory aTerritory = [
                SELECT ID, Name
                FROM ServiceTerritory
                LIMIT 1
        ];

        // make trigger use the territory as default
        SG_WorkOrderHelper.DEFAULT_TERRITORY_ID = aTerritory.ID;

        ID standardAccountRTID = Schema.SObjectType.Account.getRecordTypeInfosByName().get( 'Standard' ).getRecordTypeId();

        Account a = [
                SELECT ID
                FROM Account
                WHERE Name = 'Company Test One'
                AND RecordTypeId = :standardAccountRTID
                LIMIT 1
        ];

        WorkOrder wo = new WorkOrder();
        wo.AccountId = a.ID;
        wo.Installer_Account__c = installer.ID;
        wo.Job_Type__c = 'QC Pre-Walk';
        wo.Start_Day__c = Date.today().addDays( 1 );
        wo.Job_End_Day__c = Date.today().addDays( 3 );
        wo.Billing_Group__c = aCommunity.EntityIntegration__c + 'TEST432';//anAsset.Integration_Key_Billing_Group__c;

        system.debug( 'creating WO= ' + wo );
        insert wo;
        system.debug( 'created WO= ' + wo );

        wo.Field_Service_Manager__c = anAsset.Field_Service_Manager__c;
        update wo;

        Test.stopTest();

        //wo = [
        //        SELECT ID, ServiceTerritoryId, ServiceTerritory.Name
        //                , OwnerID, Owner.LastName, Field_Service_Manager__c
        //                , Job_Type__c, Start_Day__c, Job_End_Day__c
        //                , ServiceAppointmentID__c, AssetID
        //        FROM WorkOrder
        //        WHERE ID = :wo.ID
        //];
//
        //system.assert( wo.AssetID != null, 'Test new asset for WO' );
    }

    public static TestMethod void deleteTest() {
        Test.startTest();

        // create/query objects to test
        Account installer = [
                SELECT ID
                FROM Account
                WHERE Name LIKE 'Installer%'
                LIMIT 1
        ];

        Asset anAsset = [
                SELECT ID, Field_Service_Manager__c, AccountID, Community__c
                        , Field_Service_Manager_Territory_ID__c
                FROM Asset
                WHERE Name = '1313 Mockingbird'
                LIMIT 1
        ];

        system.assert( anAsset.Field_Service_Manager_Territory_ID__c != null, 'Asset has FSM territory' );

        WorkOrder wo = new WorkOrder();
        wo.AssetId = anAsset.ID;
        wo.Installer_Account__c = installer.ID;
        wo.Job_Type__c = 'QC Pre-Walk';
        wo.Start_Day__c = Date.today().addDays( 1 );
        wo.Job_End_Day__c = Date.today().addDays( 3 );
        insert wo;

        Test.stopTest();

        Quality_Control__c qc = [
                SELECT ID, RecordTypeId, House_Unit__c
                FROM Quality_Control__c
                WHERE Work_Order__c = :wo.ID
                LIMIT 1
        ];

        String recTypeID = SG_WorkOrderHelper.jobTypeToQCRecordTypeIDMap.get( wo.Job_Type__c.toUpperCase() );

        system.assertEquals( anAsset.ID, qc.House_Unit__c, 'Test QC record asset' );
        system.assertEquals( recTypeID, qc.RecordTypeId, 'Test QC record asset' );

        delete wo;

        List<Quality_Control__c> qcList = [
                SELECT ID
                FROM Quality_Control__c
                WHERE ID = :qc.ID
        ];

        system.assertEquals( 0, qcList.size(), 'Test QC record deleted' );

    }

    public static TestMethod void assignCommunityTest() {
        Test.startTest();

        // create/query objects to test
        Account installer = [
                SELECT ID
                FROM Account
                WHERE Name LIKE 'Installer%'
                LIMIT 1
        ];

        Community__c aCommunity = [
                SELECT ID, Name, EntityIntegration__c
                FROM Community__c
                LIMIT 1
        ];

        Asset anAsset = [
                SELECT ID, Field_Service_Manager__c, AccountID
                        , Field_Service_Manager_Territory_ID__c
                        , Integration_Key_Billing_Group__c, PrimaryIdentifier__c, Community__c
                FROM Asset
                WHERE Name = '1313 Mockingbird'
                LIMIT 1
        ];

        system.assert( anAsset.Field_Service_Manager_Territory_ID__c != null, 'Asset has FSM territory' );

        // expect match asset by billing group
        WorkOrder wo = new WorkOrder();
        wo.Installer_Account__c = installer.ID;
        wo.Job_Type__c = 'QC Pre-Walk';
        wo.Start_Day__c = Date.today().addDays( 1 );
        wo.Job_End_Day__c = Date.today().addDays( 3 );
        wo.Billing_Group__c = anAsset.Integration_Key_Billing_Group__c + 'XYZ'; // new house
        wo.CommunityNameERP__c = aCommunity.Name;   // match by comm name ERP
        
        system.debug( 'test work order= '+ wo );
        insert wo;

        SG_BatchAssetWorkOrderControl.runMe();

        Test.stopTest();

        wo = [
                SELECT ID, AssetID, Asset.Community__c
                FROM WorkOrder
                WHERE ID = :wo.ID
        ];
		
        //system.assertEquals( aCommunity.ID, wo.Asset.Community__c, 'Test assignment of community' );
        system.assertEquals(aCommunity.ID, anAsset.Community__c, 'Test assignment of community');
    }

//
//    public static TestMethod void createQCByCommunityTest() {
//        Test.startTest();
//
//        // create/query objects to test
//        Account a = [
//                SELECT ID
//                FROM Account
//                WHERE Name LIKE 'Company Test One%'
//                LIMIT 1
//        ];
//
//        ID installerRTID = Schema.SObjectType.Account.getRecordTypeInfosByName().get( 'Installer Company' ).getRecordTypeId();
//        Account installer = [
//                SELECT ID
//                FROM Account
//                WHERE RecordTypeID = :installerRTID
//                LIMIT 1
//        ];
//
//        Community__c aCommunity = new Community__c();
//        aCommunity.Name = 'Someone\'s community';
//        aCommunity.EntityIntegration__c = 'DEF_432:';
//        aCommunity.QC_Wood_Install__c = 'Yes';
//        insert aCommunity;
//
//        //aCommunity = [
//        //        SELECT ID, Name, Field_Service_Manager__c
//        //                , Field_Service_Manager__r.Territory_ID__c
//        //        FROM Community__c
//        //        WHERE ID = :aCommunity.ID
//        //];
//        system.debug( 'created aCommunity= ' + aCommunity );
//
//        Asset anAsset = new Asset();
//        anAsset.Name = '1313 Mockingbird';
//        anAsset.Lot_Block__c = '1313 Mockingbird';
//        anAsset.AccountID = a.ID;
//        anAsset.Community__c = aCommunity.ID;
//        anAsset.Status = 'Pre-Start';
//        anAsset.Integration_Key_Billing_Group__c = '321TEST';
//        anAsset.PrimaryIdentifier__c = 'ID-321TEST';
//        insert anAsset;
//
//        //anAsset = [
//        //        SELECT ID, Name, Field_Service_Manager_Territory_ID__c, Field_Service_Manager__c
//        //                , Field_Service_Manager__r.Territory_ID__c
//        //        FROM Asset
//        //        WHERE ID = :anAsset.ID
//        //];
//        system.debug( 'created anAsset= ' + anAsset );
//
//        WorkOrder wo = new WorkOrder();
//        wo.AssetId = anAsset.ID;
//        wo.Installer_Account__c = installer.ID;
//        wo.Job_Type__c = 'Wood';
//        wo.Start_Day__c = Date.today().addDays( 1 );
//        wo.Job_End_Day__c = Date.today().addDays( 3 );
//        //wo.PrimaryIdentifier__c = anAsset.PrimaryIdentifier__c;
//        wo.Billing_Group__c = anAsset.Integration_Key_Billing_Group__c;
//
//        system.debug( 'creating WO= ' + wo );
//        insert wo;
//        system.debug( 'created WO= ' + wo );
//
//        Test.stopTest();
//
//        wo = [
//                SELECT ID, ServiceTerritoryId, ServiceTerritory.Name
//                        , OwnerID, Owner.LastName, Field_Service_Manager__c
//                        , Job_Type__c, Start_Day__c, Job_End_Day__c, Community__c
//                FROM WorkOrder
//                WHERE ID = :wo.ID
//        ];
//        system.assertEquals( anAsset.Community__c, wo.Community__c, 'Test community assignment' );
//
//        Quality_Control__c qc = [
//                SELECT ID, RecordTypeId, House_Unit__c
//                FROM Quality_Control__c
//                WHERE Work_Order__c = :wo.ID
//                LIMIT 1
//        ];
//
//        String recTypeID = SG_WorkOrderHelper.jobTypeToQCRecordTypeIDMap.get( wo.Job_Type__c.toUpperCase() );
//
//        system.assertEquals( anAsset.ID, qc.House_Unit__c, 'Test QC record asset' );
//        system.assertEquals( recTypeID, qc.RecordTypeId, 'Test QC record asset' );
//    }

    public static TestMethod void workOrderCreateANDAssignHouseTest() {
        Test.startTest();

        // create/query objects to test
        Account installer = [
                SELECT ID
                FROM Account
                WHERE Name LIKE 'Installer%'
                LIMIT 1
        ];

        Community__c aCommunity = [
                SELECT ID, EntityIntegration__c
                FROM Community__c
                LIMIT 1
        ];



        ID standardAccountRTID = Schema.SObjectType.Account.getRecordTypeInfosByName().get( 'Standard' ).getRecordTypeId();

        Account a = [
                SELECT ID
                FROM Account
                WHERE Name = 'Company Test One'
                AND RecordTypeId = :standardAccountRTID
                LIMIT 1
        ];

        WorkOrder wo = new WorkOrder();
        wo.AccountId = a.ID;
        wo.Installer_Account__c = installer.ID;
        wo.Job_Type__c = 'QC Pre-Walk';
        wo.Start_Day__c = Date.today().addDays( 1 );
        wo.Job_End_Day__c = Date.today().addDays( 3 );
        wo.Billing_Group__c = aCommunity.EntityIntegration__c + 'TEST123';
        system.debug( 'creating WO= ' + wo );
        insert wo;
        system.debug( 'created WO= ' + wo );

        SG_BatchAssetWorkOrderControl.runMe();

        Test.stopTest();

        wo = [
                SELECT ID, ServiceTerritoryId, ServiceTerritory.Name
                        , OwnerID, Owner.LastName, Field_Service_Manager__c
                        , Job_Type__c, Start_Day__c, Job_End_Day__c
                        , ServiceAppointmentID__c, AssetID
                FROM WorkOrder
                WHERE ID = :wo.ID
        ];

        system.assert( wo.AssetID != null, 'Test new asset for WO' );
    }

    public static TestMethod void workOrderUpdateDeleteQCApptTest() {
        Test.startTest();

        // create/query objects to test
        Account installer = [
                SELECT ID
                FROM Account
                WHERE Name LIKE 'Installer%'
                LIMIT 1
        ];

        Community__c aCommunity = [
                SELECT ID, EntityIntegration__c
                FROM Community__c
                LIMIT 1
        ];

        ID standardAccountRTID = Schema.SObjectType.Account.getRecordTypeInfosByName().get( 'Standard' ).getRecordTypeId();

        Account a = [
                SELECT ID
                FROM Account
                WHERE Name = 'Company Test One'
                AND RecordTypeId = :standardAccountRTID
                LIMIT 1
        ];

        Asset anAsset = [
                SELECT ID, Field_Service_Manager__c, AccountID
                        , Field_Service_Manager_Territory_ID__c
                        , Integration_Key_Billing_Group__c, PrimaryIdentifier__c
                FROM Asset
                WHERE Name = '1313 Mockingbird'
                LIMIT 1
        ];

        WorkOrder wo = new WorkOrder();
        wo.AccountId = a.ID;
        wo.Installer_Account__c = installer.ID;
        wo.Job_Type__c = 'QC Pre-Walk';
        wo.Start_Day__c = Date.today().addDays( 1 );
        wo.Job_End_Day__c = Date.today().addDays( 3 );
        wo.Billing_Group__c = anAsset.Integration_Key_Billing_Group__c; //aCommunity.EntityIntegration__c + 'TEST123';

        insert wo;

        system.debug( 'created WO= ' + wo );

        String qcRecTypeID = Schema.SObjectType.Quality_Control__c.getRecordTypeInfosByName().get( 'Pre-Walk' ).getRecordTypeId();
        Quality_Control__c qc = SG_WorkOrderHelper.createQualityControl( anAsset.Id, qcRecTypeID, wo.ID );
        insert qc;

        List<ServiceAppointment> spList = [
                SELECT ID
                FROM ServiceAppointment
                WHERE Work_Order__c = :wo.ID
                    AND Status <> :SG_WorkOrderHelper.CANCELLED_APPOINTMENT
        ];

        system.assertEquals( 1, spList.size(), 'Svc Appt created' );

        wo.Start_Day__c = null;
        update wo;

        List<Quality_Control__c> qcList = [
                SELECT ID
                FROM Quality_Control__c
                WHERE Work_Order__c = :wo.ID
        ];

        system.assertEquals( 0, qcList.size(), 'QC deleted' );

        spList = [
                SELECT ID
                FROM ServiceAppointment
                WHERE Work_Order__c = :wo.ID
                    AND Status = :SG_WorkOrderHelper.CANCELLED_APPOINTMENT
        ];

        system.assertEquals( 1, spList.size(), 'Svc Appt cancelled' );

        Test.stopTest();
    }
}