@isTest
private class SG_TestDataGenerator_Test {

    static testMethod void TestDataGeneratorUnitTest() {
        SG_TestDataGenerator data = new SG_TestDataGenerator();
        data.initAllTestData();               
        data.getProfileToUserMap(null);       
        System.assertNotEquals(0,data.getUsers(null).size());
    }

    static testMethod void TestDataGeneratorUnitTest_FailedProfiles() {
        SG_TestDataGenerator data = new SG_TestDataGenerator();               
        List<String> badProfiles = new List<String>();
        badProfiles.add('WrongProfile');
        data.getProfileToUserMap(badProfiles);       
        System.assertNotEquals(0,data.getUsers(null).size());
    }
    
    static testMethod void TestDataGeneratorUnitTest_FailuredCounter() {
        SG_TestDataGenerator data = new SG_TestDataGenerator();
        data.userNum = null;               
        List<String> badProfiles = new List<String>();
        badProfiles.add('WrongProfile');
        data.getProfileToUserMap(badProfiles);       
        System.assertNotEquals(0,data.getUsers(null).size());
    }

    static testMethod void testGeos() {
        SG_TestDataGenerator data = new SG_TestDataGenerator();
        List<Project_Location_GEO__c> geos = data.getGeos(true);
        Pricebook2 pb = SG_TestDataGenerator.stdPB;
    }
    
}