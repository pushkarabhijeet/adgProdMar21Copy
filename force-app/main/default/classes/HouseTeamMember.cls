public without sharing class HouseTeamMember {
    
    public static void createShares(Map<Id, Community__c> communityHouseTeamMap){
        List<AssetShare> sharesToInsert = new List<AssetShare>(); //RowCause, AssetId, UserOrGroupId, AssetAccessLevel
        Set<String> insertedParentAndUser = new Set<String>();
        for (String key : communityHouseTeamMap.keySet()){
            Community__c communityRec = communityHouseTeamMap.get(key);
            for (Asset house: communityRec.House_Units__r){
                for (Community_Team__c ct : communityRec.Community_Teams__r){
                    String parentAndUser = String.valueOf(house.Id) + String.valueOf(ct.Field_User_Id__c);
                    if (insertedParentAndUser.contains(parentAndUser)) continue;
                    if (house.OwnerId == ct.Field_User_Id__c) continue;
                    sharesToInsert.add(new AssetShare(
                        //ParentId, UserOrGroupId, AccessLevel, RowCause
                        AssetId = house.Id, UserOrGroupId = ct.Field_User_Id__c, AssetAccessLevel = 'Edit', RowCause = 'Manual'));
                    insertedParentAndUser.add(parentAndUser); 
                } 
            }
        }
        if (! sharesToInsert.IsEmpty()){
            insert sharesToInsert;
        }
    }
    
    public static void shareOnFSMUpd(Map<Id, Community__c> communityTeamMap){
        Set<Id> communitySet = new Set<Id>();
        communitySet = communityTeamMap.keySet();
        List<AssetShare> sharesToDelete = new List<AssetShare>([Select Id  from AssetShare where Asset.Community__c  IN:communitySet  AND RowCause = 'Manual']);
        if (! sharesToDelete.IsEmpty()){
            delete sharesToDelete;
        }
        createShares(communityTeamMap);
    }
}