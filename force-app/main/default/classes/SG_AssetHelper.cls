/**********************************************************************
* Name:     SG_AssetHelper
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
* 1.0       19-Jun-2020     rwd           Initial Development           
*   
***********************************************************************/


public with sharing class SG_AssetHelper {
    
    public static Boolean hasDoneAssetRollups = false;
    
    // perform rollups...
    public static void doAssetRollups(System.TriggerOperation triggerEvent, List<Asset> newAssets, Map<Id, Asset> oldAssets)
    {
        //System.debug(LoggingLevel.WARN, '---> start doAssetRollups');
        //System.debug(LoggingLevel.WARN, '---> newAssets: ' + newAssets );
        //System.debug(LoggingLevel.WARN, '---> oldAssets: ' + oldAssets );
        // set the enum of allowed trigger operations (before insert, after update, etc)
        List<TriggerOperation> triggerTypes = new List<TriggerOperation>{
            TriggerOperation.AFTER_INSERT
                , TriggerOperation.AFTER_UPDATE
                , TriggerOperation.AFTER_DELETE
                , triggerOperation.AFTER_UNDELETE
                };
                    if (!SG_DisplayUtils.canFireTrigger(triggerEvent, triggerTypes, hasDoneAssetRollups)) {
                        //System.debug(LoggingLevel.WARN, '---> already hasDoneAssetRollups: ' + hasDoneAssetRollups + ' or wrong trigger type; skip');
                        return;
                    }
        
        // prevents recursive triggers...
        hasDoneAssetRollups = true;
        //Pass in the API name of the child object, for example 'Asset' and the API name of the parent object, for example 'Community__c';
        SG_LookupRollupHelper lh = new SG_LookupRollupHelper( 'Asset', 'Community__c');
        
        // take care of assigning the correct lists based on the trigger type (Insert vs Update vs Delete vs Undelete)
        List<Asset> oldAssetList;
        if ( oldAssets != null ) oldAssetList = oldAssets.values();
        
        // take care of assigning the correct lists based on the trigger type (Insert vs Update vs Delete vs Undelete)
        lh.setTriggerLists(Trigger.isUpdate, Trigger.isDelete, newAssets, oldAssetList);
        
        // do the rollup(s) -- will execute all active rollups for current child/parent configuration
        lh.doRollupSummary();
    }
    
    public static Set<Id> recordIdsAlreadyProcessedSet = new Set<Id>();
    
    public static void propagateAssetChanges( System.TriggerOperation operationType,
                                             List<Asset> newAssetList, Map<Id, Asset> oldAssetMap ) {
                                                 
                                                 //System.debug( LoggingLevel.WARN, '---> start propagateAssetChanges ' );
                                                 // only on updates
                                                 if( operationType != TriggerOperation.BEFORE_UPDATE ) {
                                                     return;
                                                 }
                                                 
                                                 Map<Id, Asset> newAssetMap = new Map<Id, Asset>( newAssetList );
                                                 
                                                 // collect IDs from assets that changed to retrieve their work orders
                                                 Set<ID> assetIDSet = new Set<ID>();
                                                 for( Asset aHouse : newAssetList ) {
                                                     if( recordIdsAlreadyProcessedSet.contains( aHouse.Id ) ) {
                                                         continue;
                                                     }
                                                     recordIdsAlreadyProcessedSet.add( aHouse.Id );
                                                     
                                                     // skip if no relevant field has changed
                                                     Asset oldHouse = oldAssetMap != null ? (Asset) oldAssetMap.get( aHouse.Id ) : null;
                                                     if( oldHouse == null
                                                        || ( aHouse.Field_Service_Manager__c == oldHouse.Field_Service_Manager__c
                                                            && aHouse.Community__c == oldHouse.Community__c ) ) {
                                                                continue;
                                                            }
                                                     
                                                     assetIDSet.add( aHouse.ID );
                                                     
                                                     // sync the owner to the FSM Service_Resource_User_ID__c
                                                     if( aHouse.Field_Service_Manager_ID_formula__c != null ) {
                                                         // user Paul T Hess couldn't change house owner, error "insufficient access rights on cross-reference id"
                                                         aHouse.OwnerID = aHouse.Field_Service_Manager_ID_formula__c;
                                                     }
                                                 }
                                                 
                                                 // no need to run the query and update work orders if we're already at future
                                                 // because that is supposed to be in the asset trigger context
                                                 if( System.isFuture() ) {
                                                     return;
                                                 }
                                                 
                                                 if( assetIDSet.isEmpty() ) {
                                                     return;
                                                 }
                                                 
                                                 // retrieve work orders to change their FSM
                                                 List<WorkOrder> workOrderList = [
                                                     SELECT ID, Field_Service_Manager__c, Asset_Field_Service_Manager__c
                                                     , Work_Order_Status__c, AssetId, Community__c, Account_Location__c 
                                                     FROM WorkOrder
                                                     WHERE AssetId IN :assetIDSet
                                                 ];
                                                 //system.debug( 'workOrderList= ' + workOrderList );
                                                 
                                                 if( workOrderList.isEmpty() ) {
                                                     return;
                                                 }
                                                 
                                                 // change work orders' FSM to sync with the respective asset's FSM
                                                 List<WorkOrder> ordersToUpdateList = new List<WorkOrder>();
                                                 for( WorkOrder aWorkOrder : workOrderList ) {
                                                     
                                                     // skip completed work orders
                                                     if((aWorkOrder.Work_Order_Status__c != null && 
                                                         //&& aWorkOrder.Work_Order_Status__c.containsIgnoreCase( 'Completed' ) 
                                                         (aWorkOrder.Work_Order_Status__c == 'Completed_with_QC' 
                                                          || aWorkOrder.Work_Order_Status__c == 'Completed_without_QC'))
                                                        || (aWorkOrder.Account_Location__c != null && (aWorkOrder.Account_Location__c.contains('Peninsula'))))
                                                     {
                                                         continue;
                                                     }
                                                     
                                                     Asset newAsset = newAssetMap.get( aWorkOrder.AssetId );
                                                     if( newAsset == null ) {
                                                         continue;
                                                     }
                                                     
                                                     aWorkOrder.Field_Service_Manager__c = newAsset.Field_Service_Manager__c;
                                                     aWorkOrder.Community__c = newAsset.Community__c;
                                                     ordersToUpdateList.add( aWorkOrder );
                                                 }
                                                 
                                                 // sync FSM to asset FSM
                                                 //system.debug( 'updated workOrderList= ' + ordersToUpdateList );
                                                 
                                                 String JSONWorkOrderList = JSON.serialize( ordersToUpdateList );
                                                 updateWorkOrdersAtFuture( JSONWorkOrderList );
                                             }
    
    @future
    public static void updateWorkOrdersAtFuture( String JSONWorkOrderList ) {
        //System.debug(LoggingLevel.WARN, '---> start updateWorkOrdersAtFuture');
        
        List<WorkOrder> workOrderList = (List<WorkOrder>) JSON.deserializeStrict(
            JSONWorkOrderList, List<WorkOrder>.class );
        //system.debug( 'workOrderList.size= ' + workOrderList.size() );
        //system.debug( 'workOrderList= ' + workOrderList );
        WorkOrderSyncCommunityTeamsFSM.syncCommunityTeamFSMOnWO(workOrderList);
        update workOrderList;
    }
    
}