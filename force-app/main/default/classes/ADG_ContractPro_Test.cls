@isTest
private class ADG_ContractPro_Test {
  @TestSetup
  static void setup() {
    Account account1 = new Account(Name = 'Jon Doe Contractors, LLC');
    insert account1;

    Account account2 = new Account(Name = 'Jane Doe Contractors, LLC');
    insert account2;

    Contact contact1 = new Contact(
      Email = 'james.doe@adgus.net',
      FirstName = 'James',
      LastName = 'Doe'
    );
    insert contact1;

    Contact contact2 = new Contact(
      Email = 'juan.doe@adgus.net',
      FirstName = 'Juan',
      LastName = 'Doe'
    );
    insert contact2;
  }

  @isTest
  static void testAssociateAccount() {
    Test.startTest();
    Account act1 = [SELECT name FROM Account WHERE name = 'Jon Doe Contractors, LLC'];
    System.assert(act1.Name == 'Jon Doe Contractors, LLC', 'Account 1 not found');
    Contact ct1 = [SELECT email, accountid FROM Contact WHERE email = 'james.doe@adgus.net'];
    System.assert(ct1.Email == 'james.doe@adgus.net', 'Contact 1 not found');
    System.assert(ct1.AccountId == null, 'Contact 1 already associated with an account');
    ct1.AccountId = act1.Id;
    update ct1;
    System.assert(ct1.AccountId == act1.Id, 'Contact 1 not associated with account 1');
    Test.stopTest();
  }

  @isTest
  static void testDisassociateAccount() {
    Test.startTest();
    Contact ct2 = [SELECT email, accountid FROM Contact WHERE email = 'juan.doe@adgus.net'];
    System.assert(ct2.Email == 'juan.doe@adgus.net', 'Contact 1 not found');
    ct2.AccountId = null;
    update ct2;
    System.assert(ct2.AccountId == null, 'Contact 2 already associated with an account');
    Test.stopTest();
  }

  @isTest
  static void testReassociateAccount() {
    Test.startTest();
    Account act1 = [SELECT name FROM Account WHERE name = 'Jon Doe Contractors, LLC'];
    Account act2 = [SELECT name FROM Account WHERE name = 'Jane Doe Contractors, LLC'];
    System.assert(act1.Name == 'Jon Doe Contractors, LLC', 'Account 1 not found');

    Contact ct1 = [SELECT email, accountid FROM Contact WHERE email = 'james.doe@adgus.net'];
    System.assert(ct1.Email == 'james.doe@adgus.net', 'Contact 1 not found');
    System.assert(ct1.AccountId == null, 'Contact 1 already associated with an account');

    ct1.AccountId = act1.Id;
    update ct1;
    System.assert(ct1.AccountId == act1.Id, 'Contact 1 not associated with account 1');

    ct1.AccountId = null;
    update ct1;
    System.assert(ct1.AccountId == null, 'Contact 1 already associated with an account');

    ct1.AccountId = act2.Id;
    System.assert(ct1.AccountId == act2.Id, 'Contact 1 not associated with account 2');
    Test.stopTest();
  }

  @isTest
  static void testContractProAccountEnable() {
    Test.startTest();
    Contact ct1 = [SELECT ContractPro_Account_Enabled__c FROM Contact WHERE email = 'james.doe@adgus.net'];
    System.assert(ct1.ContractPro_Account_Enabled__c == false, 'Contact 1 already has ContractProAccountEnable set to true');

    ct1.ContractPro_Account_Enabled__c = true;
    update ct1;

    System.assert(ct1.ContractPro_Account_Enabled__c == true, 'Contact 1 is not set to ContractProAccountEnable to true');
    Test.stopTest();
  }

  @isTest
  static void testContractProLoginCount() {
    Test.startTest();
    Account act1 = [SELECT ContractPro_Login_Count__c FROM Account WHERE name = 'Jon Doe Contractors, LLC'];
    Contact ct1 = [SELECT accountid FROM Contact WHERE email = 'james.doe@adgus.net'];
    Contact ct2 = [SELECT accountid FROM Contact WHERE email = 'juan.doe@adgus.net'];
    System.assert(act1.ContractPro_Login_Count__c == 0, 'ContractProLoginCount for account 1 is not 0');

    // Make a change to the Contact - cause trigger to run.
    ct1.AccountId = act1.Id;
    ct1.ContractPro_Account_Enabled__c = true;
    update ct1;
    
    ct2.AccountId = act1.Id;
    ct2.ContractPro_Account_Enabled__c = true;
    update ct2;
    
    // ContractProLoginCount should be 2.
    act1 = [SELECT ContractPro_Login_Count__c FROM Account WHERE name = 'Jon Doe Contractors, LLC'];
    System.assert(act1.ContractPro_Login_Count__c == 2, 'ContractProLoginCount for account 1 should be 2: ' + act1.ContractPro_Login_Count__c);

    // Make another change to the Contact - cause trigger to run.
    ct1.ContractPro_Account_Enabled__c = false;
    update ct1;

    // ContractProLoginCount should be 1.
    act1 = [SELECT ContractPro_Login_Count__c FROM Account WHERE name = 'Jon Doe Contractors, LLC'];
    System.assert(act1.ContractPro_Login_Count__c == 1, 'ContractProLoginCount for account 1 should be 1: ' + act1.ContractPro_Login_Count__c);

    Test.stopTest();
  }

  @isTest
  static void testContractProDeleteLoginCount() {
    Test.startTest();
    Account act1 = [SELECT ContractPro_Login_Count__c FROM Account WHERE name = 'Jon Doe Contractors, LLC'];
    Contact ct1 = [SELECT accountid FROM Contact WHERE email = 'james.doe@adgus.net'];
    Contact ct2 = [SELECT accountid FROM Contact WHERE email = 'juan.doe@adgus.net'];
    System.assert(act1.ContractPro_Login_Count__c == 0, 'ContractProLoginCount for account 1 is not 0');

    // Make a change to the Contact - cause trigger to run.
    ct1.AccountId = act1.Id;
    ct1.ContractPro_Account_Enabled__c = true;
    update ct1;
    
    ct2.AccountId = act1.Id;
    ct2.ContractPro_Account_Enabled__c = true;
    update ct2;
    
    // ContractProLoginCount should be 2.
    act1 = [SELECT ContractPro_Login_Count__c FROM Account WHERE name = 'Jon Doe Contractors, LLC'];
    System.assert(act1.ContractPro_Login_Count__c == 2, 'ContractProLoginCount for account 1 should be 2: ' + act1.ContractPro_Login_Count__c);

    delete ct1;
    delete ct2;

    // ContractProLoginCount should be 0.
    act1 = [SELECT ContractPro_Login_Count__c FROM Account WHERE name = 'Jon Doe Contractors, LLC'];
    System.assert(act1.ContractPro_Login_Count__c == 0, 'ContractProLoginCount should be 0: ' + act1.ContractPro_Login_Count__c);

    Test.stopTest();
  }
}