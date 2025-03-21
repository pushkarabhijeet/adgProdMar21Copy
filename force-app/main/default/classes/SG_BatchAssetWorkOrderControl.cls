/***************************************************
* Name:         SG_BatchAssetWorkOrderControl
* Author:       Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date:         29 Jul 2020
* ==================================================
* ==================================================
* Purpose:      ...
*
* ==================================================
* ==================================================
* History:
* VERSION   DATE            INITIALS    DESCRIPTION/FEATURES ADDED
* 1.0       29 Jul 2020     FMF     Initial Development
* 
****************************************************/

global class SG_BatchAssetWorkOrderControl extends SG_GenericBatchApex  {

    public static final String jobName = 'SGI - Batch Asset/Work Order Control';
    public static final String DEFAULT_SCHEDULE = '0 10 * * * ?'; // every 10 minutes
    public static String additionalCriteria = '';

    global override void initialize() {
        //System.debug( 'SG_BatchAssetWorkOrderControl initialize' );

        theQuery = 'SELECT ID, AccountId, Billing_Group__c, PrimaryIdentifier__c '
                    + ' , Street, City, State, PostalCode, Record_Type_Developer_Name__c '
                    + ' , Job_Type__c, Start_Day__c, Field_Service_Manager_ID_formula__c '
                    + ' , Field_Service_Manager__c, ServiceAppointmentID__c, Job_End_Day__c '
                    + ' , Due_Date_for_svc_appt__c, OrphanedCommunityCode__c '
                    + ' , WorkOrder.OwnerId, WorkOrder.AssetId, Community__c '
                    + ' , CommunityNameERP__c, Job_Number__c, Account_Location__c  '
                    + ' FROM WorkOrder '
                    + ' WHERE ( AssetId = null OR Community__c = null ) '
                    + additionalCriteria;

        //System.debug( 'theQuery= ' + theQuery );
    }

    global override void processRecords( List<SObject> scope ) {
        //System.debug( 'SG_BatchAssetWorkOrderControl processRecords - scope= ' + scope );

        List<WorkOrder> workOrderList = (List<WorkOrder>) scope;

        SG_WorkOrderHelper.assignAssetsToWorkOrders( workOrderList );
    }

    global static ID runMe() {
        //System.debug( 'SG_BatchAssetWorkOrderControl runMe' );
        SG_BatchAssetWorkOrderControl batchProcess = new SG_BatchAssetWorkOrderControl();

        return Database.executeBatch( batchProcess, batchProcess.BatchSize );
    }

    global override void execute( SchedulableContext sc ) {
        //System.debug( 'SG_BatchAssetWorkOrderControl execute' );
        batchID = SG_BatchAssetWorkOrderControl.runMe();
    }

    global override void finish( Database.BatchableContext bc ) {
        //System.debug( 'SG_BatchAssetWorkOrderControl finish' );

        // assign community owners to related assets
        syncAssetOwnershipWithCommunity();

        // delete orphaned QC records without work orders
        deleteOrphanedQualityControlRecords();
    }

    public static void deleteOrphanedQualityControlRecords() {
        List<Quality_Control__c> qcList = [
                SELECT ID
                FROM Quality_Control__c
                WHERE Work_Order__c = null
        ];

        if( !qcList.isEmpty() ) {
            delete qcList;
        }
    }

    public static void syncAssetOwnershipWithCommunity() {
        List<Asset> assetList = [
                SELECT ID, Community__r.OwnerID, OwnerID
                FROM Asset
                WHERE Owner.Name LIKE '%Integration%'
        ];

        List<Asset> assetsToUpdateList = new List<Asset>();
        for( Asset aHouse : assetList ) {
            if( aHouse.OwnerID != aHouse.Community__r.OwnerID
                            && aHouse.Community__r.OwnerID != null ) {
                aHouse.OwnerID = aHouse.Community__r.OwnerID;
                assetsToUpdateList.add( aHouse );
            }
        }

        if( ! assetsToUpdateList.isEmpty() ) {
            update assetsToUpdateList;
        }
    }

    global static void scheduleEveryXMin( Integer minutes ) {
        //System.debug( 'SG_BatchAssetWorkOrderControl scheduleEvery10Min' );
        removeSchedule( jobName );

        for( Integer i = 0; i < 60; i += minutes ) {
            SG_BatchAssetWorkOrderControl.scheduleMe( jobName + ' - Minute: ' + i
                                , '0 ' + i + ' * * * ?'
                                , true );
        }

    }

    global static void scheduleMe( String aJobName, String schedTime, Boolean removeSchedule ) {
        //System.debug( 'SG_BatchAssetWorkOrderControl scheduleMe' );
        if( removeSchedule == true ) {
            removeSchedule( aJobName );
        }

        // every day at the specified hour and minute
        if( schedTime == null ) {
            schedTime = DEFAULT_SCHEDULE;
        }

        SG_BatchAssetWorkOrderControl batchProcess = new SG_BatchAssetWorkOrderControl();
        System.schedule( aJobName, schedTime, batchProcess );
    }
}