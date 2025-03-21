trigger Community_Team on Community_Team__c (after insert, after update, after delete, before insert, before update) {
    
    if (SG_ApexActivator.isDisabled('Disable_Community_Team_Trigger__c')) {
        System.debug('---> this trigger has been disabled via Custom Setting');
        return;
    }
    
    if (Trigger.isBefore && Trigger.isInsert){
        CommunityTeamMemberTriggerHandler.addDefaults(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate){
        CommunityTeamMemberTriggerHandler.addDefaults(Trigger.new);
    }
    if (Trigger.isInsert && Trigger.isAfter) {
        if (! CommunityTeamMemberTriggerHandler.insertHasAlreadyFired()){
            CommunityTeamMemberTriggerHandler.createShares(Trigger.new);
            CommunityTeamMemberTriggerHandler.setInsertFired();
        } 
    }
    if (Trigger.isUpdate && Trigger.isAfter){
        if (! CommunityTeamMemberTriggerHandler.updateHasAlreadyFired()){
            CommunityTeamMemberTriggerHandler.updateShares(Trigger.new, Trigger.oldMap);
            CommunityTeamMemberTriggerHandler.setUpdateFired();
        }
    }
    /*else if (Trigger.isDelete && Trigger.isAfter){
  *   handler.removeShare(Trigger.new);
  handler.resetWOFSM(Trigger.new);
  }*/
}