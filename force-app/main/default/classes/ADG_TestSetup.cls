@isTest
public class ADG_TestSetup {
    public static void Setup() {
        ADG_SfapiConfig__c setting = new ADG_SfapiConfig__c();
        setting.Name = 'ADG SFAPI Config';
        setting.apiKey__c = '123456789';
        setting.baseUrl__c = 'https://ihapi.adgus.net:6710';
        insert setting;
        
        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE Name = '#Custom: Field Service Manager'
            LIMIT 1
        ];
        
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
        
        User user1 = new User(
            Username = 'testUser2@adgus.net',
            LastName = 'Doe',
            Email = 'testUser2@adgus.net',
            Alias = 'test',
            TimeZoneSidKey = 'America/Chicago',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.id,
            LanguageLocaleKey = 'en_US'
        );
        insert user1;
        
        User user2 = new User(
            Username = 'testUser3@adgus.net',
            LastName = 'Doe',
            Email = 'testUser3@adgus.net',
            Alias = 'test',
            TimeZoneSidKey = 'America/Chicago',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.id,
            LanguageLocaleKey = 'en_US'
        );
        insert user2;
        
        ServiceResource fieldServiceManager = new ServiceResource(
            Name = 'Test FieldServiceManager',
            RelatedRecordId = user.id
        );
        insert fieldServiceManager;
        
        ServiceResource fieldServiceManager1 = new ServiceResource(
            Name = 'Test FieldServiceManager2',
            RelatedRecordId = user1.id
        );
        insert fieldServiceManager1;
        
        ServiceResource fieldServiceManager2 = new ServiceResource(
            Name = 'Test FieldServiceManager3',
            RelatedRecordId = user2.id
        );
        insert fieldServiceManager2;
        
        Account account0 = new Account(
            Name = 'Builder Long Name, LLC CO.',
            Account_Short_Name__c = 'Builder Short Name',
            Integration_Key_Account__c = 'FLR_BLD_RFMS:4549'
        );
        insert account0;
        
        Id installerType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Installer Company').getRecordTypeId();
        Account account1 = new Account(
            Name = 'Jon Doe Contractors, LLC',
            Account_Short_Name__c = 'Jon Doe Short Name',
            RecordTypeId = installerType,
            Installer__c = 'ABC_RFMS:1111'
        );
        insert account1;
        System.debug('XXX Account1: ' + account1);
        
        Account account2 = new Account(
            Name = 'Jane Doe Contractors, LLC',
            Account_Short_Name__c = 'Jane Doe Short Name',
            RecordTypeId = installerType,
            Installer__c = 'ABC_RFMS:2222'
        );
        insert account2;
        
        Community__c community = new Community__c(
            Name = 'community',
            Builder__c = account0.id,
            Location__c = 'DFW',
            Field_Service_Manager__c = fieldServiceManager.id,
            Entity__c = 'Floors'
        );
        insert community;
        
        Asset house = new Asset(
            Name = 'identifier',
            AccountId = account0.id,
            Community__c = community.id,
            Lot_Block__c = 'identifier',
            Street__c = 'identifier',
            Field_Service_Manager__c = fieldServiceManager.Id
        );
        insert house;
        
        
        Contact contact1 = new Contact(
            Email = 'james.doe@adgus.net',
            FirstName = 'James',
            LastName = 'Doe',
            AccountId = account1.Id, // Has work orders attached to it.
            ContractPro_Account_Enabled__c = true
        );
        insert contact1;
        System.debug('XXX Contact1: ' + contact1);
        
        Contact contact2 = new Contact(
            Email = 'juan.doe@adgus.net',
            FirstName = 'Juan',
            LastName = 'Doe',
            AccountId = account2.Id, // Has no work orders attached to it.
            ContractPro_Account_Enabled__c = true
        );
        insert contact2;
        
        WorkOrder wo = new WorkOrder(
            AssetId = house.Id,
            AccountId = account0.Id,
            Community__c = community.Id,
            Field_Service_Manager__c = fieldServiceManager.id,
            Installer_Account__c = account1.id,
            Job_End_Day__c = date.today(),
            Start_Day__c = date.today(),
            Job_Type__c = 'CARPET'
        );
        insert wo;
        System.debug('XXX WorkOrder: ' + wo);
        
