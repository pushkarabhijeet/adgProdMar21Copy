@isTest
private class ADG_InstallerMessage_Test {
  @TestSetup
  static void setup() {
    ADG_TestSetup.messageTest();
  }

  @isTest
  static void testContactName() {
    Test.startTest();
    Contact ct1 = [SELECT Id FROM Contact WHERE email = 'james.doe@adgus.net'];
    String contactName = ADG_InstallerMessage.getContactName(ct1.Id);
    System.assert(contactName == 'James Doe');
    Test.stopTest();
  }

  @isTest
  static void testUserName() {
    Test.startTest();
    User user = [SELECT Id FROM User WHERE Id = '0054T000001PSXLQA4'];
    String uN = ADG_InstallerMessage.getUserName(user.Id);
    System.assert(uN == 'ADG FMS API User');
    Test.stopTest();
  }

  @isTest
  static void testHasInstallerAccount() {
    Test.startTest();
    Account a1 = [SELECT Id FROM Account WHERE Account_Short_Name__c = 'Jon Doe Short Name'];
    WorkOrder wO = [SELECT Id, Installer_Account__r.Id, Field_Service_Manager_ID_formula__c FROM WorkOrder WHERE Installer_Account__c = :a1.Id];
    Boolean hasInstallerAccount = ADG_InstallerMessage.hasInstallerAccount(wO.Id);
    System.assert(hasInstallerAccount == true);
    Test.stopTest();
  }

  @isTest
  static void testSubmitMessage() {
    ADG_InstallerMessageCalloutMockup imcm = new ADG_InstallerMessageCalloutMockup();
    Test.setMock(HttpCalloutMock.class, imcm);
    Test.startTest();
    Account a1 = [SELECT Id FROM Account WHERE Account_Short_Name__c = 'Builder Short Name'];
    WorkOrder wO = [SELECT Id, Installer_Account__r.Id, Field_Service_Manager_ID_formula__c FROM WorkOrder WHERE AccountID = :a1.Id];
    String workOrderId = wO.Id;
    ADG_InstallerMessage.MessageResponse response = ADG_InstallerMessage.submitMessage(workOrderId, 'sdasda', 'sdasdasd');
    Test.stopTest();
  }

  @isTest
  static void testFormatMessages(){
    Test.startTest();
    List<ADG_InstallerMessage.Message> messages = new List<ADG_InstallerMessage.Message>();
    ADG_InstallerMessage.Message installerMessage = new ADG_InstallerMessage.Message();
    installerMessage.server_message_id = '123456789';
    installerMessage.message_text = 'Installer message text here.';
    installerMessage.sender_type = 0; // Installer // 1 Field Manager
    installerMessage.sent_by_id = '111222333';
    installerMessage.installer_account_id = '999888777';
    installerMessage.server_timestamp = '';
    messages.add(installerMessage);
    ADG_InstallerMessage.MessageResponse response = new ADG_InstallerMessage.MessageResponse();
    // TODO:  VALIDATE RESPONSE.
    ADG_InstallerMessage.formatMessages(messages);
    Test.stopTest();
  }

  @isTest
  static void testGetMessages() {
    ADG_InstallerMessageCalloutMockup imcm = new ADG_InstallerMessageCalloutMockup();
    Test.setMock(HttpCalloutMock.class, imcm);
    Test.startTest();
    String recordId = '111222333';
    ADG_InstallerMessage.getMessages(recordId);
    Test.stopTest();
  }

  @isTest
  static void testMessageResponse() {
    Test.startTest();
    ADG_InstallerMessage.MessageResponse response = new ADG_InstallerMessage.MessageResponse();
    response.messages = new List<ADG_InstallerMessage.Message>();
    response.success = true;
    response.error = '';
    Test.stopTest();
  }
}