/***************************************************
* Name:         SG_WorkOrderHelper
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

public without sharing class SG_WorkOrderHelper {
    public static final String CANCELLED_APPOINTMENT = 'Canceled';
    
    public static String DEFAULT_TERRITORY_ID {
        get {
            if( DEFAULT_TERRITORY_ID == null ) {
                List<ServiceTerritory> svcTerritoryList = [SELECT Id FROM ServiceTerritory WHERE Name = 'Default Territory' LIMIT 1];
                if( svcTerritoryList.isEmpty() ) {
                    DEFAULT_TERRITORY_ID = Label.Default_Territory_ID; //'0Hh2g0000004IF5';
                } else {
                    DEFAULT_TERRITORY_ID = svcTerritoryList[0].Id;
                }
            }
            return DEFAULT_TERRITORY_ID;
        }
        set;
    }
    
    public static Set<Id> recordIdsAlreadyProcessedOnCreateSet = new Set<Id>();
    public static Set<Id> recordIdsAlreadyHaveQCSet = new Set<Id>();
    public static Set<Id> recordIdsAlreadyProcessedSet = new Set<Id>();
    public static Boolean enableAppointmentUpsert = true;
    
    public static List<Work_Order_Trigger_Configuration__mdt> woConfigList {
        get {
            if( woConfigList == null ) {
                woConfigList = [SELECT ID, Job_Type__c, Quality_Control_Record_Type__c, Community_Field_to_Verify__c, 
                                Allow_Duplicates__c, Day_Count_Field_Name__c FROM Work_Order_Trigger_Configuration__mdt];
            }
            return woConfigList;
        }
        set;
    }
    
    public static List<String> dayCountFieldNames {
        get {
            if( dayCountFieldNames == null ) {
                Set<String> fieldNameSet = new Set<String>();
                for( Work_Order_Trigger_Configuration__mdt wotc : woConfigList ) {
                    if( wotc.Day_Count_Field_Name__c != null ) {
                        fieldNameSet.add( wotc.Day_Count_Field_Name__c );
                    }
                }
                dayCountFieldNames = new List<String>( fieldNameSet );
            }
            return dayCountFieldNames;
        }
        set;
    }
    
    // lazy loading record types
    public static Map<String,Schema.RecordTypeInfo> rtMapByName {
        get {
            if( rtMapByName == null ) {
                Schema.DescribeSObjectResult dsor = Schema.SObjectType.Quality_Control__c;
                rtMapByName = dsor.getRecordTypeInfosByDeveloperName();
            }
            return rtMapByName;
        }
        set;
    }
    
    public static Map<String, Boolean> allowDuplicateByJobTypeMap {
        get {
            if( allowDuplicateByJobTypeMap == null ) {
                allowDuplicateByJobTypeMap = new Map<String, Boolean>();
                for( Work_Order_Trigger_Configuration__mdt wotc : woConfigList ) {
                    // get rid of nulls
                    Boolean allowDupes = ( wotc.Allow_Duplicates__c == true );
                    allowDuplicateByJobTypeMap.put( wotc.Job_Type__c.toUpperCase(), allowDupes );
                }
                
            }
            return allowDuplicateByJobTypeMap;
        }
        set;
    }
    
    public static Map<String, String> jobTypeToDayCountFieldNameMap {
        get {
            if( jobTypeToDayCountFieldNameMap == null ) {
                jobTypeToDayCountFieldNameMap = new Map<String, String>();
                for( Work_Order_Trigger_Configuration__mdt wotc : woConfigList ) {
                    jobTypeToDayCountFieldNameMap.put( wotc.Job_Type__c.toUpperCase(), wotc.Day_Count_Field_Name__c );
                }
            }
            return jobTypeToDayCountFieldNameMap;
        }
        set;
    }
    
    public static Map<String, String> jobTypeToQCRecordTypeIDMap {
        get {
            if( jobTypeToQCRecordTypeIDMap == null ) {
                jobTypeToQCRecordTypeIDMap = new Map<String, String>();
                for( Work_Order_Trigger_Configuration__mdt wotc : woConfigList ) {
                    // convert rec type name to id and store id in map indexed by job type
                    ID rtID = rtMapByName.get( wotc.Quality_Control_Record_Type__c ).getRecordTypeId();
                    jobTypeToQCRecordTypeIDMap.put( wotc.Job_Type__c.toUpperCase(), rtID );
                }
            }
            return jobTypeToQCRecordTypeIDMap;
        }
        set;
    }
    
    public static Map<String, String> jobTypeToCommunityFieldMap {
        get {
            if( jobTypeToCommunityFieldMap == null ) {
                jobTypeToCommunityFieldMap = new Map<String, String>();
                for( Work_Order_Trigger_Configuration__mdt wotc : woConfigList ) {
                    jobTypeToCommunityFieldMap.put(wotc.Job_Type__c.toUpperCase(), wotc.Community_Field_to_Verify__c );
                }
            }
            return jobTypeToCommunityFieldMap;
        }
        set;
    }
    
    public static void deleteRelatedQualityControl( TriggerOperation operationType, Map<ID, WorkOrder> workOrderMap ) {
        // only on deletes
        if( operationType != TriggerOperation.BEFORE_DELETE ) {
            return;
        }
        List<Quality_Control__c> qualityControlList = [SELECT ID FROM Quality_Control__c WHERE Work_Order__c IN :workOrderMap.keySet()];
        if(! qualityControlList.isEmpty() ) {
            delete qualityControlList;
        }
    }
    
    public static void populateWorkOrder( TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> oldMap ) {
        if( operationType != TriggerOperation.BEFORE_INSERT
           && operationType != TriggerOperation.BEFORE_UPDATE ) {
               return;
           }
        List<WorkOrder> workOrderList = (List<WorkOrder>) newList;
        Set<ID> assetIDSet = new Set<ID>();
        for( WorkOrder aWorkOrder : workOrderList ) {
            if( recordIdsAlreadyProcessedOnCreateSet.contains( aWorkOrder.Id ) ) {
                continue;
            }
            recordIdsAlreadyProcessedOnCreateSet.add( aWorkOrder.Id );
            aWorkOrder.ServiceTerritoryId = ( aWorkOrder.ServiceTerritoryId == null )? DEFAULT_TERRITORY_ID : aWorkOrder.ServiceTerritoryId;
            if( operationType == TriggerOperation.BEFORE_UPDATE ) {
                continue;
            }
            if( aWorkOrder.AssetId != null ) {
                assetIDSet.add( aWorkOrder.AssetId );
            }
        }
        
        if( assetIDSet.isEmpty() ) {
            return;
        }
        
        Map<ID, Asset> assetMap = new Map<ID, Asset>([SELECT ID, Name, Community__c, Field_Service_Manager__c, Field_Service_Manager_Territory_ID__c,
                                                      Field_Service_Manager_ID_formula__c, Location__c FROM Asset WHERE ID IN :assetIDSet]);
        
        for( WorkOrder aWorkOrder : workOrderList ) {
            Asset anAsset = assetMap.get( aWorkOrder.AssetId );
            if( anAsset == null ) {
                continue;
            }
            
            // populate fields with values from the asset
            Id assetFieldServiceManagerID = anAsset.Field_Service_Manager__c;
            if (anAsset.Location__c != null && (!anAsset.Location__c.contains('Peninsula'))){
                aWorkOrder.Field_Service_Manager__c = ( assetFieldServiceManagerID != null )? assetFieldServiceManagerID : aWorkOrder.Field_Service_Manager__c;
            }
            String territoryID = anAsset.Field_Service_Manager_Territory_ID__c;
            aWorkOrder.ServiceTerritoryId = ( territoryID != null )? territoryID : aWorkOrder.ServiceTerritoryId;
            String fieldServiceManagerUserID = anAsset.Field_Service_Manager_ID_formula__c;
            aWorkOrder.OwnerId = ( fieldServiceManagerUserID != null && fieldServiceManagerUserID != '')? fieldServiceManagerUserID : aWorkOrder.OwnerId;
            String communityID = anAsset.Community__c;
            aWorkOrder.Community__c = ( communityID != null)? communityID : aWorkOrder.Community__c;
        }
        if (operationType == TriggerOperation.BEFORE_INSERT && (! workOrderList.isEmpty())){
            WorkOrderSyncCommunityTeamsFSM.syncCommunityTeamFSMOnWO(workOrderList);
        }
    }
    
    public static void assignAssetsToWorkOrders( List<WorkOrder> workOrderList ) {
        // collect billing groups in order to retrieve corresponding house/units
        Set<String> billingGroupSet = new Set<String>();
        Set<String> primaryIdentifierSet = new Set<String>();
        Set<ID> assetIDSet = new Set<ID>();
        for( WorkOrder aWorkOrder : workOrderList ) {
            String billingGroup = aWorkOrder.Billing_Group__c;
            if( billingGroup != null ) {
                billingGroupSet.add( billingGroup );
            }
            
            String primaryIdentifier = aWorkOrder.PrimaryIdentifier__c;
            if( primaryIdentifier != null ) {
                primaryIdentifierSet.add( primaryIdentifier );
            }
            
            if( aWorkOrder.AssetId == null ) {
                assetIDSet.add( aWorkOrder.AssetId );
            }
        }
        // find houses/units using billing groups or primary identifiers
        Map<String, Asset> houseUnitByBillingGroupMap = getHouseUnitMapByBillingGroup( billingGroupSet, primaryIdentifierSet, assetIDSet );
        Id defaultHouseRTID = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get( 'House' ).getRecordTypeId();        
        // retrieve communities in case we need to create new house/units and assign communities to them
        List<Community__c> communityList = getCommunityList();
        Map<String, Community__c> communityIDByEntityMap = getCommunityByEntityMap( communityList );
        Map<String, Community__c> communityIDByNameMap = getCommunityByNameAndBuilder( communityList );
        // populate house/unit on work orders
        Map<String, Asset> newAssetMap = new Map<String, Asset>();
        Set<ID> workOrdersWithNewAssetIDSet = new Set<ID>();
        for( WorkOrder aWorkOrder : workOrderList ) {
            String billingGroup = aWorkOrder.Billing_Group__c;
            String communityNameERP = aWorkOrder.CommunityNameERP__c;
            String orphanedCommunityCode = aWorkOrder.OrphanedCommunityCode__c;
            String primaryID = aWorkOrder.PrimaryIdentifier__c;
            // skip WO records whose billing group and primary id don't allow us to select a house/unit
            if( billingGroup == null && primaryID == null && aWorkOrder.AssetId == null ) {
                continue;
            }
            Asset houseUnit = houseUnitByBillingGroupMap.get( aWorkOrder.AssetId );
            // if it couldn't find house/unit by Id, try by billing group, then try by primary ID
            if( houseUnit == null && billingGroup != null ) {
                houseUnit = houseUnitByBillingGroupMap.get( billingGroup );
            }
            if( houseUnit == null && primaryID != null ) {
                houseUnit = houseUnitByBillingGroupMap.get( primaryID.toUpperCase() );
            }
            // if found by primaryID and not billing group, check the account too
            if( houseUnit != null && billingGroup == null && aWorkOrder.AssetId == null && aWorkOrder.AccountId != houseUnit.AccountId ) {
                // reject the house/unit because the account didn't match
                continue;
            }
            
            // use the house/unit found and proceed to the next work order
            if( houseUnit != null ) {
                setAssetFieldsOnWorkOrder( houseUnit, aWorkOrder );
                continue;
            }
            // create house/unit as needed
            if( billingGroup != null && houseUnit == null ) {
                String street = aWorkOrder.Street;
                Asset newHouseUnit = getNewAsset( defaultHouseRTID, billingGroup, aWorkOrder );
                Community__c aCommunity;
                if( communityNameERP != null ) {
                    String theKey = communityNameERP.toUpperCase() + '^' + aWorkOrder.AccountId;
                    aCommunity = communityIDByNameMap.get( theKey );
                }
                // if community wasn't found by community name ERP, determine to which community
                // should this new house/unit belong using the orphaned community code
                if( aCommunity == null ) {
                    aCommunity = communityIDByEntityMap.get( orphanedCommunityCode.toUpperCase() );
                }
                if( aCommunity == null ) {
                    String communityIntegrationID = billingGroup;
                    if( orphanedCommunityCode == null || orphanedCommunityCode == 'N/A' ) {
                        String[] billingGroupArray = billingGroup.split( ':' );
                        if( billingGroupArray.size() > 0 ) {
                            communityIntegrationID = billingGroupArray[ 0 ];
                        }
                    } else {
                        communityIntegrationID = orphanedCommunityCode;
                    }
                    aCommunity = communityIDByEntityMap.get( communityIntegrationID + ':' );
                }
                
                if( aCommunity != null ) {
                    setCommmunityFieldsOnAsset( newHouseUnit, aCommunity );
                    
                    aWorkOrder.Community__c = aCommunity.Id;
                }
                // store new asset to be inserted
                newAssetMap.put( newHouseUnit.Integration_Key_Billing_Group__c, newHouseUnit );
                // assign the house object reference in the work order
                aWorkOrder.Asset = newHouseUnit;
                workOrdersWithNewAssetIDSet.add( aWorkOrder.ID );
                setFieldServiceManagerOnWorkOrder( aCommunity, aWorkOrder );
                newHouseUnit.OwnerID = aWorkOrder.OwnerId != null ? aWorkOrder.OwnerId : newHouseUnit.OwnerID;
                houseUnitByBillingGroupMap.put( newHouseUnit.Integration_Key_Billing_Group__c, newHouseUnit );
            }
        }
        if( ! newAssetMap.isEmpty() ) {
            List<Asset> newAssetList = newAssetMap.values();
            Database.UpsertResult[] upsertResults = Database.upsert( newAssetList, Asset.Integration_Key_Billing_Group__c, false );
            logErrors( upsertResults, newAssetList );
        }
        
        // convert asset obj references to asset ids
        for( WorkOrder aWorkOrder : workOrderList ) {
            // skip if work order already have asset or work order has not been set with a new asset
            If( aWorkOrder.AssetId != null || ! workOrdersWithNewAssetIDSet.contains( aWorkOrder.ID ) ) {
                continue;
            }
            aWorkOrder.AssetId = aWorkOrder.Asset.Id;
            aWorkOrder.Asset = null;
        }
        
        //update workOrderList;
        Database.SaveResult[] srList = Database.update( workOrderList, false );
        logErrors( 'Work Order updates', srList, workOrderList );
    }
    
    public static void logErrors( Database.UpsertResult[] upsertResults, List<SObject> sObjectList ) {
        String allErrors = '';
        for( Integer i = 0; i < upsertResults.size(); i++ ) {
            Database.UpsertResult anUpsertResult = upsertResults[ i ];
            if( anUpsertResult.isSuccess() ) {
                continue;
            }
            allErrors = allErrors + ' Record: ' + JSON.serialize(sObjectList[i])+ ' Error: ' + JSON.serialize(anUpsertResult.getErrors());
        }
        if( allErrors != '' ) {
            SG_ErrorHelper.notifyOnError( 'SG_BatchAssetWorkOrderControl', 'Asset Creation', 'Upserting Assets', allErrors );
        }
    }
    
    public static void logErrors( String subject, Database.SaveResult[] saveResults, List<SObject> sObjectList ) {
        String allErrors = '';
        for( Integer i = 0; i < saveResults.size(); i++ ) {
            Database.SaveResult aSaveResult = saveResults[ i ];
            if( aSaveResult.isSuccess() ) {
                continue;
            }
            
            allErrors = allErrors + ' Record: '+ JSON.serialize(sObjectList[i]) + ' Error: ' + JSON.serialize( aSaveResult.getErrors());
        }
        if( allErrors != '') {
            SG_ErrorHelper.notifyOnError( 'SG_BatchAssetWorkOrderControl', 'Update Exception', subject, allErrors );
        }
    }
    
    public static void setFieldServiceManagerOnWorkOrder( Community__c aCommunity, WorkOrder aWorkOrder ) {
        
        if(( aCommunity != null && aCommunity.Field_Service_Manager__c != null) && 
           (aCommunity.Location__c != null && (!aCommunity.Location__c.contains('Peninsula')))) {
               aWorkOrder.Field_Service_Manager__c = aCommunity.Field_Service_Manager__c;
               if( aCommunity.Field_Service_Manager__r.Service_Resource_User_ID__c != null
                  && aCommunity.Field_Service_Manager__r.Service_Resource_User_ID__c != '' ) {
                      aWorkOrder.OwnerId = aCommunity.Field_Service_Manager__r.Service_Resource_User_ID__c;
                  }
               if( aCommunity.Field_Service_Manager__r.Territory_ID__c != null ) {
                   aWorkOrder.ServiceTerritoryId = aCommunity.Field_Service_Manager__r.Territory_ID__c;
               }
           }
    }
    
    public static void setCommmunityFieldsOnAsset( Asset newHouseUnit, Community__c aCommunity ) {
        newHouseUnit.Community__c = aCommunity.Id;
        newHouseUnit.Field_Service_Manager__c = aCommunity.Field_Service_Manager__c;
        newHouseUnit.AccountId = ( newHouseUnit.AccountId == null ) ? aCommunity.Builder__c : newHouseUnit.AccountId;
    }
    
    public static Asset getNewAsset( Id defaultHouseRTID, String billingGroup, WorkOrder aWorkOrder ) {
        Asset newHouseUnit = new Asset();
        newHouseUnit.RecordTypeID = defaultHouseRTID;
        newHouseUnit.Integration_Key_Billing_Group__c = billingGroup;
        newHouseUnit.Name = aWorkOrder.PrimaryIdentifier__c; // was Street
        newHouseUnit.Lot_Block__c = aWorkOrder.PrimaryIdentifier__c; // was Street
        newHouseUnit.Job_Number__c = aWorkOrder.Job_Number__c;
        newHouseUnit.Street__c = aWorkOrder.Street;
        newHouseUnit.City__c = aWorkOrder.City;
        newHouseUnit.State__c = aWorkOrder.State;
        newHouseUnit.Zip_Code__c = aWorkOrder.PostalCode;
        newHouseUnit.AccountId = aWorkOrder.AccountId;
        newHouseUnit.Status = 'Final';
        String defaultName = ((newHouseUnit.City__c != null ? newHouseUnit.City__c + '' : '') + 
                              (newHouseUnit.State__c != null ? newHouseUnit.State__c + '' : '') + billingGroup );
        newHouseUnit.Name = ( newHouseUnit.Name != null ) ? newHouseUnit.Name : defaultName;
        newHouseUnit.Lot_Block__c = ( newHouseUnit.Lot_Block__c != null ) ? newHouseUnit.Lot_Block__c : defaultName;
        return newHouseUnit;
    }
    
    public static void setAssetFieldsOnWorkOrder( Asset houseUnit, WorkOrder aWorkOrder ) {
        String ownerID = (houseUnit.Field_Service_Manager_ID_formula__c != null && houseUnit.Field_Service_Manager_ID_formula__c != '' )	
            ? houseUnit.Field_Service_Manager_ID_formula__c : aWorkOrder.OwnerId;
        String communityID = houseUnit.Community__c != null ? houseUnit.Community__c : aWorkOrder.Community__c;
        aWorkOrder.OwnerId = ownerID;
        aWorkOrder.Community__c = communityID;
        if (houseUnit.Location__c != null && (!houseUnit.Location__c.contains('Peninsula'))){
            aWorkOrder.Field_Service_Manager__c = houseUnit.Field_Service_Manager__c;
            aWorkOrder.ServiceTerritoryId = houseUnit.Field_Service_Manager_Territory_ID__c;
        }
        
        // if house/unit hasn't been saved yet, link the object reference instead of ID
        if( houseUnit.Id == null ) {
            aWorkOrder.Asset = houseUnit;
            
        } else {
            // house is created and should be in this work order
            aWorkOrder.AssetId = houseUnit.Id;
        }
    }
    
    public static Map<String, Asset> getHouseUnitMapByBillingGroup( Set<String> billingGroupSet, Set<String> primaryIdentifierSet, Set<ID> assetIDSet ) {
        List<Asset> assetList = [SELECT ID, AccountId, Integration_Key_Billing_Group__c, Field_Service_Manager__c, Field_Service_Manager_ID_formula__c
                                 ,Field_Service_Manager_Territory_ID__c, PrimaryIdentifier__c, Community__c, Location__c FROM Asset 
                                 WHERE Integration_Key_Billing_Group__c IN :billingGroupSet OR PrimaryIdentifier__c IN :primaryIdentifierSet OR ID IN :assetIDSet];
        // index houses/units by the billing group and primary ID
        Map<String, Asset> houseUnitByBillingGroupMap = new Map<String, Asset>();
        for( Asset aHouseUnit : assetList ) {
            houseUnitByBillingGroupMap.put( aHouseUnit.ID, aHouseUnit );                                                
            if( aHouseUnit.Integration_Key_Billing_Group__c != null ) {
                houseUnitByBillingGroupMap.put( aHouseUnit.Integration_Key_Billing_Group__c, aHouseUnit );
            }
            
            if( aHouseUnit.PrimaryIdentifier__c != null ) {
                houseUnitByBillingGroupMap.put( aHouseUnit.PrimaryIdentifier__c.toUpperCase(), aHouseUnit );
            }
        }
        return houseUnitByBillingGroupMap;
    }
    
    public static List<Community__c> getCommunityList() {
        List<Community__c> communityList = [SELECT ID, Name, EntityIntegration__c, Field_Service_Manager__c, Field_Service_Manager__r.Service_Resource_User_ID__c
                                            ,Field_Service_Manager__r.Territory_ID__c, Builder__c, Builder__r.Name, Location__c
                                            FROM Community__c LIMIT 5000];
        // 10/23/2020 - FMF removed condition because now we're mapping by name too
        //      WHERE EntityIntegration__c != null
        
        return communityList;
    }
    
    public static Map<String, Community__c> getCommunityByEntityMap( List<Community__c> communityList ) {
        // index communities by EntityIntegration__c
        Map<String, Community__c> communityIDByEntityMap = new Map<String, Community__c>();
        for( Community__c aCommunity : communityList ) {
            if( aCommunity.EntityIntegration__c != null ) {
                communityIDByEntityMap.put( aCommunity.EntityIntegration__c.toUpperCase(), aCommunity );
            }
        }
        return communityIDByEntityMap;
    }
    
    public static Map<String, Community__c> getCommunityByNameAndBuilder( List<Community__c> communityList ) {
        // index communities by EntityIntegration__c
        Map<String, Community__c> communityIDByName = new Map<String, Community__c>();
        for( Community__c aCommunity : communityList ) {
            communityIDByName.put( aCommunity.Name.toUpperCase() + '^' + aCommunity.Builder__c, aCommunity );
        }
        return communityIDByName;
    }
    
    
    @future
    public static void createAssetsAtFuture( String JSONnewAssetList ) {
        List<Asset> newAssetList = (List<Asset>) JSON.deserializeStrict( JSONnewAssetList, List<Asset>.class );
        Database.UpsertResult[] upsertResults = Database.upsert( newAssetList, Asset.Integration_Key_Billing_Group__c, false);
        String allErrors = '';
        for( Integer i = 0; i < upsertResults.size(); i++ ) {
            Database.UpsertResult anUpsertResult = upsertResults[ i ];
            if( anUpsertResult.isSuccess() ) {
                continue;
            }
            
            allErrors = allErrors + ' Asset: ' + JSON.serialize(newAssetList[i]) + ' Error: ' + JSON.serialize(anUpsertResult.getErrors());
        }
        if(allErrors != '') {
            SG_ErrorHelper.notifyOnError( 'SG_WorkOrderHelper', 'Work Order Trigger - DB to SF', 'Work Order Trigger - Upserting Assets', allErrors );
        }
        
        // collect billing groups in order to retrieve work orders matching the billing group and without assets
        Map<String, Asset> assetByBillingGroupMap = new Map<String, Asset> ();
        for( Asset newHouseUnit : newAssetList ) {
            assetByBillingGroupMap.put( newHouseUnit.Integration_Key_Billing_Group__c, newHouseUnit );
        }
        Set<String> billingGroupSet = assetByBillingGroupMap.keySet();
        List<WorkOrder> workOrderList = [SELECT ID, Billing_Group__c, Account_Location__c FROM WorkOrder WHERE Billing_Group__c IN :billingGroupSet AND AssetID = null];
        
        // assign assets to the work orders
        for( WorkOrder aWorkOrder : workOrderList ) {
            Asset houseUnit = assetByBillingGroupMap.get( aWorkOrder.Billing_Group__c );
            if( houseUnit == null ) {
                continue;
            }
            aWorkOrder.AssetId = houseUnit.ID;
            
            // prevent recursion
            SG_WorkOrderHelper.recordIdsAlreadyProcessedOnCreateSet.add( aWorkOrder.Id );
        }
        
        update workOrderList;
    }
    
    public static void createQualityControl(TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> oldMap ) {
        // only on inserts/updates
        if( operationType != TriggerOperation.AFTER_INSERT
           && operationType != TriggerOperation.AFTER_UPDATE ) {
               return;
           }
        
        Set<String> recTypeSet = new Set<String> {
            'Standard', 'Internal'
                };
                    
                    // create list of community__c fields to verify
                    List<String> communityFieldList = getUniqueCommunityFieldList();
        String soqlQuery = 'SELECT ID, Location__c , '
            + String.join( communityFieldList, ', ' )
            +  ' FROM Asset '
            +  ' WHERE ID IN :assetIdSet ';        
        List<WorkOrder> workOrderList = (List<WorkOrder>) newList;
        
        // collect asset ids in order to get the quality control records associated with them
        Set<Id> assetIdSet = new Set<Id>();
        Boolean atLeastOneWorkOrder = false;
        for( WorkOrder aWorkOrder : workOrderList ) {
            if( recordIdsAlreadyHaveQCSet.contains( aWorkOrder.Id ) ) {
                continue;
            }
            recordIdsAlreadyHaveQCSet.add( aWorkOrder.Id );
            atLeastOneWorkOrder = true;
            
            Id AssetId = aWorkOrder.AssetId;
            assetIdSet.add( AssetId );
        }
        // avoid running the same code again when all records have already been checked
        // and assetIdSet resulted empty
        if( atLeastOneWorkOrder == false ) {
            return;
        }
        
        // fetch the community related to the houses
        List<Asset> assetList = Database.query( soqlQuery );
        Map<Id, Asset> assetMap = new Map<Id, Asset>( assetList );
        // fetch quality control records for the assets
        List<Quality_Control__c> existingQCList = [SELECT ID, RecordTypeId, House_Unit__c, Work_Order__c FROM Quality_Control__c WHERE House_Unit__c IN :assetIdSet];
        // create index of QC record types for each asset
        Map<Id, Set<Id>> qcRecordTypeIDsByAssetIdMap = new Map<Id, Set<Id>>();
        Set<Id> workOrderIDWithQCSet = new Set<Id>();
        for( Quality_Control__c existingQC : existingQCList ) {
            Set<Id> recordTypeIDSet = qcRecordTypeIDsByAssetIdMap.get( existingQC.House_Unit__c );
            if( recordTypeIDSet == null ) {
                recordTypeIDSet = new Set<Id>();
            }
            
            recordTypeIDSet.add( existingQC.RecordTypeId );
            qcRecordTypeIDsByAssetIdMap.put( existingQC.House_Unit__c, recordTypeIDSet );
            
            // store work order id to indicate that there is already a QC for it
            workOrderIDWithQCSet.add( existingQC.Work_Order__c );
        }
        // create QC records as needed
        List<Quality_Control__c> qualityControlList = new List<Quality_Control__c>();
        for( WorkOrder aWorkOrder : workOrderList ) {
            
            // don't create QC for past work orders
            if( aWorkOrder.Start_Day__c < Date.today() ) {
                continue;
            }
            
            String workOrderRecType = aWorkOrder.Record_Type_Developer_Name__c;
            Id assetId = aWorkOrder.AssetId;
            
            // get the QC record type according to the job type
            String jobType = aWorkOrder.Job_Type__c;
            if( jobType != null ) {
                jobType = jobType.toUpperCase();
            }
            String qcRecTypeID = jobTypeToQCRecordTypeIDMap.get( jobType );
            
            // check that the asset doesn't already have a QC of this record type
            Set<Id> recordTypeIDSet = qcRecordTypeIDsByAssetIdMap.get( assetId );
            Boolean assetRecTypeAlreadyHasQC = ( recordTypeIDSet != null
                                                && recordTypeIDSet.contains( qcRecTypeID ) );
            Boolean allowsDuplicates = allowDuplicateByJobTypeMap.get( jobType );
            if( allowsDuplicates == false && assetRecTypeAlreadyHasQC == true ) {
                // asset already has QC matching this record type, bail out
                continue;
            }
            
            // if there is already a QC for this work order, skip it
            if( workOrderIDWithQCSet.contains( aWorkOrder.ID ) ) {
                continue;
            }
            
            // check whether community field is specified in the configuration and, if it is
            // check whether its value is Yes
            String communityField = jobTypeToCommunityFieldMap.get( jobType );
            if( communityField != null ) {
                String communityFieldValue;
                Asset theAsset = assetMap.get( assetId );
                if( theAsset != null ) {
                    Community__c aCommunity = ( Community__c ) theAsset.getSObject( 'Community__r' );
                    if( aCommunity != null ) {
                        communityFieldValue = String.valueOf( aCommunity.get( communityField ) );
                    }
                }
                if( communityFieldValue != 'Yes' ) {
                    continue;
                }
            }
            
            // create quality control records according to the job type if applicable
            if( recTypeSet.contains( workOrderRecType ) && assetId != null && qcRecTypeID != null ) {
                Quality_Control__c qc = createQualityControl( assetId, qcRecTypeID, aWorkOrder.Id );
                qualityControlList.add( qc );
                
                // store the new record type to indicate there is now a QC record for it
                if( recordTypeIDSet == null ) {
                    recordTypeIDSet = new Set<Id>();
                }
                recordTypeIDSet.add( qcRecTypeID );
                qcRecordTypeIDsByAssetIdMap.put( assetId, recordTypeIDSet );
                
            }
        }
        if( ! qualityControlList.isEmpty() ) {
            insert qualityControlList;
        }
    }
    
    public static List<String> getUniqueCommunityFieldList() {
        // get list of fields, remove nulls and make it unique
        List<String> communityFields = jobTypeToCommunityFieldMap.values();
        Set<String> communityFieldSet = new Set<String>();
        for( String aFieldName : communityFields ) {
            if( aFieldName != null ) {
                communityFieldSet.add( 'Community__r.' + aFieldName );
            }
        }
        return new List<String>( communityFieldSet );
    }
    
    public static Quality_Control__c createQualityControl(ID AssetId, String recTypeID, ID workOrderID) {
        //Quality_Control__c qc = new Quality_Control__c();
        // instantiate QC with the default field values
        Quality_Control__c qc = (Quality_Control__c) Quality_Control__c.sObjectType.newSObject(null, true);
        qc.House_Unit__c = AssetId;
        qc.RecordTypeId = recTypeID;
        qc.Work_Order__c = workOrderID;
        return qc;
    }
    
    public static void syncFieldServiceManagerChanges( TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> oldMap){
        
        // is there reason to run this on INSERTs ? Field_Service_Manager__c will not have changed
        if( operationType != TriggerOperation.BEFORE_INSERT && operationType != TriggerOperation.BEFORE_UPDATE ) {
            return;
        }
        List<WorkOrder> workOrderList = (List<WorkOrder>) newList;
        List<String> dateFieldList = new List<String> {'Field_Service_Manager__c'};
            Map<Id, Id> fieldServMngIDByWorkOrderIDMap = new Map<Id, Id>();
        for(WorkOrder aWorkOrder : workOrderList){
            // detect whether a relevant field has changed
            WorkOrder oldWorkOrder = oldMap != null ? (WorkOrder) oldMap.get( aWorkOrder.Id ) : null;
            Boolean relevantFieldChanged = detectChanges( aWorkOrder, oldWorkOrder, dateFieldList );
            if( relevantFieldChanged == false ) {
                continue;
            }
            // change owner to the new field service manager user
            String fieldServiceManagerUserID = String.valueOf( aWorkOrder.Field_Service_Manager_ID_formula__c );
            if( fieldServiceManagerUserID != null && fieldServiceManagerUserID != '' ) {
                aWorkOrder.OwnerId = fieldServiceManagerUserID;
            }
            fieldServMngIDByWorkOrderIDMap.put( aWorkOrder.Id, aWorkOrder.Field_Service_Manager__c );
        }
        
        // retrieve all related Service Appointments
        Set<Id> workOrderIDSet = fieldServMngIDByWorkOrderIDMap.keySet();
        List<ServiceAppointment> servAppointmentList = [SELECT Id, ParentRecordId FROM ServiceAppointment WHERE ParentRecordId IN :workOrderIDSet];
        if( servAppointmentList.isEmpty() ) {
            return;
        }
        // create assigned resources for each of the service appointments
        createAssignedResources( servAppointmentList, fieldServMngIDByWorkOrderIDMap );
    }
    
    public static void calculateJobQCDates( TriggerOperation operationType, List<WorkOrder> newList, Map<Id, WorkOrder> oldMap ) {
        
        if( operationType != TriggerOperation.BEFORE_INSERT && operationType != TriggerOperation.BEFORE_UPDATE ) {
            return;
        }
        List<String> dateFieldList = new List<String> { 'Start_Day__c', 'Job_Type__c', 'Community__c' };
            // collect community ID to retrieve communities
            Set<ID> communityIDSet = new Set<ID>();
        List<WorkOrder> modifiedWorkOrderList = new List<WorkOrder>();
        for( WorkOrder aWorkOrder : newList ) {
            // detect whether a relevant field has changed
            WorkOrder oldWorkOrder = oldMap != null ? (WorkOrder) oldMap.get( aWorkOrder.Id ) : null;
            Boolean relevantFieldChanged = detectChanges( aWorkOrder, oldWorkOrder, dateFieldList );
            if( relevantFieldChanged == false || aWorkOrder.Community__c == null || aWorkOrder.Start_Day__c == null ) {
                continue;
            }
            communityIDSet.add( aWorkOrder.Community__c );
            modifiedWorkOrderList.add( aWorkOrder );
        }
        if( modifiedWorkOrderList.isEmpty() ) {
            return;
        }
        // filter out work orders whose qc records are completed or dont exist
        Boolean modifiedWorkOrders = true;
        if( operationType != TriggerOperation.BEFORE_INSERT ) {
            modifiedWorkOrderList = getWorkOrdersWithoutCompletedQCList( modifiedWorkOrderList );
            modifiedWorkOrders = ! modifiedWorkOrderList.isEmpty();
        }
        
        // retrieve communities to get business hours and day counts and index by ID
        Map<Id, Community__c> communityMap = getCommunityMap( communityIDSet );
        if( communityMap.isEmpty() ) {
            return;
        }
        
        // apply business hours and day counts to the work order start date
        for( WorkOrder aWorkOrder : modifiedWorkOrderList ) {
            if( aWorkOrder.Start_Day__c == null ) {
                continue;
            }
            
            Community__c aCommunity = communityMap.get( aWorkOrder.Community__c );
            if( aCommunity == null ) {
                continue;
            }
            
            BusinessHours bh = aCommunity.Business_Hours__r;
            if( bh == null ) {
                bh = SG_WorkdayCalculationHelper.orgsHours;
            }
            // find the field name to check
            String jobType = aWorkOrder.Job_Type__c;
            jobType = ( jobType == null ? '' : jobType.toUpperCase() );
            
            String fieldName = jobTypeToDayCountFieldNameMap.get( jobType );
            
            // if fieldname was not in the custom metadata, use default of 2 days
            Decimal dayCount = 2;
            try {
                dayCount = ( fieldName == null ? 2 : ( Decimal ) aCommunity.get( fieldName ) );
            } catch( Exception e ) {
                system.debug( 'ERROR:  couldn\'t find field ' + fieldName + ' in community record ' + aCommunity );
            }
            
            Decimal QCEndCount = ( aCommunity.Day_Count_QC_End__c != null ) ? aCommunity.Day_Count_QC_End__c : 0;
            dayCount = ( dayCount != null ) ? dayCount : 0;
            Decimal nbrDays = dayCount + QCEndCount - 1;
            
            // calculate business days from Job Start Day to Job Start Day + day count + day count QC end
            Map<Integer, DateTime> workdaysMap = SG_WorkdayCalculationHelper.getWorkdayMap(
                bh, aWorkOrder.Start_Day__c, nbrDays );
            // assign each business day on the work order
            if( workdaysMap.containsKey( Integer.valueOf( dayCount - 1 ) ) ) {
                aWorkOrder.Job_End_Day_calculated__c = workdaysMap.get( Integer.valueOf( dayCount - 1 ) ).date();
            }
            if( modifiedWorkOrders && workdaysMap.containsKey( Integer.valueOf( dayCount ) ) ) {
                aWorkOrder.QC_Start_Date__c = workdaysMap.get( Integer.valueOf( dayCount ) ).date();
            }
            if( modifiedWorkOrders && workdaysMap.containsKey( Integer.valueOf( nbrDays ) ) ) {
                aWorkOrder.QC_End_Date__c = workdaysMap.get( Integer.valueOf( nbrDays ) ).date();
            }
        }
    }
    
    public static Map<Id, Community__c> getCommunityMap( Set<Id> communityIDSet ) {
        // create SOQL query string
        String soql = 'SELECT ID, Business_Hours__c, Location__c,'+ String.join( dayCountFieldNames, ',' )
            + ', Day_Count_QC_End__c '+ ', Business_Hours__r.ID, Business_Hours__r.MondayEndTime '
            + ', Business_Hours__r.MondayStartTime '+' FROM Community__c' + ' WHERE ID IN :communityIDSet ';
        List<Community__c> communityList = Database.query( soql );
        Map<ID, Community__c> communityMap = new Map<ID, Community__c>( communityList );
        return communityMap;
    }
    
    public static List<WorkOrder> getWorkOrdersWithoutCompletedQCList( List<WorkOrder> aWorkOrderList ) {
        // retrieve qc records that are completed
        Map<ID, WorkOrder> workOrderMap = new Map<ID, WorkOrder>( aWorkOrderList );
        List<Quality_Control__c> qcList = [SELECT ID, Work_Order__c FROM Quality_Control__c WHERE Work_Order__c IN :workOrderMap.keySet() 
                                           AND Status__c = :SG_QualityControlHelper.COMPLETED_STATUS_QC];
        // get IDs for work orders with completed QC record
        Set<ID> workOrderIDsWithCompletedQCSet = new Set<ID>();
        for( Quality_Control__c qc : qcList ) {
            workOrderIDsWithCompletedQCSet.add( qc.Work_Order__c );
        }
        // exclude work orders with completed QC
        List<WorkOrder> workOrderWithQCList = new List<WorkOrder>();
        for( WorkOrder wo : aWorkOrderList ) {
            if( workOrderIDsWithCompletedQCSet.contains( wo.ID ) ) {
                continue;
            }
            workOrderWithQCList.add( wo );
        }
        
        return workOrderWithQCList;
    }
    
    public static void createAssignedResources(List<ServiceAppointment> servAppointmentList,Map<Id, Id> fieldServMngIDByWorkOrderIDMap) {
        Map<ID, ServiceAppointment> servApptMap = new Map<ID, ServiceAppointment>( servAppointmentList );                                                  
        List<AssignedResource> existingAssignedResources = [SELECT Id, ServiceAppointmentID, ServiceResourceID FROM AssignedResource 
                                                            WHERE ServiceAppointmentID IN :servApptMap.keySet()];
        Set<String> assignedResourceExists = new Set<String>();
        for(AssignedResource ar :  existingAssignedResources)
        {
            String key = ar.ServiceAppointmentId + '|' + ar.ServiceResourceId;
            assignedResourceExists.add(key);
        }
        
        List<AssignedResource> resourceList = new List<AssignedResource>();
        for( ServiceAppointment servAppt : servAppointmentList ) {
            // add new field service manager to the work order's service appointment's assigned resource list
            Id workOrderID = servAppt.ParentRecordId;
            Id fieldServManagerID = fieldServMngIDByWorkOrderIDMap.get( workOrderID );
            if(fieldServManagerID == null) {
                continue;
            }
            String key = servAppt.Id + '|' + fieldServManagerID;
            if( assignedResourceExists.contains( key ) ) {
                continue;
            }
            
            AssignedResource aResource = new AssignedResource();
            aResource.ServiceAppointmentId = servAppt.Id;
            aResource.ServiceResourceId = fieldServManagerID;
            resourceList.add( aResource );
        }
        
        if( !resourceList.isEmpty() ) {
            //insert resourceList;
            Database.SaveResult[] srList = Database.insert( resourceList, false );
            logErrors( 'Assigned Resource inserts', srList, resourceList );
        }
    }
    
    public static void upsertAppointments(TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> oldMap ) {
        if( operationType != TriggerOperation.AFTER_INSERT && operationType != TriggerOperation.AFTER_UPDATE) {
            return;
        }
        if( enableAppointmentUpsert == false ) {
            return;
        }
        // 7/7/2020 - if a Field Service Manager is added, create a new appointment
        List<String> fieldChangeList = new List<String> {'Start_Day__c', 'Job_End_Day__c', 'Due_Date_for_svc_appt__c', 'Field_Service_Manager__c'};
            List<WorkOrder> workOrderList = (List<WorkOrder>) newList;
        List<ServiceAppointment> serviceAppointmentList = new List<ServiceAppointment>();
        for(WorkOrder aWorkOrder : workOrderList){
            WorkOrder oldWorkOrder = oldMap != null ? (WorkOrder) oldMap.get( aWorkOrder.Id ) : null;
            Boolean relevantFieldChanged = detectChanges( aWorkOrder, oldWorkOrder, fieldChangeList );
            ID servApptID = aWorkOrder.ServiceAppointmentID__c;
            // only upsert serv appt if the day/time has changed
            Date startDay = aWorkOrder.Start_Day__c;
            if( relevantFieldChanged && startDay >= Date.today() ) {
                ServiceAppointment appt = new ServiceAppointment();
                appt.Id = servApptID;
                if( servApptID == null ) {
                    // field below is read only when updating
                    appt.ParentRecordId = aWorkOrder.Id;
                    appt.Work_Order__c = aWorkOrder.Id;
                    appt.House_Unit__c = aWorkOrder.AssetId;
                    appt.Status = 'Scheduled';
                }
                Time aTime = Time.newInstance( 0, 0, 0, 0 );
                DateTime startDt = DateTime.newInstance( startDay, aTime );
                DateTime endDt = ( aWorkOrder.Job_End_Day__c != null ) ?
                    DateTime.newInstance( aWorkOrder.Job_End_Day__c, aTime ) : null;
                appt.SchedStartTime = startDt;
                appt.SchedEndTime = endDt;
                appt.EarliestStartTime = startDt.addDays( -1 );
                Date dueDate = aWorkOrder.Due_Date_for_svc_appt__c;
                if( dueDate != null ) {
                    DateTime dueDt = DateTime.newInstance( dueDate, aTime );
                    appt.DueDate = dueDt;
                }
                
                serviceAppointmentList.add( appt );
            }
        }
        
        if(! serviceAppointmentList.isEmpty() ) {
            Database.UpsertResult[] upsertResults = Database.upsert( serviceAppointmentList, false );
            String allErrors = '';
            for(Integer i = 0; i < upsertResults.size(); i++) {
                Database.UpsertResult anUpsertResult = upsertResults[ i ];
                if(anUpsertResult.isSuccess()) {
                    continue;
                }
                allErrors = allErrors + ' Appointment: ' + JSON.serialize(serviceAppointmentList[i])+ ' Error: ' + JSON.serialize( anUpsertResult.getErrors() );
            }
            if(allErrors != '') {
                SG_ErrorHelper.notifyOnError( 'SG_WorkOrderHelper', 'Work Order Trigger - DB to SF', 'Work Order Trigger - Upserting Appointments', allErrors );
            }
        }
    }
    
    public static Boolean detectChanges( SObject newObj, SObject oldObj, List<String> fieldList ) {
        // check each field in the list, return true at first change found
        for( String aField : fieldList ) {
            // assume oldObj null means insert context
            if( oldObj == null || newObj.get( aField ) != oldObj.get( aField ) ) {
                return true;
            }
        }
        return false;
    }
    
    public static void checkBlankStartDate(TriggerOperation operationType, List<SObject> newList, Map<Id, SObject> oldMap) {
        if(operationType != TriggerOperation.AFTER_UPDATE) {
            return;
        }
        List<String> fieldChangeList = new List<String> {'Start_Day__c'};
            List<WorkOrder> workOrderList = (List<WorkOrder>) newList;
        Set<ID> workOrderIDSet = new Set<ID>();
        for( WorkOrder aWorkOrder : workOrderList ) {
            // detect whether a relevant field has changed
            WorkOrder oldWorkOrder = oldMap != null ? (WorkOrder) oldMap.get( aWorkOrder.Id ) : null;
            Boolean relevantFieldChanged = detectChanges( aWorkOrder, oldWorkOrder, fieldChangeList );
            if( relevantFieldChanged == false || aWorkOrder.Start_Day__c != null ) {
                continue;
            }
            
            workOrderIDSet.add( aWorkOrder.Id );
        }
        
        if( workOrderIDSet.isEmpty() ) {
            return;
        }
        
        List<Quality_Control__c> qcList = [SELECT ID FROM Quality_Control__c WHERE Work_Order__c IN :workOrderIDSet];
        if( ! qcList.isEmpty() ) {
            delete qcList;
        }
        
        List<ServiceAppointment> svcApptList = [SELECT ID, Status FROM ServiceAppointment WHERE Work_Order__c IN :workOrderIDSet];
        
        if( ! svcApptList.isEmpty() ) {
            for( ServiceAppointment svcAppt : svcApptList ) {
                svcAppt.Status = CANCELLED_APPOINTMENT;
            }
            update svcApptList;
        }
        
    }
    
    //Added to delete QC on Job Change
    public static void deleteQCOnJobTypeChange(List<WorkOrder> woList, Map<Id, WorkOrder> oldWOMap){
        List<WorkOrder> updWOList = new List<WorkOrder>();
        for (WorkOrder wo: woList){
            if (wo.Job_Type__c != oldWOMap.get(wo.Id).Job_Type__c){
                updWOList.add(wo);
            }
        }
        if (!updWOList.isEmpty()){
            List<Quality_Control__c> qualityControlList = [SELECT ID FROM Quality_Control__c WHERE Work_Order__c IN :updWOList];
            if (!qualityControlList.isEmpty()) {
                delete qualityControlList;
            }
        }
    }
}