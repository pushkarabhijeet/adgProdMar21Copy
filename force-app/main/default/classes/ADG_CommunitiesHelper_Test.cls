/***********************************************************************************
 * Name:     	ADG_CommunitiesHelper
 * Author:   	Pushkar
 * Main Class:	ADG_CommunitiesHelper
 * ======================================================
 * History:
 * VER   DATE          INITIALS      DESCRIPTION/FEATURES ADDED
 * 1.0   Dec-31-2020   pushkar       Initial Development to be test
 *
 ***********************************************************************************/
@isTest
public class ADG_CommunitiesHelper_Test {
  public static Boolean isTest = false; //Used for Trigger Test Coverage
  @TestSetUP
  public static void setupData() {
    isTest = true;
    ADG_TestSetup.Setup(); //SetUp Accounts and Workorders
  }

  static testMethod void invokeAfterUpdate_test() {
    Test.startTest();
    Profile profile = [
      SELECT Id
      FROM Profile
      WHERE Name = '#Custom: Field Service Manager'
      LIMIT 1
    ];
    User user = new User(
      Username = 'testUser1@adgus.net',
      LastName = 'Doe',
      Email = 'testUser1@adgus.net',
      Alias = 'test',
      TimeZoneSidKey = 'America/Chicago',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      ProfileId = profile.id,
      LanguageLocaleKey = 'en_US'
    );
    insert user;
    ServiceResource fieldServiceManager = new ServiceResource(
      Name = 'Test FieldServiceManager1',
      RelatedRecordId = user.id
    );
    insert fieldServiceManager;
    isTest = false; //Reset for trigger test coverage
    for (Community__c c : [
      SELECT Id, Field_Service_Manager__c
      FROM Community__c
      LIMIT 1
    ]) {
      c.Field_Service_Manager__c = fieldServiceManager.Id;
      update c;
    }

    Test.stopTest();
  }
}