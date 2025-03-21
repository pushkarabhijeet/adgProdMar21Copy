@isTest
public class massCommunityTeamsTest {
    
    @TestSetUP
    public static void setupData() {
        ADG_TestSetup.Setup(); //SetUp Accounts and Workorders
    }
    
    @isTest
    static void testUploadCommunityMembers() {
        // Create test data for the Community__c and ServiceResource objects
        List<Community__c> communities = [SELECT Builder_Name_Text__c, Name, Field_Service_Manager__r.RelatedRecord.Email FROM Community__c LIMIT 2];
        List<ServiceResource> serviceResources = [SELECT Id,RelatedRecord.Email  from ServiceResource LIMIT 2];
        List<massCommunityTeams.csvRecs> testRecords = new List<massCommunityTeams.csvRecs>();
        massCommunityTeams.csvRecs testRec = new massCommunityTeams.csvRecs();
        testRec.BuilderName = communities[0].Builder_Name_Text__c;
        testRec.CommunityName = communities[0].Name;
        testRec.CommunityOwnerEmail = serviceResources[1].RelatedRecord.Email;
        testRec.CommunityTeamMemberEmail = serviceResources[0].RelatedRecord.Email;
        testRec.JobType = 'LVP';
        testRecords.add(testRec);
        massCommunityTeams.csvRecs testRec1 = new massCommunityTeams.csvRecs();
        testRec1.BuilderName = communities[0].Builder_Name_Text__c;
        testRec1.CommunityName = communities[0].Name;
        testRec1.CommunityOwnerEmail = serviceResources[1].RelatedRecord.Email;
        testRec1.CommunityTeamMemberEmail = serviceResources[0].RelatedRecord.Email;
        testRec1.JobType = 'Laminate';
        testRecords.add(testRec1);
        massCommunityTeams.csvRecs testRec2 = new massCommunityTeams.csvRecs();
        testRec2.BuilderName = communities[0].Builder_Name_Text__c;
        testRec2.CommunityName = communities[0].Name;
        testRec2.CommunityOwnerEmail = null;
        testRec2.CommunityTeamMemberEmail = serviceResources[0].RelatedRecord.Email;
        testRec2.JobType = 'Countertops';
        testRecords.add(testRec2);
        // Test the uploadCommunityMembers method
        Test.startTest();
        String jsonInput = JSON.serialize(testRecords);
        massCommunityTeams.uploadCommunityMembers(jsonInput);
        Test.stopTest();   
    }
}