@IsTest
public with sharing class SG_ErrorHelper_Test {
        
    static testMethod void test_notifyOnErrorCurrentUser() {        
        Custom_Apex_Error_Handler__c setting = new Custom_Apex_Error_Handler__c();
        setting.Name = 'CurrentUser_CustomSettingNameTest';
        setting.Single_Apex_Class__c = 'testClasstest1234';
        setting.Log_Exceptions__c = true;
        insert setting;
        
        SG_ErrorHelper.notifyOnError(setting.Single_Apex_Class__c,'ExceptionName','subject','errorbody');
    }

    static testMethod void test_notifyOnErrorWithUserIds() {        
        Custom_Apex_Error_Handler__c setting = new Custom_Apex_Error_Handler__c();
        setting.Name = 'CustomSettingNameTest';
        setting.Email__c = 'testOne@TesterNoVoidWork.net';
        setting.Single_Apex_Class__c = 'testClasstest1234';
        setting.Log_Exceptions__c = true;
        insert setting;
        
        SG_TestDataGenerator data = new SG_TestDataGenerator();
        User u = data.getUsers(null)[0];
        Set<Id> userIds = new Set<Id>();
        System.assertNotEquals(null,u.Id);
        userIds.add(u.Id);
        SG_ErrorHelper.notifyOnError(setting.Single_Apex_Class__c,'exception','subject','errorbody',userIds);     
    }

    static testMethod void test_notifyOnError() {       
        Custom_Apex_Error_Handler__c setting = new Custom_Apex_Error_Handler__c();
        setting.Name = 'CustomSettingNameTest';
        setting.Email__c = 'testOne@TesterNoVoidWork.net';
        setting.Single_Apex_Class__c = 'testClasstest1234';
        setting.Single_Exception__c = 'exception';
        setting.Log_Exceptions__c = true;
        insert setting;
        
        SG_ErrorHelper.notifyOnError(setting.Single_Apex_Class__c,setting.Single_Exception__c,'subject','errorbody');
    }

/*    
    static testMethod void test_notifyOnErrorSimple() {       
        Custom_Apex_Error_Handler__c setting = new Custom_Apex_Error_Handler__c();
        setting.Name = 'CustomSettingNameTest';
        setting.Email__c = 'testOne@TesterNoVoidWork.net';
        setting.Single_Apex_Class__c = 'testClasstest1234';
        setting.Single_Exception__c = 'exception';
        insert setting;
        
        SG_ErrorHelper.notifyOnError(setting.Single_Apex_Class__c,setting.Single_Exception__c,'errorbody');
    }
*/
   
    static testMethod void test_notifyOnErrorException() {       
        Custom_Apex_Error_Handler__c setting = new Custom_Apex_Error_Handler__c();
        setting.Name = 'CustomSettingNameTest';
        setting.Email__c = 'testOne@TesterNoVoidWork.net';
        setting.Single_Apex_Class__c = 'testClasstest1234';
        setting.Single_Exception__c = 'exception';
        setting.Log_Exceptions__c = true;
        insert setting;
        
        SG_ErrorHelper.notifyOnError(setting.Single_Apex_Class__c,setting.Single_Exception__c,new SG_DisplayUtils.DisplayUtilsException('test'));
    }
    
    static testMethod void test_notifyOnErrorFALSE() {       
        Custom_Apex_Error_Handler__c setting = new Custom_Apex_Error_Handler__c();
        setting.Name = 'CustomSettingNameTest';
        setting.Email__c = 'testOne@TesterNoVoidWork.net';
        setting.Single_Apex_Class__c = '';
        setting.Single_Exception__c = 'exception';
        setting.Log_Exceptions__c = true;
        insert setting;
        
        SG_ErrorHelper.notifyOnError('class','exception','subject','errorbody');
    }
    
    static testMethod void test_notifyOnError_HighVolume() {
        Custom_Apex_Error_Handler__c setting = new Custom_Apex_Error_Handler__c();
        setting.Name = 'CustomSettingNameTest';
        setting.Email__c = 'testVolume@TesterNoVoidWork.net';
        setting.Single_Apex_Class__c = 'testClasstest1234';
        setting.Log_Exceptions__c = true;
        insert setting;
                
        for(Integer i = 0; i < Limits.getLimitEmailInvocations() + 2; i++) {
            SG_ErrorHelper.notifyOnError(setting.Single_Apex_Class__c,'exp','subject','errorbody');
        }
    } 
    
    static testMethod void test_doLogEmail() {       
        Custom_Apex_Error_Handler__c setting = new Custom_Apex_Error_Handler__c();
        setting.Name = 'CustomSettingNameTest';
        setting.Email__c = 'test@testernovoidwork.net';
        setting.Log_Exceptions__c = true;        
        insert setting;
        
        Custom_Apex_Error_Handler__c setting2 = new Custom_Apex_Error_Handler__c();
        setting2.Name = 'CustomSettingNameTest2';
        setting2.Email__c = 'test2@testernovoidwork.net';
        setting2.Single_Apex_Class__c = 'TestTestTest';
        setting2.Log_Exceptions__c = true;        
        insert setting2;
        
        SG_ErrorHelper.doLogError('ApexClass','Exception',new Set<String>{setting.Email__c,setting2.Email__c});
    }
    
}