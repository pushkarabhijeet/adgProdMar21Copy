@IsTest
public class SG_Asset_LU_Test 
{
    private static SG_TestDataGenerator td;
    private static List<Account> accounts;
    private static List<Community__c> comms;
    private static List<Asset> houses;
    private static List<ServiceResource> servResource;
    
    
    public static Boolean isTest = false;

    
    @testSetup static void setupTestData()
    {
        isTest = true;
        ADG_TestSetup.Setup();
        //td = new SG_TestDataGenerator();
        //accounts = td.getAccounts(true);
    }
    
    static testMethod void testBehavior()
    {
        // the LU Helper has it's own test class. We just need to fire the trigger for test coverage
        refreshData();
        /*
        System.debug('---> accounts: ' + accounts );
        Account a = accounts[0];
        Community__c com = new Community__c();
        com.Name = 'Test';
        com.Builder__c = a.Id;
        insert com;
        
        refreshData();
        com = comms[0];
        ServiceResource serv = servResource[0];
        
        Id houseRtId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('House').getRecordTypeId();
        
        Asset ast = new Asset();
        ast.Community__c = com.Id;
        ast.Name = 'Test Asset';
        ast.RecordTypeId = houseRtId;
        ast.Lot_Block__c = 'Lot';
        ast.AccountId = a.Id;
        ast.Field_Service_Manager__c = serv.Id;
        insert ast;
		*/
        ServiceResource serv = servResource[0];
        Asset ast = houses[0];
        isTest = true;
        update ast;

        // test the activator...
        isTest = false;
        serv = servResource[1];
        ast.Field_Service_Manager__c = serv.Id;
        update ast;
        
    }

    public static void refreshData()
    {
        accounts = [SELECT Id, Name FROM Account];
        comms = [SELECT Id, Name FROM Community__c];
        houses = [SELECT Id, Field_Service_Manager__c FROM Asset];
        servResource = [SELECT ID from ServiceResource];
    }
}