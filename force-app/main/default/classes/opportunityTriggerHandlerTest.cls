@isTest
public class opportunityTriggerHandlerTest {
    @isTest static void testValidateStagesBeforeUpdate() {
        Account acc = new Account(Name = 'test Acc adg1sdbx', OwnerId = UserInfo.getUserId());
        insert acc;
        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Construction Opportunity')?.getRecordTypeId();
        Opportunity opp0 = new Opportunity(Name = 'test Opp adg1sdbx',
                                          AccountId = acc.Id,
                                          RecordTypeId = recordTypeId,
                                          StageName = 'ITB (Invitation to Bid)',
                                          CloseDate = Date.today().addDays(10),
                                          OwnerId = UserInfo.getUserId());
        insert opp0;
        Opportunity opp = [SELECT StageName, First_Bid_Type__c, First_Bid_Delivery_Date__c
                           FROM Opportunity
                           WHERE Id = :opp0.Id];
        opp.StageName = 'First Bid Delivered';
        try {
            update opp;
            Assert.fail();
        } catch (DmlException ex) {
            System.debug('exception catched');
        }
        Assert.areEqual('First Bid Delivered', opp.StageName);
        opp.First_Bid_Type__c = 'Schematic Deisgn - SD';
        opp.First_Bid_Estimator__c = System.UserInfo.getUserId();
        opp.First_Bid_Amount__c = 500;
        opp.First_Bid_Submitter__c = System.UserInfo.getUserId();
        opp.First_Bid_Software__c = 'Procore';
        opp.First_Bid_Margin__c = 0.5;
        Date currentDate = System.today();
		Date dateTenDaysAhead = currentDate.addDays(10);
        opp.First_Bid_Due_Date__c = dateTenDaysAhead;
        opp.StageName = 'First Bid Delivered';
        update opp;
        Opportunity opp1 = [SELECT StageName, First_Bid_Type__c, First_Bid_Delivery_Date__c
                           FROM Opportunity
                           WHERE Id = :opp.Id];
        Assert.areEqual(Date.today(), opp1.First_Bid_Delivery_Date__c);
        Assert.areEqual('First Bid Delivered', opp1.StageName);
    }
}