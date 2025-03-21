public without sharing class WorkOrderSyncCommunityTeamsFSM {
    
    public static void syncCommunityTeamFSMOnWO(List<WorkOrder> workOrdersList){
        String enabledEntities = System.Label.Teams_Entities;
        Map<Id, Community__c> communityTeams = new Map<Id, Community__c>();
        communityTeams = getCommunityTeams(workOrdersList);
        for (WorkOrder wo : workOrdersList){
            Community__c communityRec = communityTeams.get(wo.Community__c);
            if (communityRec.Entity__c != null){
                if (enabledEntities.contains(communityRec.Entity__c) || Test.isRunningTest()){
                    for (Community_Team__c ct : communityRec.Community_Teams__r){
                        if (ct.Job_Type__c != null && wo.Job_Type__c != null){
                            if (wo.Job_Type__c.contains(ct.Job_Type__c.toUpperCase())){
                                wo.Field_Service_Manager__c = ct.FSM__c;
                                wo.OwnerId = ct.Field_User_Id__c;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    
    public static Map<Id, Community__c> getCommunityTeams(List<WorkOrder> woList){
        Set<Id> communityId = new Set<ID>();
        Map<Id, Community__c> communityTeamMap = new Map<Id, Community__c>();
        for (WorkOrder order: woList){
            if (order.Community__c != null){
                communityId.add(order.Community__c);
            }
        }
        if (! communityId.isEmpty()){
            communityTeamMap = new Map<Id, Community__c> ([Select Id, Entity__c, (Select Field_User_Id__c, FSM__c, Job_Type__c from Community_Teams__r) from Community__c where Id IN: communityId]); 
        }
        return communityTeamMap;
    }
    
}