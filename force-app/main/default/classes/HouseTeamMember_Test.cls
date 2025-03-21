/***********************************************************************************
* Name:     	HouseTeamMember_Test
* Author:   	Pushkar
* Main Class:	HouseTeamMember
* ======================================================
* History:
* VER   DATE          INITIALS      DESCRIPTION/FEATURES ADDED
* 1.0   Aug-01-2023   pushkar       Initial Development to be test
*
***********************************************************************************/
@isTest
public class HouseTeamMember_Test {
    
    static testMethod void HouseTeamMembershareOnFSMUpd(){
        Test.startTest();
        ADG_TestSetup.Setup(); //SetUp Accounts and Workorders
        Map<Id, Community__c> communityHouseMap = new Map<Id, Community__c> ([Select Id, (Select Id, Status, OwnerId from House_Units__r), (Select Field_User_Id__c, FSM__c, Job_Type__c from Community_Teams__r) from Community__c]); 
        system.debug('@@@@' + JSON.serialize(communityHouseMap));
        HouseTeamMember.shareOnFSMUpd(communityHouseMap);
        Test.stopTest();
    }
}