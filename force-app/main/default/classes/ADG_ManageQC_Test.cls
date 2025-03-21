/***********************************************************************************
 * Name:     	ADG_ManageQC_Test
 * Author:   	Pushkar
 * Main Class:	ADG_ManageQC
 * ======================================================
 * History:
 * VER   DATE          INITIALS      DESCRIPTION/FEATURES ADDED
 * 1.0   Jan-20-2021   pushkar       Initial Development to be test
 *
 ***********************************************************************************/
@isTest
public class ADG_ManageQC_Test {
    @TestSetUP
    public static void setupData() {
    ADG_TestSetup.Setup(); //SetUp Accounts and Workorders
  }
    
    static testMethod void submitBatch_test(){
        Test.startTest();
        Date qcCreatedDate = System.today();
        //String strEntity = 'Floors';
        String strEntity = '';
		String strFieldName = 'QC_Build_Sheet__c';
        String strFieldLabel = 'QC Build Sheet';
        String strButtonClk = 'disable';
        String returnMsg = ADG_ManageQC.submitBatch(qcCreatedDate, strEntity, strFieldName, strFieldLabel, strButtonClk);
        strButtonClk = 'enable';
        returnMsg = ADG_ManageQC.submitBatch(qcCreatedDate, strEntity, strFieldName, strFieldLabel, strButtonClk);
        Test.stopTest();
    }

}