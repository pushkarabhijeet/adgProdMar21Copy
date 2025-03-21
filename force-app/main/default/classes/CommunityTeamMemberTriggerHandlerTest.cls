@isTest
public without sharing class CommunityTeamMemberTriggerHandlerTest {
    
    @TestSetUP
    public static void setupData() {
        ADG_TestSetup.Setup(); //SetUp Accounts and Workorders
    }
    
    @isTest
    static void testCreateShares() {
        Test.startTest();
        List<Community_Team__c> teamMembers = [Select Community__c, Community_Entity__c, Field_User_Id__c, FSM__c, Job_Type__c , 
                                               UniqueJobType__c from Community_Team__c LIMIT 5];
        CommunityTeamMemberTriggerHandler.createShares(teamMembers);
        Test.stopTest();
    }
    
    @isTest
    static void testAddDefaults() {
        List<Community_Team__c> teamMembers = [Select Community__c, Community_Entity__c, Field_User_Id__c, FSM__c, Job_Type__c , 
                                               UniqueJobType__c from Community_Team__c LIMIT 5];
        Test.startTest();
        CommunityTeamMemberTriggerHandler.addDefaults(teamMembers);
        Test.stopTest();
    }

    @isTest
    static void testUpdateShares() {
        List<Community_Team__c> teamMembers = [Select Community__c, Community_Entity__c, Field_User_Id__c, FSM__c, Job_Type__c , 
                                               UniqueJobType__c from Community_Team__c WHERE FSM__r.Name = 'Test FieldServiceManager2' LIMIT 1];
        List<ServiceResource> fsmList = [SELECT Id From ServiceResource where Name = 'Test FieldServiceManager3'];
        Test.startTest();
        system.debug('@@@1 ' + teamMembers[0].FSM__c);
        system.debug('@@@2 ' + fsmList[0].Id);
        for (Community_Team__c tm : teamMembers){
            tm.FSM__c = fsmList[0].Id;
            update tm;
        }
        Test.stopTest();        
    }
    
    /*@isTest
    static void testShareOnFSMUpd(){
        
    }*/
}