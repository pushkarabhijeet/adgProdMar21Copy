@IsTest
private class SG_EmailUtils_Test {

    static testMethod void testsendEmail_test() {
        List<String> recepients=new String[]{'test@test.com','test2@test.com'};
        SG_EmailUtils.sendTextEmail(recepients,'Test method', 'This is to test the sendTextNotificationEmail method');
        SG_EmailUtils.sendHTMLEmail(recepients,'Test method', 'This is to test the sendTextNotificationEmail method');
    } 
    
    static testMethod void testsendEmailNoReceipients_test() {
        List<String> recepients=null;
        SG_EmailUtils.sendTextEmail(recepients,'Test method', 'This is to test the sendTextNotificationEmail method');
        
        recepients=new List<String>();
        SG_EmailUtils.sendHTMLEmail(recepients,'Test method', 'This is to test the sendTextNotificationEmail method');
    }
    
    static testMethod void testsendEmailWithAttachment_test() {
        List<String> recepients=new String[]{'test@test.com','test2@test.com'};
        List<Attachment> stdAttachments = new List<Attachment>();
        Attachment a = new Attachment();
        a.Name = 'Test';
        a.Body = EncodingUtil.base64Decode('Test Body');
        stdAttachments.add(a);
        SG_EmailUtils.sendEmailWithStandardAttachments(recepients,'Test method', 'This is to test the sendTextNotificationEmail method',false,stdAttachments);
    }
    
    static testMethod void testsendEmailWithAttachmentIDs_test() {
        List<String> recepients=new String[]{'test@test.com','test2@test.com'};
        List<ID> stdAttachments = new List<ID>();
               
        SG_TestDataGenerator dataUtils = new SG_TestDataGenerator();
        Account foo = dataUtils.getAccounts(true)[0];
                
        Attachment a = new Attachment();
        a.ParentId = foo.Id;
        a.Name = 'Test';
        a.Body = EncodingUtil.base64Decode('Test Body');
        insert a;
        stdAttachments.add(a.Id);
        SG_EmailUtils.sendEmailWithStandardAttachments(recepients,'Test method', 'This is to test the sendTextNotificationEmail method',false,stdAttachments);
    }

    private static testmethod void testIsNotValidEmailAddress(){
        String str = null;
        System.assertEquals(true,SG_EmailUtils.isNotValidEmailAddress(str));
        System.assertEquals(true,SG_EmailUtils.isNotValidEmailAddress('  '));
        System.assertEquals(true,SG_EmailUtils.isNotValidEmailAddress('x'));
        System.assertEquals(true,SG_EmailUtils.isNotValidEmailAddress('x@'));
        System.assertEquals(true,SG_EmailUtils.isNotValidEmailAddress('x@x'));
        System.assertEquals(false,SG_EmailUtils.isNotValidEmailAddress('x@x.x'));
    }


    static testMethod void test_getCurrentUser() {
        User u = SG_EmailUtils.getCurrentUser();
        System.assertEquals(UserInfo.getUserId(),u.Id);                     
    }
    
    static testMethod void test_getCurrentUser_NEW() {
        SG_TestDataGenerator data = new SG_TestDataGenerator();
        User newUsr = data.getUsers(null)[0];
        System.runAs(newUsr){           
            System.assertEquals(UserInfo.getUserId(),SG_EmailUtils.getCurrentUser().Id);
        }                       
    }

    static testMethod void test_getUserMapSize_Empty() {
        System.assertEquals(-1,SG_EmailUtils.getUserMapSize());
    }

    static testMethod void test_getUsersFromIds() {
        SG_TestDataGenerator data = new SG_TestDataGenerator();
        User newUsr = data.getUsers(null)[0];
        System.assertNotEquals(null,newUsr.Id);
        
        Set<Id> userIds = new Set<Id>();
        userIds.add(newUsr.Id);
        
        List<User> users = SG_EmailUtils.getUsersFromIds(userIds);
        
        System.debug('users = ' + users);
        System.assertEquals(1,users.size());
        System.assertEquals(newUsr.Id,users[0].Id);
        System.assertEquals(1,SG_EmailUtils.getUserMapSize());
        
        //Want to see that the cache is working
        List<User> usersDuplicate = SG_EmailUtils.getUsersFromIds(userIds);
        System.assertEquals(1,SG_EmailUtils.getUserMapSize());     
    }

	static testMethod void test_sendEmailTemplate() 
	{
		User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    	// plus any other fields that you want to set, but we don't really care if their are merge fields
    	EmailTemplate validEmailTemplate = new EmailTemplate();
		validEmailTemplate.isActive = true;
		validEmailTemplate.Name = 'testUnique123521095';
		validEmailTemplate.DeveloperName = 'testUnique123521095';
		validEmailTemplate.TemplateType = 'text';
		validEmailTemplate.FolderId = UserInfo.getUserId(); 
		System.runAs(u)
    	{
			insert validEmailTemplate;
    	}
    	
    	List<String> recepients=new String[]{'test@test.com','test2@test.com'};
        List<ID> stdAttachments = new List<ID>();
        
        SG_TestDataGenerator dataUtils = new SG_TestDataGenerator();
        dataUtils.accountNum = 1;
        dataUtils.contactNum = 1;
        Account foo = dataUtils.getAccounts(true)[0];
		Contact person = dataUtils.getContacts(true)[0];
        
        Attachment a = new Attachment();
        a.ParentId = foo.Id;
        a.Name = 'Test';
        a.Body = EncodingUtil.base64Decode('Test Body');
        insert a;
        stdAttachments.add(a.Id);
        
        List<Id> attachmentIds = new List<Id>();
        attachmentIds.add(a.Id);
        
        SG_EmailUtils.sendEmailtemplate(foo.Id, validEmailTemplate.Id, person.Id, recepients, attachmentIds);                    	
	}
    
    static testMethod void test_sendEmailTemplateNulls() 
	{
		User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
    	// plus any other fields that you want to set, but we don't really care if their are merge fields
    	EmailTemplate validEmailTemplate = new EmailTemplate();
		validEmailTemplate.isActive = true;
		validEmailTemplate.Name = 'testUnique123521095';
		validEmailTemplate.DeveloperName = 'testUnique123521095';
		validEmailTemplate.TemplateType = 'text';
		validEmailTemplate.FolderId = UserInfo.getUserId(); 
		System.runAs(u)
    	{
			insert validEmailTemplate;
    	}
    	
    	List<String> recepients=new String[]{'test@test.com','test2@test.com'};
        List<ID> stdAttachments = new List<ID>();
        
        SG_TestDataGenerator dataUtils = new SG_TestDataGenerator();
        dataUtils.accountNum = 1;
        dataUtils.contactNum = 1;
        Account foo = dataUtils.getAccounts(true)[0];
		Contact person = dataUtils.getContacts(true)[0];
        
        Attachment a = new Attachment();
        a.ParentId = foo.Id;
        a.Name = 'Test';
        a.Body = EncodingUtil.base64Decode('Test Body');
        insert a;
        stdAttachments.add(a.Id);
        
        List<Id> attachmentIds = new List<Id>();
        attachmentIds.add(a.Id);
        Boolean hadError = false;
        try
        {
        	SG_EmailUtils.sendEmailtemplate(foo.Id, validEmailTemplate.Id, null, null, attachmentIds);
        } 
        catch(Exception exp)
        {
        	hadError = true;
        }
        System.assert(hadError,'With null contact and ccList this should throw an exception, but it did not.');                    	
	}
	
	static testMethod void test_getNoReplyContact()
	{
		SG_EmailUtils.getNoReplyContact();
	}
    
}