public with sharing class ADG_ContractProRegister {

    // matched fields from GenericResponse
    public class RegisterResponse {
        @AuraEnabled
        public Boolean success { get; set; }
        @AuraEnabled
        public String error_message { get; set; }
    }

    public class ActivationRequest {
        @AuraEnabled
        public String account_id { get; set; }
        @AuraEnabled
        public String first_name { get; set; }
        @AuraEnabled
        public String last_name { get; set; }
        @AuraEnabled
        public String phone { get; set; }
    }

    @AuraEnabled
    public static RegisterResponse submitActivationRequest(ActivationRequest activateReq) {
        HttpRequest request = new HttpRequest();
        String endpoint = 'callout:ADG_IHAPI/v2/account/request-activation';
        request.setEndpoint(endpoint);
        request.setHeader('X-Api-Key', '{!$Credential.Password}');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type', 'application/json');
        request.setMethod('POST');
        request.setBody(JSON.serialize(activateReq));
        Http http = new Http();
        HttpResponse response = http.send(request);
        String jsonResponse = response.getBody();
        RegisterResponse result = (RegisterResponse) JSON.deserialize(
            jsonResponse,
            RegisterResponse.class
        );
        return result;
    }

    @AuraEnabled
    public static Boolean doesContactExist(String phone) {
        String q = 'FIND :phone IN Phone FIELDS RETURNING Contact(Id, Phone, FirstName, LastName)';
        List<List <sObject>> contacts = search.query(q);
        return (!contacts[0].isEmpty());
    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactList() {
        return [SELECT Id, FirstName, LastName, Title, Phone, Email FROM Contact LIMIT 5];
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountList(String searchKey) {
        List<Account> results = new List<Account>();
        if (String.isBlank(searchKey)) { return results; }
        if (searchKey.isNumeric()){
            String key = '%:' + searchKey;
            results = [
                SELECT Id, Name, Account_Short_Name__c, Installer__c, Entity__c
                FROM Account
                WHERE Installer__c LIKE :key
                    AND RecordType.Name = 'Installer Company'
                LIMIT 100
            ]; 
        }
        else {
            String key = '%' + searchKey + '%';
            results = [
                SELECT Id, Name, Account_Short_Name__c, Installer__c, Entity__c
                FROM Account
                WHERE Name LIKE :key 
                    AND RecordType.Name = 'Installer Company'
                    AND Installer__c != null
                LIMIT 100
            ];
        }
        return results;
    }
}