        WorkOrderLineItem woLine = new WorkOrderLineItem(
            WorkOrderId = wo.Id
        );
        insert woLine;
        
        Area__c areaRec = new Area__c(
            Work_Order_Line_Item__c = woLine.Id, 
            Area_Note__c = '<div class="notes-plain">This is a test note</div>'
        );
        insert areaRec;
        
        Community_Team__c ctm = new Community_Team__c(Community__c = community.Id, 
                                                      FSM__c = fieldServiceManager1.Id, 
                                                      Job_Type__c = 'CARPET');
        insert ctm;
        
        ADG_JobPathCalloutMockup hcm = new ADG_JobPathCalloutMockup();
        hcm.setJobPathsBody(house.Id);
        Test.setMock(HttpCalloutMock.class, hcm);
        
    }
    
    public static void messageTest() {
        ADG_SfapiConfig__c setting = new ADG_SfapiConfig__c();
        setting.Name = 'ADG SFAPI Config';
        setting.apiKey__c = '123456789';
        setting.baseUrl__c = 'https://ihapi.adgus.net:6710';
        insert setting;
        
        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE Name = '#Custom: Field Service Manager'
            LIMIT 1
        ];
        
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
        
        Account account0 = new Account(
            Name = 'Builder Long Name, LLC CO.',
            Account_Short_Name__c = 'Builder Short Name',
            Integration_Key_Account__c = 'FLR_BLD_RFMS:4549'
        );
        insert account0;
        
        Account account1 = new Account(
            Name = 'Jon Doe Contractors, LLC',
            Account_Short_Name__c = 'Jon Doe Short Name'
        );
        insert account1;
        System.debug('XXX Account1: ' + account1);
        
        Account account2 = new Account(
            Name = 'Jane Doe Contractors, LLC',
            Account_Short_Name__c = 'Jane Doe Short Name');
        insert account2;
        
        Community__c community = new Community__c(
            Name = 'community',
            Builder__c = account0.id,
            Location__c = 'DFW',
            Field_Service_Manager__c = fieldServiceManager.id
        );
        insert community;
        
        Asset house = new Asset(
            Name = 'identifier',
            AccountId = account0.id,
            Community__c = community.id,
            Lot_Block__c = 'identifier',
            Street__c = 'identifier',
            Field_Service_Manager__c = fieldServiceManager.Id
        );
        insert house;    
        
        
        Contact contact1 = new Contact(
            Email = 'james.doe@adgus.net',
            FirstName = 'James',
            LastName = 'Doe',
            AccountId = account1.Id, // Has work orders attached to it.
            ContractPro_Account_Enabled__c = true
        );
        insert contact1;
        System.debug('XXX Contact1: ' + contact1);
        
        Contact contact2 = new Contact(
            Email = 'juan.doe@adgus.net',
            FirstName = 'Juan',
            LastName = 'Doe',
            AccountId = account2.Id, // Has no work orders attached to it.
            ContractPro_Account_Enabled__c = true
        );
        insert contact2;
        
        WorkOrder wo = new WorkOrder(
            AssetId = house.Id,
            AccountId = account0.Id,
            Community__c = community.Id,
            Field_Service_Manager__c = fieldServiceManager.id,
            Installer_Account__c = account1.id,
            Job_End_Day__c = date.today(),
            Start_Day__c = date.today(),
            Job_Type__c = 'CARPET'
        );
        insert wo;
        System.debug('XXX WorkOrder: ' + wo);
        
        WorkOrderLineItem woLine = new WorkOrderLineItem(
            WorkOrderId = wo.Id
        );
        insert woLine;
        
        Area__c areaRec = new Area__c(
            Work_Order_Line_Item__c = woLine.Id, 
            Area_Note__c = '<div class="notes-plain">This is a test note</div>'
        );
        insert areaRec;
    }
    
}