@IsTest
public with sharing class ADG_ContractProRegister_Test {
    @TestSetup
    static void setup() {
      ADG_TestSetup.Setup();
    }

    @IsTest
    static void testDoesContactExist() {
        System.assert(ADG_ContractProRegister.doesContactExist('123-123-1234') == false);
    }

    @IsTest
    static void testGetAccountList() {
        System.assert(!ADG_ContractProRegister.getAccountList('Doe').isEmpty());
        System.assert(ADG_ContractProRegister.getAccountList('99999').isEmpty());
    }

    @IsTest
    static void testSubmitActivationRequest() {
        ADG_ContractProRegisterMockup m = new ADG_ContractProRegisterMockup();
        Test.setMock(HttpCalloutMock.class, m);
        ADG_ContractProRegister.ActivationRequest req = new ADG_ContractProRegister.ActivationRequest();
        req.account_id = 'abc';
        req.first_name = 'a';
        req.last_name = 'a';
        req.phone = '123-123-1234';
        ADG_ContractProRegister.submitActivationRequest(req);
    }

}