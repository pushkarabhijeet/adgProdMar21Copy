@isTest
public class TestAdgSetup {
    public static void Setup() {

        ADG_SfapiConfig__c setting = new ADG_SfapiConfig__c();
        setting.Name = 'ADG SFAPI Config';
        setting.apiKey__c = '123456789';
        setting.baseUrl__c = 'https://ihapi.adgus.net:6710';
        insert setting;

        Profile profile = [SELECT Id FROM Profile WHERE Name = '#Custom: Field Service Manager' LIMIT 1];

        User user = new User(
            Username = 'testUser@adgus.net',
            LastName = 'Doe',
            Email = 'testUser@adgus.net',
            Alias = 'test',
            TimeZoneSidKey = 'America/Chicago',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
        
        ServiceResource fieldServiceManager = new ServiceResource(
            Name = 'Test FieldServiceManager',
            RelatedRecordId = user.id
        );
        insert fieldServiceManager;

        Account builder = new Account(
            Name = 'builder',
            Account_Short_Name__c = 'Builder Short Name',
            Integration_Key_Account__c = 'FLR_BLD_RFMS:4549'
        );
        insert builder;

        Community__c community = new Community__c(
            Name = 'community',
            Builder__c = builder.id,
            Location__c = 'DFW',
            Field_Service_Manager__c = fieldServiceManager.id
        );
        insert community;

        Asset house = new Asset(
            Name = 'identifier',
            AccountId = builder.id,
            Community__c = community.id,
            Lot_Block__c = 'identifier',
            Field_Service_Manager__c = fieldServiceManager.id
        );
        insert house;

        ADG_JobPathCalloutMockup hcm = new ADG_JobPathCalloutMockup();
        hcm.body = house.Id;
        //hcm.assetId = house.Id;
        Test.setMock(HttpCalloutMock.class, hcm);
    }
}