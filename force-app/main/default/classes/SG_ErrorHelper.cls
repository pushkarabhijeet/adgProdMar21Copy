/**********************************************************************
* Name:   	ErrorHelper
* Author: 	Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date: 	21 Oct 2012
* ======================================================
* ======================================================
* Purpose:                                                            
* This class is used to send emails upon errors. This class requires the custom setting called "Custom Apex Error Handler"
*
* ======================================================
* ======================================================
* History:                                                            
* VERSION	DATE            INITIALS	DESCRIPTION/FEATURES ADDED
* 1.0     	21 Oct 2012     CS			Initial Development           
*   
***********************************************************************/

public class SG_ErrorHelper {
	
	public static Boolean doLogError(String className, String exceptionName, Set<String> emailAddresses) 
	{
        if(emailAddresses == null) emailAddresses = new Set<String>();
        
        Boolean logError = false;
        
        try {
            Map<String,Custom_Apex_Error_Handler__c> settings = Custom_Apex_Error_Handler__c.getAll();
            System.debug('@@@SG: ErrorEmailHelper: getEmailAddresses: settings = ' + settings);
            for(Custom_Apex_Error_Handler__c setting : settings.values()) {
                
                System.debug('@@@SG: setting.Single_Apex_Class ' + setting.Single_Apex_Class__c);
                System.debug('@@@SG:                 className ' + className);
                
                Boolean noApexClass = false;
                Boolean noSingleException = false;
                Boolean sendEmail = false;
                                
                if(setting.Single_Apex_Class__c == null || setting.Single_Apex_Class__c.length() == 0) {
                    noApexClass = true;
                }
                
                if(setting.Single_Exception__c == null || setting.Single_Exception__c.length() == 0) {
                    noSingleException = true;
                }
                
                if(noApexClass && noSingleException) {
                    //no apex class or exception specified, send email
                    sendEmail = true;
                } else if(!noApexClass && !noSingleException) {
                    //send email only if exception and class match 
                    if ((className != null && className.equalsIgnoreCase(setting.Single_Apex_Class__c))
                        &&
                        (exceptionName != null && exceptionName.equalsIgnoreCase(setting.Single_Exception__c)) ) {
                            sendEmail = true;
                            
                        }
                } else if(!noApexClass && noSingleException) {
                    //only an Apex Class, then send exception if class match
                    //send email only if exception and class match 
                    if ((className != null && className.equalsIgnoreCase(setting.Single_Apex_Class__c))) {
                            sendEmail = true;                           
                    }
                } else {
                    sendEmail = false;
                }
                              
                
                if( sendEmail ) {
                    
                    if(setting.Email__c != null && !setting.Name.startsWith('CurrentUser')) {
                        System.debug('@@@SG: Not current user, adding email address.');
                        emailAddresses.add( setting.Email__c );
                    } else if(setting.Name.startsWith('CurrentUser')) {
                        System.debug('@@@SG: Trying to email current user.');
                        if(SG_EmailUtils.getCurrentUser() != null) {
                            System.debug('@@@SG: Current user identified.');
                            String email = SG_EmailUtils.getCurrentUser().Email;
                            if(email != null && email.length() > 0) {
                                System.debug('@@@SG: Current user email added.');
                                emailAddresses.add( email );
                            }
                        } 
                    }
                    
                 	if(setting.Log_Exceptions__c)
                 	{
                 		logError = true;
                 	}   
                }   
            }
            
        } catch (Exception exp) {
            //Never throw an exception, simply return the default value
            System.debug('@@@ErrorEmailHelper: getEmailAddresses: Exception: ' + exp.getMessage());
        }
        
        System.debug('@@@SG: ErrorEmailHelper: getEmailAddresses: emailAddresses ' + emailAddresses);
        return logError;
    }
	
    private static void notifyOnError(String className, String subject, String errorMessage, Set<String> emailAddressSet) {    	
    	List<String> emailAddresses = new List<String>();
        emailAddresses.addAll(emailAddressSet);

        if(Limits.getEmailInvocations() == Limits.getLimitEmailInvocations()) {
            System.debug('@@@SG: Can not send any more emails on errors in this context: className ' + className + ' subject ' + subject + ' errorMessage ' + errorMessage);
            return;
        } else if(Limits.getEmailInvocations() + 1 == Limits.getLimitEmailInvocations()) {          
            errorMessage = 'WARNING: Email Invocation Limit Reached. No more emails can be sent for this context. If there are further emails for this context they will not be sent. \n' + errorMessage;
            System.debug('@@@SG: ' + errorMessage + ' Context: className ' + className + ' subject ' + subject + ' errorMessage ' + errorMessage);     
                        
        }
        try
        {
        	if(subject == null)
        	{
        		subject = 'Custom Apex Error: ' + className;
        	}
        	SG_EmailUtils.sendTextEmail(emailAddresses, subject, errorMessage);
        }
        catch(Exception exp)
        {
        	//The entire point of this helper is to ensure zero exceptions.
        	SG_DisplayUtils.debug('SG_ErrorHelper', 'notifyOnError', exp);        	
        }
    }
	
    public static void notifyOnError( String className, String subject, Exception e ) {
        String exceptionText = SG_DisplayUtils.exceptionToString( className, e );
        notifyOnError( className, e.getTypeName(), subject, exceptionText );
    }

    public static void notifyOnError(String className, String exceptionName, String subject, String errorMessage) {
        Set<String> emailAddresses = new Set<String>();
        Boolean logErrors = doLogError(className,exceptionName,emailAddresses);
        
        if(emailAddresses != null && emailAddresses.size() > 0)
        {
        	notifyOnError(className, subject, errorMessage, emailAddresses);
        }        
        else if(logErrors)
        {
        	// save error in database
        	logErrorToDB(className, subject, errorMessage);
        }
        
    }
    
    public static void notifyOnError(String className, String exceptionName, String subject, String errorMessage, Set<Id> userIds) {
        Set<String> emailAddresses = new Set<String>();
        Boolean logErrors = doLogError(className,exceptionName,emailAddresses);
        
        if(userIds != null && userIds.size() > 0)
        {
	        for(User usr : SG_EmailUtils.getUsersFromIds(userIds)) {
	            emailAddresses.add(usr.Email);
	        }
        }
                
        if(emailAddresses != null && emailAddresses.size() > 0)
        {
        	notifyOnError(className, subject, errorMessage, emailAddresses);
        }
        
        if(logErrors)
        {
        	// save error in database
        	logErrorToDB(className, subject, errorMessage);
        }   
    }


	public static void logErrorToDB(String origin, String shortDescription, String error){
		// save errors to database always @future.  Unless this call is made during an @future call.
		if( System.isFuture() || System.isScheduled() || System.isQueueable() || System.isBatch() )
		{
			saveErrorToDB(origin, shortDescription, error);
		}
		else
		{
			saveErrorToDB_FUTURE(origin, shortDescription, error);
		}
	}
	
	@future
	private static void saveErrorToDB_FUTURE(String origin, String shortDescription, String error)
	{
		saveErrorToDB(origin, shortDescription, error);
	}
	
	private static void saveErrorToDB(String origin, String shortDescription, String error)
	{
		Error_Log__c err = new Error_Log__c();
		err.Origin__c = origin;
		Integer length = 0;
		if(shortDescription != null)
		{
			length = shortDescription.length();	
		}
		length = Math.min(255,length);		
		err.Description__c = shortDescription.substring(0,length);

		if( error != null && error.length() > 32767 ) {
			error = error.substring( 0, 32767 );
		}
		err.Error__c = error;
		
		insert err;	
	}

}