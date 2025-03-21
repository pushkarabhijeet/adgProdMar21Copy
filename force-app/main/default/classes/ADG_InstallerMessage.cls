public with sharing class ADG_InstallerMessage {
    public with sharing class Message {
        @AuraEnabled
        public String server_message_id { get; set;}
        @AuraEnabled
        public String message_text { get; set; }
        @AuraEnabled
        public Integer sender_type { get; set; }
        @AuraEnabled
        public String sent_by_id { get; set; }
        @AuraEnabled
        public String installer_account_id { get; set; }
        @AuraEnabled
        public String server_timestamp { get; set; }
        @AuraEnabled
        public String display_name { get; set; }
        @AuraEnabled
        public Boolean is_owner { get; set; } 
    }

    public class MessageResponse {
        @AuraEnabled
        public List<Message> messages { get; set; }
        @AuraEnabled
        public Boolean success { get; set; }
        @AuraEnabled
        public String error { get; set; }
    }

    public class MessageRequirements {
        public String accountId { get; set; }
        public String fsmUserId { get; set;}
        public List<Contact> contacts { get; set; }
    }

    @TestVisible
    static String getContactName(String contactId) {
        String contactName = null;
        try {
            contactName = [SELECT Name FROM Contact WHERE Id = :contactId].name;
        } catch(Exception e) {
            contactName = 'Installer ' + contactId;
        }
        return contactName;
    }

    @TestVisible
    static String getUserName(String id) {
        String userName = null;
        try {
            userName = [SELECT Name from User WHERE id = :id].name;
        } catch(Exception e) {
            userName = 'FM ' + id;
        }
        return userName;
    }

    public static MessageRequirements getMessagePrereqs(String workOrderId) {

        MessageRequirements reqs = new MessageRequirements();
        try {
            WorkOrder wo = [SELECT Installer_Account__r.Id, Field_Service_Manager_ID_formula__c FROM WorkOrder WHERE Id = :workOrderId];
            reqs.accountId = wo.Installer_Account__r.Id;
            reqs.fsmUserId = wo.Field_Service_Manager_ID_formula__c;
        } catch(Exception e) {}

        if (reqs.accountId == null) return reqs;

        try {
            List<Contact> contacts = [SELECT Id FROM Contact WHERE Account.Id = :reqs.accountId AND ContractPro_Account_Enabled__c = true];
            reqs.contacts = contacts;
        } catch(Exception e) {}
        return reqs;
    }

    @AuraEnabled
    public static Boolean hasInstallerAccount(String workOrderId) {
        MessageRequirements reqs = getMessagePrereqs(workOrderId);
        return (reqs.contacts != null && !reqs.contacts.isEmpty());
    }

    @TestVisible
    static void formatMessages(List<Message> messages) {
        String uid = UserInfo.getUserId();
        Map<String, String> userDisplayNames = new Map<String, String>();
        for (Message m : messages) {
            String displayName = '[Unknown]';
            if (userDisplayNames.containsKey(m.sent_by_id)) {
                displayName = userDisplayNames.get(m.sent_by_id);
            } else {
                if (m.sender_type == 0 ) {
                    displayName = getContactName(m.sent_by_id);
                } else {
                    displayName = getUserName(m.sent_by_id);
                }
                userDisplayNames.put(m.sent_by_id, displayName);
            }

            m.display_name = displayName;
            m.is_owner = false;

            if (m.sent_by_id == uid) {
                m.is_owner = true;
            }
        }
    }

    @TestVisible
    static HttpRequest makeMessageRequest(String endPoint, String contentType) {
        HttpRequest request = new HttpRequest();
        String host = 'callout:ADG_IHAPI/v2/messages/';
        request.setEndpoint(host + endPoint);
        request.setHeader('X-Api-Key', '{!$Credential.Password}');
        request.setHeader('Content-Type', contentType);
        request.setHeader('Accept', 'application/json');
        return request;
    }

    @AuraEnabled
    public static MessageResponse getMessages(String recordId) {
        HttpRequest request = makeMessageRequest('fms/get/' + recordId, 'application/json');
        request.setMethod('GET');
        Http http = new Http();
        HttpResponse response = http.send(request);
        String jsonResponse = response.getBody();

        MessageResponse messageResponse = new MessageResponse();
        if (response.getStatusCode() != 200) {
            messageResponse.success = false;
            messageResponse.error = 'Server error';
            return messageResponse;
        }

        List<Message> results = (List<Message>) JSON.deserialize(
            jsonResponse,
            List<Message>.class
        );
        formatMessages(results);
        messageResponse.messages = results;
        messageResponse.success = true;
        return messageResponse;
    }

    @AuraEnabled
    public static MessageResponse submitMessage(String workOrderId, String senderMessageId, String message) {

        MessageRequirements reqs = getMessagePrereqs(workOrderId);
        MessageResponse messageResponse = new MessageResponse();
        if (reqs.accountId == null) {
            messageResponse.error = 'Installer Account not assigned to WorkOrder';
            return messageResponse;
        }
        if (reqs.contacts == null || reqs.contacts.isEmpty()) {
            messageResponse.error = 'Contract Pro login not found for installer';
            return messageResponse;
        }

        HttpRequest request = makeMessageRequest('fms/send/' + workOrderId, 'application/x-www-form-urlencoded');
        request.setMethod('POST');
        String formBody = 'text=' + EncodingUtil.urlEncode(message, 'UTF-8');
        formBody += '&sender_message_id=' + EncodingUtil.urlEncode(senderMessageId, 'UTF-8');
        formBody += '&sender_timestamp=' + EncodingUtil.urlEncode(json.serialize(datetime.now()).remove('"'), 'UTF-8');
        formBody += '&sent_by_id=' + EncodingUtil.urlEncode(UserInfo.getUserId(), 'UTF-8');
        request.setBody(formBody);
        Http http = new Http();
        HttpResponse response = http.send(request);
        String jsonResponse = response.getBody();

        if (response.getStatusCode() != 200) {
            messageResponse.success = false;
            messageResponse.error = 'Server error';
            return messageResponse;
        }

        List<Message> results = (List<Message>) JSON.deserialize(
            jsonResponse,
            List<Message>.class
        );
        formatMessages(results);
        messageResponse.messages = results;
        messageResponse.success = true;
        return messageResponse;
    }
}