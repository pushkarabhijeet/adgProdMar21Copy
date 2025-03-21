/***************************************************
* Name:         SG_QualityControlHelper
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

public with sharing class SG_QualityControlHelper {
    public static final String BUSINESS_HOURS_ID = '01m4T0000008xMr';
    public static final String CASE_STATUS = '01 - New';
    public static final String CASE_SUBJECT = 'House needs Shower/Bath field measure';
    public static final String CASE_TYPE = 'Repair';
    public static final String COMPLETED_WORK_ORDER_STATUS = '90-Completed';
    public static final String COMPLETED_CUSTOM_STATUS = 'Completed_with_QC'; //'Completed with QC';
    public static final String MR_CASE_CREATED_FIELD_NAME = 'Most_Recent_Case_Created__c';
    public static final String COMPLETED_STATUS_QC = 'Completed';
    public static final String DEFAULT_PICKLIST_VALUE = 'Please select a value';

    public static Set<ID> recordIdsAlreadyProcessedSet = new Set<ID>();
    public static Set<ID> recordIdsAlreadyAssignedCaseSet = new Set<ID>();
    public static Set<ID> recordIdsAlreadyUpdatedWorkOrderSet = new Set<ID>();

    public static Boolean hasSetFileNames = false;
    public static Boolean hasDoneQcRollups = false;

    public static Boolean isNotBeforeInsertOrUpdate( TriggerOperation operationType ) {
        system.debug( 'operationType= ' + operationType );
        return operationType != TriggerOperation.BEFORE_INSERT
                && operationType != TriggerOperation.BEFORE_UPDATE;
    }

    public static ID preWalkRecordTypeID {
        get {
            if( preWalkRecordTypeID == null ) {
                preWalkRecordTypeID = Schema.SObjectType.Quality_Control__c.getRecordTypeInfosByDeveloperName().get( 'Pre_Walk' ).getRecordTypeId();
            }
            return preWalkRecordTypeID;
        }
        set;
    }

    public static List<Quality_Control_Trigger_Case_Creation__mdt> qcConfigList {
        get {
            if( qcConfigList == null ) {
                qcConfigList = [
                        SELECT ID, DeveloperName, MasterLabel
                                , QC_Field_Name_to_Verify__c, QC_Field_Value__c
                                , QC_Field_Name_for_Material_Option__c
                                , Case_Material_If_Yes__c, Case_Material_If_No__c
                                , List_of_QC_Record_Types__c
                                , Case_Subject__c, Case_Type__c
                        FROM Quality_Control_Trigger_Case_Creation__mdt
                ];
            }
            return qcConfigList;
        }
        set;
    }

    // lazy loading record types
    public static Map<ID, Schema.RecordTypeInfo> rtMapByName {
        get {
            if( rtMapByName == null ) {
                Schema.DescribeSObjectResult dsor = Schema.SObjectType.Quality_Control__c;
                rtMapByName = dsor.getRecordTypeInfosById();
            }

            return rtMapByName;
        }
        set;
    }


    // there could be multiple images attached to a QC; we need to know what a picture is (Garage Area, Backsplash damage, etc)
    // when an image is uploaded, a hidden input field contains the image file names for each type -- find all the images
    // that are stored in the hidden field, then rename the image to something meaningful
    public static void setFileNames(System.TriggerOperation triggerEvent, List<Quality_Control__c> newQcs, Map<Id, Quality_Control__c> oldQcs)
    {
        System.debug(LoggingLevel.WARN, '---> start setFileNames');
        // set the enum of allowed trigger operations (before insert, after update, etc)
        List<TriggerOperation> triggerTypes = new List<TriggerOperation>{
                TriggerOperation.AFTER_INSERT
                , TriggerOperation.AFTER_UPDATE
        };
        if ( !SG_DisplayUtils.canFireTrigger( triggerEvent, triggerTypes, hasSetFileNames ) )
        {
            System.debug(LoggingLevel.WARN, '---> already hasSetFileNames: ' + hasSetFileNames + ' or wrong trigger type; skip');
            return;
        }

        // prevents recursive triggers
        hasSetFileNames = true;

        String keyPrefix = Quality_Control__c.sObjectType.getDescribe().getKeyPrefix();
        Map<Id, Set<Id>> entityToDocIdsMap = new Map<Id, Set<Id>>();
        List<ContentDocument> upsertDocs = new List<ContentDocument>();
        Set<Id> allDocIds = new Set<Id>();

        System.debug(LoggingLevel.WARN, '---> keyPrefix: ' + keyPrefix);

        if ( newQcs != null && newQcs.size() > 0 )
        {
            // build maps; a QC Map, and a pairing of QC : Asset
            Map<Id, Quality_Control__c> qcMap = new Map<Id, Quality_Control__c>();
            Map<Id, Id> qcToHouseholdId = new Map<Id, Id>();
            for ( Quality_Control__c qc : newQcs )
            {
                qcMap.put( qc.Id, qc );
                qcToHouseholdId.put( qc.Id, qc.House_Unit__c );
                System.debug(LoggingLevel.WARN, '---> qc work order: ' + qc.Work_Order__c);
            }

            // loop over ALL files related to our QCs
            // build a map of QC : List<Files>
            for ( ContentDocumentLink cdl : [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :qcMap.keySet()] )
            {
                System.debug(LoggingLevel.WARN, '---> cdl: ' + cdl );

                // let's just double check it's really tied to a QC...
                String type = String.valueOf( cdl.LinkedEntityId.getSobjectType() );

                if ( type == 'Quality_Control__c' )
                {
                    System.debug(LoggingLevel.WARN, '---> QC file!');

                    Set<Id> tmpSet = entityToDocIdsMap.get( cdl.LinkedEntityId );
                    if ( tmpSet == null ) tmpSet = new Set<Id>();
                    tmpSet.add( cdl.ContentDocumentId );
                    entityToDocIdsMap.put( cdl.LinkedEntityId, tmpSet );

                    allDocIds.add( cdl.ContentDocumentId );
                }
            }


            System.debug(LoggingLevel.WARN, '---> entityToDocIdsMap: ' + entityToDocIdsMap);
            // get the documents...
            if ( entityToDocIdsMap != null && entityToDocIdsMap.keySet().size() > 0 && allDocIds != null )
            {
                Map<Id, ContentDocument> docMap = new Map<Id, ContentDocument>([SELECT Id, Title FROM ContentDocument WHERE Id IN :allDocIds]);
                Map<Id, RecordType> rtMap = new Map<Id, RecordType>([SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Quality_Control__c']);
                System.debug(LoggingLevel.WARN, '---> found record types for QC: ' + rtMap );

                // loop over all our QCs, and rename any File whose name is contained in the hidden pic fields
                for ( Id entityId : entityToDocIdsMap.keySet() )
                {
                    Quality_Control__c qc = qcMap.get( entityId );
                    Set<Id> docIds = entityToDocIdsMap.get( entityId );
                    System.debug(LoggingLevel.WARN, '---> looping docs for entity; entityId: ' + entityId + ' docIds: ' + docIds );
                    if ( qc != null && docIds != null )
                    {
                       // Integer ctr = 1;
                        RecordType rt;
                        String rtName = 'File';
                        if ( qc.RecordTypeId != null )
                        {
                            rt = rtMap.get( qc.RecordTypeId );
                            if ( rt != null ) rtName = rt.DeveloperName;
                        }
                        System.debug(LoggingLevel.WARN, '---> QC rt name: ' + rtName );

                        // read a Field Set for all of our hidden picture fields and loop over that to rename everything...
                        List<Schema.FieldSetMember> pictureFieldNames = SG_SchemaUtils.getFieldSetMembers( 'Picture_Upload_Fields', 'Quality_Control__c');
                        if ( pictureFieldNames != null && pictureFieldNames.size() > 0 )
                        {
                            // loop over all of our hidden picture fields and see if they contain any image names
                            for ( Schema.FieldSetMember field : pictureFieldNames )
                            {
                                System.debug(LoggingLevel.WARN, '---> looping potential field of picture names: ' + field.getFieldPath() );
                                String photoPrefix = '_' + field.getFieldPath() + '_';
                                photoPrefix = photoPrefix.replace('__c', '' );

                                Set<String> fieldStrs = getImagesFromHiddenField( qc, field.getFieldPath() ); // returns lower-case file name!!
                                // for EVERY doc that is tied to the QC, see if it's name is contained in this hidden pic field
                                for ( Id docId : docIds )
                                {
                                    ContentDocument doc = docMap.get( docId );
                                    String title = doc.Title;
                                    title = getStrippedName( title );
                                    System.debug(LoggingLevel.WARN, '---> seeing if ' + field.getFieldPath() + ' contains this doc: ' + title );
                                    if ( fieldStrs.contains( title ))
                                    {
                                        System.debug(LoggingLevel.WARN, '---> found this file in the field!');
                                        doc.Title = rtName + photoPrefix + title;
                                        upsertDocs.add( doc );
                                       // ctr++;
                                    }
                                }

                            }
                        }
                    }
                }
                System.debug(LoggingLevel.WARN, '---> upsertDocs: ' + upsertDocs );

                if ( upsertDocs != null && upsertDocs.size() > 0 )
                {
                    try
                    {
                        upsert upsertDocs;
                    }
                    catch (Exception e )
                    {
                        System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );
                    }
                }

            }
        }

    }

    public static Set<String> getImagesFromHiddenField( Quality_Control__c qc, String fieldApiName)
    {
        System.debug(LoggingLevel.WARN, '---> getting pic files for field: ' + fieldApiName);
        Set<String> fieldStrs;
        if ( fieldApiName != null )
        {
            try
            {
                String fieldVal = (String)qc.get(fieldApiName);
                System.debug(LoggingLevel.WARN, '---> contents of the hidden field: ' + fieldVal );
                fieldVal = getStrippedName( fieldVal );

                /*if ( String.isNotBlank( fieldVal ))
                {
                    // strip out some extensions
                    fieldVal = fieldVal.toLowerCase().replace( '.jpg', '' );
                    fieldVal = fieldVal.toLowerCase().replace( '.jpeg', '' );
                    fieldVal = fieldVal.toLowerCase().replace( '.png', '' );
                    fieldVal = fieldVal.toLowerCase().replace( '.txt', '' );
                    fieldVal = fieldVal.toLowerCase().replace( '.pdf', '' );
                    fieldVal = fieldVal.toLowerCase().replace( '.gif', '' );
                    fieldVal = fieldVal.toLowerCase().replace( '.mov', '' );
                    fieldVal = fieldVal.toLowerCase().replace( '.mp4', '' );
                    fieldVal = fieldVal.toLowerCase().replace( '.mov', '' );
                }*/

                fieldStrs = SG_DisplayUtils.parseIncomingStringIntoSet( fieldVal );

            }
            catch( Exception e )
            {
                System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );
            }

        }
        System.debug(LoggingLevel.WARN, '---> found image file names for field (' + fieldApiName + '): ' + fieldStrs );
        return fieldStrs;

    }

    public static String getStrippedName(String fieldVal )
    {
        if ( String.isNotBlank( fieldVal ))
        {
            // strip out some extensions
            fieldVal = fieldVal.toLowerCase().replace( '.jpg', '' );
            fieldVal = fieldVal.toLowerCase().replace( '.jpeg', '' );
            fieldVal = fieldVal.toLowerCase().replace( '.png', '' );
            fieldVal = fieldVal.toLowerCase().replace( '.txt', '' );
            fieldVal = fieldVal.toLowerCase().replace( '.pdf', '' );
            fieldVal = fieldVal.toLowerCase().replace( '.gif', '' );
            fieldVal = fieldVal.toLowerCase().replace( '.mov', '' );
            fieldVal = fieldVal.toLowerCase().replace( '.mp4', '' );
            fieldVal = fieldVal.toLowerCase().replace( '.mov', '' );
        }
        return fieldVal;
    }

    public static List<String> picklistFieldList {
        get {
            if( picklistFieldList == null ) {
                picklistFieldList = new List<String>();
                Schema.DescribeSObjectResult dsr = Quality_Control__c.sObjectType.getDescribe();

                // get list of fields for Quality_Control__c
                Map<String, Schema.SObjectField> fieldMap = dsr.fields.getMap();

                // collect only picklist fields
                for( String aKey : fieldMap.keySet() ) {
                    // skip non-updateable fields and non-picklists and picklists that are restricted
                    Schema.DescribeFieldResult dfr = fieldMap.get( aKey ).getDescribe();
                    DisplayType dt = dfr.getType();
                    if( ! dfr.isUpdateable()
                            || ( dt != DisplayType.PICKLIST && dt != DisplayType.MULTIPICKLIST )
                            || dfr.isRestrictedPicklist() ) {
                        continue;
                    }

                    // collect picklist name
                    String fieldName = dfr.getName();
                    picklistFieldList.add( fieldName );
                }
            }
            system.debug( 'picklistFieldList= ' + picklistFieldList );
            return picklistFieldList;
        }
        set;
    }

    public static void populatePicklists( TriggerOperation operationType, List<SObject> newList
            , Map<ID, SObject> oldMap ) {

        if( SG_QualityControlHelper.isNotBeforeInsertOrUpdate( operationType ) ) {
            return;
        }

        // populate all non-null picklists
        for( SObject sobj : newList ) {
            for( String picklistName : picklistFieldList ) {
                if( sobj.get( picklistName ) != null ) {
                    continue;
                }

                sobj.put( picklistName, DEFAULT_PICKLIST_VALUE );
            }
        }
    }

    public static void createCase( TriggerOperation operationType, List<SObject> newList
            , Map<ID, SObject> oldMap ) {

        //// only after inserts/updates
        //if( operationType != TriggerOperation.AFTER_INSERT
        //        && operationType != TriggerOperation.AFTER_UPDATE ) {
        //    return;
        //}


        if( SG_QualityControlHelper.isNotBeforeInsertOrUpdate( operationType ) ) {
            return;
        }

        // create case with default values to be cloned when generating new cases
        Case templateCase = new Case();
        templateCase.BusinessHoursId = BUSINESS_HOURS_ID;
        templateCase.Status = CASE_STATUS;
        templateCase.Subject = CASE_SUBJECT;
        templateCase.Type = CASE_TYPE;

        // create cases for pre-walk whose shower bath need measure
        List<Case> caseList = new List<Case>();
        Map<SObject, Case> caseByQCMap = new Map<SObject, Case>();
        for( SObject sobj : newList ) {
            if (recordIdsAlreadyProcessedSet.contains(sobj.ID)) {
                continue;
            }
            recordIdsAlreadyProcessedSet.add(sobj.ID);

            ID rtID = (ID) sobj.get('RecordTypeId');
            RecordTypeInfo QCRecType = rtMapByName.get( rtID );
            if( QCRecType == null ) {
                continue;
            }

            String recTypeNName = QCRecType.getDeveloperName();

            // check each of the config rules

            for ( Quality_Control_Trigger_Case_Creation__mdt qcConfig : qcConfigList ) {
                // skip if rec type is not matching
                if (qcConfig.QC_Field_Name_to_Verify__c == null
                        || qcConfig.List_of_QC_Record_Types__c == null
                        || !qcConfig.List_of_QC_Record_Types__c.contains(recTypeNName)) {
                    continue;
                }

                // skip if field value hasn't changed or doesn't match
                Quality_Control__c oldQualityControl = oldMap != null ? (Quality_Control__c) oldMap.get(sobj.ID) : null;
                String oldFieldValue = oldQualityControl != null ? (String) oldQualityControl.get(qcConfig.QC_Field_Name_to_Verify__c) : null;
                String newFieldValue = (String) sobj.get(qcConfig.QC_Field_Name_to_Verify__c);
                if (oldFieldValue == newFieldValue || newFieldValue != qcConfig.QC_Field_Value__c) {
                    continue;
                }

                // create a case using config data
                ID workOrderID = (ID) sobj.get('Work_Order__c');
                Case aCase = templateCase.clone(false);
                aCase.AssetId = (ID) sobj.get('House_Unit__c');
                aCase.Originating_QC__c = sobj.ID;
                aCase.Originating_Work_Order__c = workOrderID;
                aCase.Status = CASE_STATUS;
                aCase.Subject = qcConfig.Case_Subject__c;
                aCase.Type = qcConfig.Case_Type__c;

                // determine what value case material should have
                if (qcConfig.QC_Field_Name_for_Material_Option__c != null) {
                    String materialFieldValue = (String) sobj.get(qcConfig.QC_Field_Name_for_Material_Option__c);
                    Map<String, String> materialTypeMap = new Map<String, String>{
                            'Yes' => qcConfig.Case_Material_If_Yes__c
                            , 'No' => qcConfig.Case_Material_If_No__c
                    };

                    aCase.Material__c = materialTypeMap.get(materialFieldValue);
                }

                caseList.add( aCase );
                caseByQCMap.put( sobj, aCase );
            }
        }


        if( caseList.isEmpty() ) {
            return;
        }

        insert caseList;
        system.debug( 'caseList= ' + caseList );

        // set the case IDs on each QC record's Most_Recent_Case_Created__c
        for( SObject sobj : caseByQCMap.keySet() ) {
            Case aCase = caseByQCMap.get( sobj );
            sobj.put( 'Most_Recent_Case_Created__c', aCase.ID );
            system.debug( 'aCase.ID= ' + aCase.ID );
        }
    }

    public static void assignCase( TriggerOperation operationType, List<SObject> newList
            , Map<ID, SObject> oldMap ) {

        if( SG_QualityControlHelper.isNotBeforeInsertOrUpdate( operationType ) ) {
            return;
        }

        // collect case ids to process assignment rules
        Set<ID> recentCaseIDset = new Set<ID>();
        for( SObject sobj : newList ) {
            if( recordIdsAlreadyAssignedCaseSet.contains( sobj.ID ) ) {
                continue;
            }
            recordIdsAlreadyAssignedCaseSet.add( sobj.ID );

            if( sobj.get( MR_CASE_CREATED_FIELD_NAME ) != null ) {
                recentCaseIDset.add( (ID) sobj.get( MR_CASE_CREATED_FIELD_NAME ) );
            }
        }

        if( ! recentCaseIDset.isEmpty() ) {
            SG_CaseAssignmentRuleActivation.applyAssignmentRules( recentCaseIDset );
        }
    }

    public static void updateWorkOrder( TriggerOperation operationType, List<Quality_Control__c> newList
            , Map<ID, Quality_Control__c> oldMap ) {

        if( SG_QualityControlHelper.isNotBeforeInsertOrUpdate( operationType ) ) {
            return;
        }

        // collect work order ids related to completed QC to set their status
        // collect all work orders to update their QC count
        Set<ID> allWorkOrderIdsSet = new Set<ID>();
        Set<ID> completedWorkOrderIDset = new Set<ID>();
        Map<ID, Date> completedWorkOrderQCDateMap = new Map<ID, Date>();
        for( Quality_Control__c aQualityControl : newList ) {
            if( recordIdsAlreadyUpdatedWorkOrderSet.contains( aQualityControl.ID ) ) {
                continue;
            }
            recordIdsAlreadyUpdatedWorkOrderSet.add( aQualityControl.ID );

            ID workOrderID = aQualityControl.Work_Order__c;

            // collect all workOrders
            allWorkOrderIdsSet.add( workOrderID );

            // determine whether status has changed to completed
            Quality_Control__c oldQualityControl = oldMap != null ?
                                oldMap.get( aQualityControl.ID ) : null;
            String oldStatus = oldQualityControl == null ? null : oldQualityControl.Status__c;
            String statusFlag = aQualityControl.Status__c;
            Boolean statusChangedToCompleted = (
                    statusFlag == COMPLETED_STATUS_QC
                            && statusFlag != oldStatus
            );

            // collect work order id and date for completed QC records
            if( statusChangedToCompleted && workOrderID != null ) {
                completedWorkOrderIDset.add( workOrderID );
                completedWorkOrderQCDateMap.put( workOrderID, aQualityControl.QC_Date__c );
            }
        }
        system.debug( 'allWorkOrderIdsSet= ' + allWorkOrderIdsSet );
        system.debug( 'completedWorkOrderIDset= ' + completedWorkOrderIDset );

        if( allWorkOrderIdsSet.isEmpty() && completedWorkOrderIDset.isEmpty() ) {
            return;
        }

        List<WorkOrder> workOrderList = getRelatedWorkOrderList( allWorkOrderIdsSet );

        // set status to completed on all related work orders
        List<WorkOrder> workOrdersToUpdateList = getWorkOrdersToUpdateList(
                                workOrderList, completedWorkOrderQCDateMap
                                , operationType );

        system.debug( 'workOrdersToUpdateList= ' + workOrdersToUpdateList );
        if( ! workOrdersToUpdateList.isEmpty() ) {
            update workOrdersToUpdateList;
        }

    }

    public static List<WorkOrder> getWorkOrdersToUpdateList(
                    List<WorkOrder> workOrderList
                    , Map<Id, Date> workOrderQCDateMap
                    , TriggerOperation operationType ) {
        // set status to completed on related work orders
        // update the QC count and has QC flag
        List<WorkOrder> workOrdersToUpdateList = new List<WorkOrder>();
        for( WorkOrder aWorkOrder : workOrderList ) {
            aWorkOrder.Has_QC__c = true;

            // only increase count if adding new QC, not on updates
            if( operationType == TriggerOperation.BEFORE_INSERT ) {
                aWorkOrder.QC_Count__c = ( aWorkOrder.QC_Count__c != null ?
                                        aWorkOrder.QC_Count__c + 1 : 1 );
            }

            // only flag complete the work orders in the map
            if( workOrderQCDateMap.containsKey( aWorkOrder.Id )
                    && aWorkOrder.Work_Order_Status__c != COMPLETED_CUSTOM_STATUS ) {
                aWorkOrder.Work_Order_Status__c = COMPLETED_CUSTOM_STATUS;

                Date QCDate = workOrderQCDateMap.get( aWorkOrder.ID );
                aWorkOrder.Status_Closed_Date__c = QCDate;
            }

            workOrdersToUpdateList.add( aWorkOrder );
        }
        return workOrdersToUpdateList;
    }

    public static List<WorkOrder> getRelatedWorkOrderList( Set<Id> workOrderIDset ) {
        List<WorkOrder> workOrderList = [
                SELECT ID, Status, Work_Order_Status__c, QC_Count__c, Has_QC__c
                FROM WorkOrder
                WHERE ID IN :workOrderIDset
        ];
        system.debug( 'workOrderList= ' + workOrderList );
        return workOrderList;
    }

    // perform rollups...
    //public static void doQCRollups(System.TriggerOperation triggerEvent, List<Quality_Control__c> newQcs, Map<Id, Quality_Control__c> oldQcs)
    //{
    //    System.debug(LoggingLevel.WARN, '---> start doQCRollups');
    //    // set the enum of allowed trigger operations (before insert, after update, etc)
    //    List<TriggerOperation> triggerTypes = new List<TriggerOperation>{
    //            TriggerOperation.AFTER_INSERT
    //            , TriggerOperation.AFTER_UPDATE
    //            , TriggerOperation.AFTER_DELETE
    //            , triggerOperation.AFTER_UNDELETE
    //    };
    //    if (!SG_DisplayUtils.canFireTrigger(triggerEvent, triggerTypes, hasDoneQcRollups)) {
    //        System.debug(LoggingLevel.WARN, '---> already hasDoneQcRollups: ' + hasDoneQcRollups + ' or wrong trigger type; skip');
    //        return;
    //    }
    //
    //    // prevents recursive triggers...
    //    hasDoneQcRollups = true;
    //    //Pass in the API name of the child object, for example 'Asset' and the API name of the parent object, for example 'Community__c';
    //    SG_LookupRollupHelper lh = new SG_LookupRollupHelper( 'Quality_Control__c', 'WorkOrder');
    //
    //    // take care of assigning the correct lists based on the trigger type (Insert vs Update vs Delete vs Undelete)
    //    List<Quality_Control__c> oldQcList;
    //    if ( oldQcs != null ) oldQcList = oldQcs.values();
    //
    //    // take care of assigning the correct lists based on the trigger type (Insert vs Update vs Delete vs Undelete)
    //    lh.setTriggerLists(Trigger.isUpdate, Trigger.isDelete, newQcs, oldQcList);
    //
    //    // do the rollup(s) -- will execute all active rollups for current child/parent configuration
    //    lh.doRollupSummary();
    //}

}