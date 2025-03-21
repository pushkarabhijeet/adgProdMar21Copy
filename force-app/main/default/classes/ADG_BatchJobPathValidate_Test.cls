@isTest
private class ADG_BatchJobPathValidate_Test {
    @TestSetup
    static void setup(){
        ADG_TestSetup.Setup();
    }
    static testmethod void test() {
        Test.startTest();
        ADG_BatchJobPathValidate jobPathValidate = new ADG_BatchJobPathValidate(); 
        Database.executebatch(jobPathValidate);
        Test.stopTest();
    }
}