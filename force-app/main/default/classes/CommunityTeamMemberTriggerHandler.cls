/**
* insert sharing records for the given team members
*/
public without sharing class CommunityTeamMemberTriggerHandler {
    
    private static boolean insertAlreadyFired = false;
    private static boolean updateAlreadyFired = false;
    
    
    public static boolean insertHasAlreadyFired(){
        return insertAlreadyFired; 
    }
    public static boolean updateHasAlreadyFired(){
        return updateAlreadyFired; 
    }
    public static void setInsertFired(){
        insertAlreadyFired = true; 
    }
    public static void setUpdateFired(){
        updateAlreadyFired = true; 
    }
    
    public static void createShares(List<Community_Team__c> teamMembers) {
        String enabledEntities = System.Label.Teams_Entities.toUpperCase();
        List<Community__Share> sharesToInsert = new List<Community__Share>();
        Set<String> insertedParentAndUser = new Set<String>();
        Set<Id> communityIdSet = new Set<Id>();
        for (Community_Team__c tm : teamMembers){
            if (tm.Community_Entity__c != null){
                if (enabledEntities.contains(tm.Community_Entity__c.toUpperCase()) || Test.isRunningTest()){
                    communityIdSet.add(tm.Community__c);
                    String parentAndUser = String.valueOf(tm.Community__c) + String.valueOf(tm.Field_User_Id__c);
                    if (insertedParentAndUser.contains(parentAndUser)) continue;
                    sharesToInsert.add(new Community__Share(
                        //ParentId, UserOrGroupId, AccessLevel, RowCause
                        ParentId = tm.Community__c,
                        UserOrGroupId = tm.Field_User_Id__c, 
                        AccessLevel = 'Edit', 
                        RowCause = Schema.Community__Share.rowCause.Community_Team__c
                    ));
                    insertedParentAndUser.add(parentAndUser);
                }
            }
        }
        
        if (! sharesToInsert.isEmpty()){
            insert sharesToInsert;
            Map<Id, Community__c> communityHouseTeamMap = new Map<Id, Community__c> ([Select Id, (Select Id, Status, OwnerId  from House_Units__r), (Select Field_User_Id__c, FSM__c, Job_Type__c from Community_Teams__r) from Community__c where Id IN: communityIdSet]); 
            if (!communityHouseTeamMap.IsEmpty()) {
                HouseTeamMember.createShares(communityHouseTeamMap);
                updWOFSM(communityIdSet);
            }
        }
    }
    
    public static void addDefaults(List<Community_Team__c> teamMembers){
        for (Community_Team__c tm : teamMembers){
            tm.UniqueJobType__c = tm.Community__c + tm.Job_Type__c + tm.FSM__c; 
        }
        
    }
    
    public static void updateShares(List<Community_Team__c> updatedMembers, Map<Id, Community_Team__c> oldMap){
        String chkEntity = System.Label.Teams_Entities.toUpperCase();
        List<Community_Team__c> sharingToInsert = new List<Community_Team__c>();
        List<Community_Team__c> sharingToRemove = new List<Community_Team__c>();
        Set<Id> communityIds = new Set<Id>();
        for (Community_Team__c member : updatedMembers){
            if (member.Community_Entity__c != null){
                if (chkEntity.contains(member.Community_Entity__c.toUpperCase()) || Test.isRunningTest()){
                    Community_Team__c oldMember = oldMap.get(member.Id);
                    if (member.Field_User_Id__c != oldMember.Field_User_Id__c || member.Community__c != oldMember.Community__c){
                        sharingToRemove.add(oldMember);
                        sharingToInsert.add(member);
                        communityIds.add(member.Community__c);
                    }
                }
            }
        }
        if (! sharingToInsert.isEmpty()){
            createShares(sharingToInsert);
            updWOFSM(communityIds);
        }
    }
    
    public static void updWOFSM(Set<Id> communitySetIds){
        List<WorkOrder> woList = new List<WorkOrder>();
        Map<Id, Community__c> communityWOTeamMap = new Map<Id, Community__c> ([Select Id, (Select Id, Work_Order_Status__c, OwnerId, Field_Service_Manager__c, Job_Type__c from Work_Orders__r WHERE (NOT Work_Order_Status__c like 'Completed%')), (Select Field_User_Id__c, FSM__c, Job_Type__c from Community_Teams__r) from Community__c where Id IN: communitySetIds]);
        for (String key : communityWOTeamMap.keySet()){
            Community__c communityRec = communityWOTeamMap.get(key);
            for (WorkOrder wo: communityRec.Work_Orders__r){
                for (Community_Team__c ct : communityRec.Community_Teams__r){
                    if (wo.Job_Type__c.toUpperCase().contains(ct.Job_Type__c.toUpperCase())){
                        wo.Field_Service_Manager__c = ct.FSM__c;
                        wo.OwnerId = ct.Field_User_Id__c;
                        woList.add(wo);
                        break;
                    }
                }
            }
        }
        if (! woList.isEmpty()){
            update woList;
        }
    }
}