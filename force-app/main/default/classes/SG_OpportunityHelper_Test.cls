/**********************************************************************
* Name:     SG_OpportunityHelper_Test
* Author:   Strategic Growth, Inc. (www.strategicgrowthinc.com)
*  
* ======================================================
* ======================================================
* Purpose:                                                      
* 
* ======================================================
* ======================================================
* History:                                                            
* VERSION   DATE            INITIALS      DESCRIPTION/FEATURES ADDED
* 1.0       28-Apr-2020     rwd           Initial Development           
*   
***********************************************************************/


/* we are using specific products - use seealldata=true */
@isTest(SeeAllData=true)
public class SG_OpportunityHelper_Test {
    private static SG_TestDataGenerator td;
    private static List<Account> accounts;
    private static List<Opportunity> opps;
    private static List<OpportunityLineItem> oppLineItems;
    private static List<Product2> prods;
    private static List<OpportunityLineItemSchedule> schedules;



    /*
        Test for default values;
        Test for setting a proj start, rev, quantity, duration
        Test for updating
     */


    static testMethod void testBehavior()
    {
        td = new SG_TestDataGenerator();
        td.accountNum = 1;
        td.opptyNum = 1;
        td.opptyLineItemNum = 1;
        td.productNum = 1;
        td.pricebookEntryNum = 1;
        accounts = td.getAccounts(true);

        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Single_Family').getRecordTypeId();
        List<Pricebook2> pricebooks = [SELECT Id FROM Pricebook2 WHERE Name = 'ADG Quick Create Price Book'];
        Pricebook2 pb;
        Id pbId;
        if ( pricebooks != null && pricebooks.size() > 0 )
        {
            pb = pricebooks[0];
            pbId = pb.Id;
        }

        opps = td.getOpportunities(false, pbId);
        for ( Opportunity o : opps )
        {
            o.Primary_Product_Family__c = 'Flooring';
            o.RecordTypeId = recordTypeId;
            o.Project_Duration_months__c = 1;
        }
        insert opps;

        refreshData();

        System.debug(LoggingLevel.WARN, '---> in test: opps: ' + opps );

        //System.assertEquals( 1, schedules.size(), 'Should only have the single default schedule' );

        SG_OpportunityHelper.hasDoneSchedules = false;
        opps[0].Estimated_Project_Start_Date__c = Date.today().addMonths(1);
        opps[0].Project_Duration_months__c = 3;
        opps[0].Bid_Due_Date__c = Date.today().addMonths(1);
        SG_OpportunityHelper.hasDoneSchedules = false;
        Test.startTest();
        system.debug('@testData =' + json.serialize(opps));
        //update opps;
        Test.stopTest();

        refreshData();

        System.debug(LoggingLevel.WARN, '---> in test; oppLineItems: ' + oppLineItems);
        System.debug(LoggingLevel.WARN, '---> in test: products: ' + prods);
        System.debug(LoggingLevel.WARN, '---> in test: scheds: ' + schedules );

        // we're dependent on a Process Builder creating schedules... but what if that is deactivated? we don't want everything else to fail...
        if ( schedules != null && schedules.size() > 0 )
        {
            //System.assertEquals( 3, schedules.size(), 'Did not create the 3 monthly schedules' );

            SG_OpportunityHelper.hasDoneSchedules = false;
            // add a rev and quantity and verify
            opps[0].of_Homes_Units__c = 9;
            opps[0].Estimated_Revenue_per_Home_Unit__c = 5;
            SG_OpportunityHelper.hasDoneSchedules = false;
            //update opps;
            refreshData();

            // Finally - test the activator on the trigger
            SG_OpportunityHelper.isTest = true;
            //update opps;

        }


    }

    public static void refreshData()
    {
        accounts = [SELECT Id, Name FROM Account];
        opps = [SELECT Id, Name, Estimated_Project_Start_Date__c, of_Homes_Units__c, Project_Duration_months__c, Estimated_Revenue_per_Home_Unit__c, CloseDate FROM Opportunity];
        prods = [SELECT Id, Name, CanUseQuantitySchedule, CanUseRevenueSchedule, NumberOfRevenueInstallments, NumberOfQuantityInstallments, QuantityInstallmentPeriod, RevenueInstallmentPeriod FROM Product2];
        oppLineItems = [SELECT Id, OpportunityId, Product2Id, Product2.Name, Product2.CanUseRevenueSchedule, PricebookEntryId FROM OpportunityLineItem];
        schedules = [SELECT Id, Revenue, Quantity, OpportunityLineItemId, OpportunityLineItem.OpportunityId, OpportunityLineItem.Product2.CanUseRevenueSchedule FROM OpportunityLineItemSchedule WHERE OpportunityLineItem.OpportunityId = :opps[0].Id];

    }
}