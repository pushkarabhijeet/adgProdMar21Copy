/**********************************************************************
* Name:     EmailUtils
* Author:   Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date:     21 Oct 2012
* ======================================================
* ======================================================
* Purpose:                                                            
* This class is used to send emails
*
* ======================================================
* ======================================================
* History:                                                            
* VERSION   DATE            INITIALS    DESCRIPTION/FEATURES ADDED
* 1.0       21 Oct 2012     CS          Initial Development           
* 1.1       25 Jan 2017     CS          Added without sharing
*
***********************************************************************/

public without sharing class SG_EmailUtils {
      
    public static final Integer EMAIL_TO_LIMIT = 25;      

    private static User currentUser;
    private static Map<Id,User> userMap;

    public static Integer getUserMapSize(){
        if(userMap != null) {
            return userMap.size();
        } else {
            return -1;
        }
    }
   
    // This is used to cache user information
    public static User getCurrentUser() {
        if(currentUser == null) {
            currentUser = [SELECT Id,Email FROM User WHERE Id = :UserInfo.getUserId()];
            if(userMap == null) userMap = new Map<Id,User>();
            userMap.put(currentUser.Id,currentUser);
        }
        return currentUser;
    }
    
    //This method will cache requests to get users in an attempt to reduce the number of queries
    //If the user is in the cache there is no need for a new query
    public static List<User> getUsersFromIds(Set<Id> userIds){
        
        if(userMap == null) userMap = new Map<Id,User>();
        
        List<Id> userIdsNotFound = new List<Id>();
        List<User> users = new List<User>();
        
        for(Id userId : userIds) {
            if(userMap.containsKey(userId)) {
                users.add(userMap.get(userId));
            } else {
                userIdsNotFound.add(userId);
            }
        }
        
        if(userIdsNotFound.size() > 0) {
            //if(Limits.getQueries() < Limits.getLimitQueries()) {          
            Map<Id,User> tmpUserMap = new Map<Id,User>([SELECT Id,Email FROM User WHERE Id IN :userIdsNotFound]);
            if(tmpUserMap != null && tmpUserMap.size() > 0) {
                users.addAll(tmpUserMap.values());
                userMap.putAll(tmpUserMap);
            }
            //} //ELSE ERROR! Can't do any more queries
        }
        
        return users;
    }
     
    public static void sendEmailWithStandardAttachments(List<String> recipients,String emailSubject,String body,Boolean useHTML,List<Id> attachmentIDs) {
        List<Attachment> stdAttachments = [SELECT id, name, body FROM Attachment WHERE Id IN:attachmentIDs];
        sendEmailWithStandardAttachments(recipients, emailSubject, body, useHTML, stdAttachments);
    }
    
    public static void sendEmailWithStandardAttachments(List<String> recipients,String emailSubject,String body,Boolean useHTML,List<Attachment> stdAttachments) {
        List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
        
        for(Attachment attachment : stdAttachments) {
            Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
            fileAttachment.setFileName(attachment.Name);
            fileAttachment.setBody(attachment.Body);
            fileAttachments.add(fileAttachment);
        }
        sendEmail(recipients, emailSubject, body, useHTML, fileAttachments);
    }
    
    @TestVisible
    private static Contact getNoReplyContact()
    {
    	Contact con = new Contact();
		con.FirstName = 'No';
		con.LastName = 'Reply';
		String companyName = UserInfo.getOrganizationName().deleteWhitespace();
		//companyName = companyName.replace',','');
		//companyName = companyName.replace('.','');
		companyName = companyName.replaceAll('[^a-zA-Z0-9]+','');
		con.Email = 'no-reply@' + companyName + '.com';
		insert con;
		return con;    	
    }
    
    public static void sendEmailtemplate(Id whatId, Id templateId, Id primaryContactId, List<String> ccEmails, List<Id> attachmentIds)
    {
    	List<Attachment> stdAttachments = [SELECT id, name, body FROM Attachment WHERE Id IN:attachmentIDs];
    	sendEmailTemplate(whatId,templateId,primaryContactId,ccEmails,stdAttachments);
    }
    
    public static void sendEmailTemplate(Id whatId, Id templateId, Id primaryContactId, List<String> ccEmails, List<Attachment> attachments)
    {
    	system.debug('@@@ ccEmails = ' + ccEmails);
		system.debug('@@@ whatId = ' + whatId);
		system.debug('@@@ templateId = ' + templateId);
		system.debug('@@@ primaryContactId = ' + primaryContactId);
		
		Contact noReplyContact = null;
		
        if(Limits.getEmailInvocations() == Limits.getLimitEmailInvocations()) 
        {
            throw new EmailException('Reached Email Invocation Limit.');                 
        }
        
        // Create a new single email message object
        // that will send out a single email to the addresses in the To, CC & BCC list.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();        
        
        //Constant settings
        mail.setBccSender(false);       
        mail.setUseSignature(false);

		//If we're using a templateId and a whatId then...
		if(templateId != null && whatId != null)
		{	
			if((ccEmails == null || ccEmails.size() == 0) && primaryContactId == null)
			{
				throw new EmailException('Must specify at least one reciepient.');
			}
						
			if(primaryContactId == null)
			{
				noReplyContact = getNoReplyContact();
				primaryContactId = noReplyContact.Id;
			}
						
			mail.setTargetObjectId(primaryContactId);
			
			//the email is saved as an activity.
			if(!((String)whatId).startsWith('00U')) //We can't save an activity for Event Notifications
			{
        		mail.setSaveAsActivity(true);
			}                       	               
			mail.setTemplateId(templateId);			
			mail.setWhatId(whatId);
			
			Set<String> recipientSet =	new Set<String>();
			if(ccEmails != null)
			{   
				for(String emailAddr : ccEmails)
		        {
		            if(isValidEmailAddress(emailAddr))
		            {
		                recipientSet.add(emailAddr);
		            }
		        }
		        ccEmails.clear();
        		ccEmails.addAll(recipientSet);      				
			}
			
			if(ccEmails != null) //Check again after the emails have been validated
			{
				mail.setCcAddresses(ccEmails);
			}																	
		}	
		else
		{
			throw new EmailException('FATAL ERROR: null values: whatId = ' + whatId + ' templateId = ' + templateId + ' primaryContactId = ' + primaryContactId);
		}
		
		// Specify FileAttachments
        if(attachments != null && attachments.size() > 0) 
        {
        	List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
        
       		for(Attachment attachment : attachments) {
	            Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
	            fileAttachment.setFileName(attachment.Name);
	            fileAttachment.setBody(attachment.Body);
	            fileAttachments.add(fileAttachment);
        	}
        	
            mail.setFileAttachments(fileAttachments);
        }
          
        // Send the email you have created.
        try
        {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }, false);
            
            String allErrorMessage = '';
            for(Messaging.SendEmailResult result : results)
            {            	
            	if(!result.isSuccess())
            	{            		            		
            		List<Messaging.SendEmailError> errors = result.getErrors();
            		for(Messaging.SendEmailError err : errors)
            		{
            			allErrorMessage += err.getMessage() + '\n';            			            			
            		}            		
            	}            	
            }
            if(allErrorMessage != null && allErrorMessage.trim().length() > 2)
            {
            	allErrorMessage = 'Error Message(s):/n' + allErrorMessage;
            	throw new EmailException('There were some errors in sending the auto-notification email.\n' + 
                                     'The template used was: ' + templateId + ' and the object Id sent was:' + 
                                     whatId + '/n'+ allErrorMessage);                  
            }
        }
        catch (Exception exp)        
        {
            if(System.Test.isRunningTest())
            {
                //Ignore exceptions during tests
            }
            else
            {
            	if(noReplyContact != null && noReplyContact.Id != null) delete noReplyContact;
                throw exp;
            }        
        }
                
        if(noReplyContact != null && noReplyContact.Id != null) delete noReplyContact;       
    }
     
    public static void sendTextEmail(List<String> recipients,String emailSubject,String textBody) { 
        sendEmail(recipients, emailSubject, textBody, false, null);
    }
    
    public static void sendHTMLEmail(List<String> recipients,String emailSubject,String htmlBody) { 
        sendEmail(recipients, emailSubject, htmlBody, true, null);
    }
    
    public static void sendEmail(List<String> recipients,String emailSubject,String body,Boolean useHTML,List<Messaging.EmailFileAttachment> fileAttachments) { 
        
        system.debug('@@@ recipients = ' + recipients);
		system.debug('@@@ emailSubject = ' + emailSubject);
		system.debug('@@@ useHTML = ' + useHTML);
		system.debug('@@@ fileAttachments = ' + fileAttachments);
        
        if(recipients == null)
        {     
            return;      
            //throw new EmailException('Null recipients not allowed.'); 
        }
        
        if(recipients.size() == 0 || recipients.size() > EMAIL_TO_LIMIT) 
        {
            return;
            //throw new EmailException('Invalid number of recipients: ' + recipients.size());  
        }
        
        if(Limits.getEmailInvocations() == Limits.getLimitEmailInvocations()) 
        {
            throw new EmailException('Reached Email Invocation Limit.');                 
        }
        
        // Create a new single email message object
        // that will send out a single email to the addresses in the To, CC & BCC list.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();        
        //the email is not saved as an activity.
        mail.setSaveAsActivity(false);
        
        // Assign the addresses for the To lists to the mail object.
        Set<String> recipientSet = new Set<String>();        
        for(String emailAddr : recipients)
        {
            if(isValidEmailAddress(emailAddr))
            {
                recipientSet.add(emailAddr);
            }
        }        
        recipients.clear();
        recipients.addAll(recipientSet);
        
        if(recipients.size() == 0 || recipients.size() > EMAIL_TO_LIMIT) 
        {
            throw new EmailException('Invalid number of recipients: ' + recipients.size());  
        }
        
        mail.setToAddresses(recipients);          
        
        // Specify the subject line for your email address.
        mail.setSubject(emailSubject);
        // Set to True if you want to BCC yourself on the email.
        mail.setBccSender(false);
        // The email address of the user executing the Apex Code will be used.
        mail.setUseSignature(false);
        if (useHTML) 
        {
            // Specify the html content of the email.
            mail.setHtmlBody(body);
            mail.setPlainTextBody(body.stripHtmlTags());
        } 
        else 
        {
            // Specify the text content of the email.
            mail.setPlainTextBody(body);
        }
        // Specify FileAttachments
        if(fileAttachments != null && fileAttachments.size() > 0) 
        {
            mail.setFileAttachments(fileAttachments);
        }
           
        // Send the email you have created.
        try
        {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        catch (Exception exp)        
        {
            if(System.Test.isRunningTest())
            {
                //Ignore exceptions during tests
            }
            else
            {
                throw exp;
            }        
        }
    }
    
    /**
     * null     => false
     * ''       => false
     * ' '      => false
     * 'x'      => false
     * 'x@'     => false
     * 'x@x'    => false
     * 'x@x.x'  => true
     */
    public static Boolean isValidEmailAddress(String str){
        if(str != null && str.trim() != null && str.trim().length() > 0){
            String[] split = str.split('@');
            if(split != null && split.size() == 2){
                split = split[1].split('\\.');
                if(split != null && split.size() >= 2){
                    return true;
                }
            }
        }
        return false;
    }

    public static Boolean isNotValidEmailAddress(String str){
        return !isValidEmailAddress(str);
    }
    
    public class EmailException extends Exception{}

}