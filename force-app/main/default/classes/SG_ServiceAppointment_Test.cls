/***************************************************
* Name:         SG_ServiceAppointment_Test
* Author:       Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date:         27 May 2020
* ==================================================
* ==================================================
* Purpose:      ...
*
* ==================================================
* ==================================================
* History:
* VERSION   DATE            INITIALS    DESCRIPTION/FEATURES ADDED
* 1.0       27 May 2020     FMF     Initial Development
* 
****************************************************/

@isTest
public with sharing class SG_ServiceAppointment_Test {
    @TestSetup
    public static void setupData() {
        SG_WorkOrderHelper_Test.createDataForFSL();
    }

    public static TestMethod void myUnitTest() {
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
        system.debug( 'creating work order= ' + wo );
        insert wo;

        Test.stopTest();

        AssignedResource ar = [
                SELECT ID, ServiceAppointmentID, ServiceAppointment.Work_Order__c
                    , ServiceResourceID
                FROM AssignedResource
                WHERE ServiceAppointment.Work_Order__c = :wo.ID
                LIMIT 1
        ];

        System.assert( ar.ServiceAppointmentId != null, 'Test assigned resource creation' );
        System.assertEquals( anAsset.Field_Service_Manager__c, ar.ServiceResourceID, 'Test assigned resource creation' );

        wo = [
                SELECT ID, ServiceTerritoryId, ServiceTerritory.Name
                        , OwnerID, Owner.LastName, Field_Service_Manager__c
                        , Job_Type__c, Start_Day__c, Job_End_Day__c
                        , ServiceAppointmentID__c
                FROM WorkOrder
                WHERE ID = :wo.ID
        ];

        System.assertEquals( ar.ServiceAppointmentId, wo.ServiceAppointmentID__c, 'Test assigned resource creation' );
        system.assert( wo.ServiceAppointmentID__c != null, 'Test appt was created/linked ' + wo.ServiceAppointmentID__c );
    }
}