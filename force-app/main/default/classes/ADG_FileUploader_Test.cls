@isTest
public class ADG_FileUploader_Test {
    
    static testMethod void ContentDocumentLinkTriggerTest() {
        String cv;
        String accId;
        //FileUploaderClass fileUpload = new FileUploaderClass();
        Test.startTest();
        Account acc = new Account();
        acc.Name = 'CRECAccount';
        INSERT acc;
        accId = acc.Id;
        String file = 'This is a Test File';
        cv = FileUploaderClass.uploadFile('This is a Test File', 'TestfileName', accId);
        Test.stopTest();
    }
}