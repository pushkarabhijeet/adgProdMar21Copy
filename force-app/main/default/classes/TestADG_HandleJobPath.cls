@isTest
private class TestADG_HandleJobPath {
    @TestSetup
    static void setup(){
        TestAdgSetup.Setup();
    }

    @isTest 
    static void TestCreateNewAsset() {
        Test.startTest();
        Asset house = [SELECT ADG_JobPath__c FROM Asset WHERE Name = 'identifier'];
     //   System.AssertEquals('test', house.ADG_JobPath__c, 'Expected Job Path to be defined.');
        Test.stopTest();
    }
}