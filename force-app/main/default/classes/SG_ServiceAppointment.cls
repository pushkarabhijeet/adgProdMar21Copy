/***************************************************
* Name:         SG_ServiceAppointment
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

public with sharing class SG_ServiceAppointment {
    public static Set<ID> recordIdsAlreadyProcessedAssignedResourceSet = new Set<ID>();
    public static Set<ID> recordIdsAlreadyProcessedSet = new Set<ID>();

    public static void syncWorkOrder( TriggerOperation operationType, List<SObject> newList
            , Map<ID, SObject> oldMap ) {
        //system.debug( 'syncWorkOrder= ' + newList );
        //system.debug( 'operationType= ' + operationType );
        // only on inserts/updates
        if( operationType != TriggerOperation.AFTER_INSERT
                && operationType != TriggerOperation.AFTER_UPDATE ) {
            return;
        }

        List<WorkOrder> workOrderList = new List<WorkOrder>();
        for( SObject sobj : newList ) {
            if( recordIdsAlreadyProcessedSet.contains( sobj.ID ) ) {
                continue;
            }
            recordIdsAlreadyProcessedSet.add( sobj.ID );

            ServiceAppointment sp = (ServiceAppointment) sobj;
            ServiceAppointment oldSP = oldMap != null ? (ServiceAppointment) oldMap.get( sp.ID ) : null;
            ID oldWorkOrderID = oldSP != null ? oldSP.Work_Order__c : null;
            //system.debug( 'sp.Work_Order__c= ' + sp.Work_Order__c );
            //system.debug( 'oldWorkOrderID= ' + oldWorkOrderID );

            // if work order is new or changed, update its service appointment id
            if( sp.Work_Order__c != null
                    && sp.Work_Order__c != oldWorkOrderID ) {
                WorkOrder aWorkOrder = new WorkOrder();
                aWorkOrder.ID = sp.Work_Order__c;
                aWorkOrder.ServiceAppointmentID__c = sp.ID;
                workOrderList.add( aWorkOrder );
            }
        }

        if( ! workOrderList.isEmpty() ) {
            update workOrderList;
        }
    }

    public static void createResource( TriggerOperation operationType, List<SObject> newList
            , Map<ID, SObject> oldMap ) {

        // only on inserts
        if( operationType != TriggerOperation.AFTER_INSERT ) {
            return;
        }

        Set<Id> serviceAppointmentIds = new Set<Id>();
        for( SObject sobj : newList ) 
        {
            ServiceAppointment sp = (ServiceAppointment) sobj;
            serviceAppointmentIds.add(sp.Id);
        }
                
        List<AssignedResource> existingAssignedResources = [SELECT Id, ServiceAppointmentID, ServiceResourceID FROM AssignedResource WHERE ServiceAppointmentID IN :serviceAppointmentIds];
		Set<String> assignedResourceExists = new Set<String>();
                
        for(AssignedResource ar :  existingAssignedResources)
        {
            String key = ar.ServiceAppointmentId + '|' + ar.ServiceResourceId;
            assignedResourceExists.add(key);
        }           
		                
        List<AssignedResource> assignedResourceList = new List<AssignedResource>();
        for( SObject sobj : newList ) {
            if( recordIdsAlreadyProcessedAssignedResourceSet.contains( sobj.ID ) ) {
                continue;
            }
            recordIdsAlreadyProcessedAssignedResourceSet.add( sobj.ID );

            ServiceAppointment sp = (ServiceAppointment) sobj;

            String key = sp.Id + '|' + sp.Asset_Field_Service_Manager__c;            
            if( assignedResourceExists.contains( key ) == false
                    && sp.Asset_Field_Service_Manager__c != null
                    && sp.Asset_Field_Service_Manager__c != '' ) {
            	// create assigned resource linked to the appt
            	AssignedResource ar = new AssignedResource();
            	ar.ServiceAppointmentID = sp.ID;
            	ar.ServiceResourceID = sp.Asset_Field_Service_Manager__c;
            	assignedResourceList.add( ar );
            }
        }

        if( ! assignedResourceList.isEmpty() ) {

            Database.SaveResult[] saveResults = Database.insert( assignedResourceList, false );
            //insert assignedResourceList;

            String allErrors = '';
            for( Integer i = 0; i < saveResults.size(); i++ ) {
                Database.SaveResult aSaveResult = saveResults[ i ];
                if( aSaveResult.isSuccess() ) {
                    continue;
                }

                allErrors = allErrors + ' AssignedResource: '
                        + JSON.serialize( assignedResourceList[ i ] )
                        + ' Error: ' + JSON.serialize( aSaveResult.getErrors() );
            }
            if( allErrors != '' ) {
                SG_ErrorHelper.notifyOnError( 'SG_ServiceAppointment'
                        , 'Service Appointment Trigger - DB to SF'
                        , 'Service Appointment Trigger - Upserting AssignedResource'
                        , allErrors );
            }
        }
    }


}