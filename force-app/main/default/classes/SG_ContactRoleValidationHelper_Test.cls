/**********************************************************************
* Name:   	SG_ContactRoleValidationHelper_Test
* Author: 	Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date: 	28-Aug-2018
* ======================================================
* ======================================================
* Purpose: The purpose of this class is to                                                            
* 
* ======================================================
* ======================================================
* History:                                                            
* VERSION	DATE            INITIALS	DESCRIPTION/FEATURES ADDED
* 1.0     	28-Aug-2018     CS			Initial Development
* 1.01      29-Aug-2018     FMF         Convert to use metadata instead of custom settings
*   
***********************************************************************/


@IsTest
private class SG_ContactRoleValidationHelper_Test
{
    @TestSetup
    public static void createData() {
        SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        tdg.contactNum = 2;
        tdg.opptyNum = 2;
        tdg.initAllTestData();
    }

    static testMethod void positiveUnitTestNotEquals() {
        Opportunity o = [ SELECT ID, StageName
                        FROM Opportunity
                        LIMIT 1 ];

        Contact c = [ SELECT ID
                    FROM Contact
                    LIMIT 1 ];

        // workaround the impossibility of inserting metadata
        String theRole = 'Project Manager';
        String rvsData = '[ { "Role_Object__c":"OpportunityContactRole", "Role__c":"' + theRole + '"'
                        + ', "Field_To_Check__c":"StageName", "Field_Value_To_Check__c":"' + o.StageName
                        + '", "Error_Message__c":"Test Error", "Comparison__c":"not equals"'
                        + ', "Count__c":"1" }'
                        + ', { "Role_Object__c":"OpportunityContactRole", "Role__c":"Executive Sponsor"'
                        + ', "Field_To_Check__c":"StageName", "Field_Value_To_Check__c":"Proposal/Price Quote"'
                        + ', "Error_Message__c":"Cannot set stage to price quote", "Comparison__c":"not equals"'
                        + ', "Count__c":"1" } ]';
        SG_ContactRoleValidationHelper.roleValidationSettings = (List<Contact_Role_Validation_Setting__mdt>)
                JSON.deserialize( rvsData, List<Contact_Role_Validation_Setting__mdt>.class );

        List<Contact_Role_Validation_Setting__mdt> rvsAssert =
                    SG_ContactRoleValidationHelper.getCustomSettings( o, 'OpportunityContactRole' );
        System.assertEquals( 1, rvsAssert.size() );

        Boolean error = false;

        OpportunityContactRole ocRole = new OpportunityContactRole();
        ocRole.Role = theRole;
        ocRole.ContactId = c.Id;
        ocRole.OpportunityId = o.Id;
        insert ocRole;

        // emulate opportunity trigger running once
        Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity> { o.ID => o };
        SG_ContactRoleValidationHelper.validateOpportunityContactRolesHelper( opptyMap );

        try
        {
            update o;
            error = false;
        }
        catch( Exception exp )
        {
            error = true;
            System.debug( exp.getMessage() + ' - ' + exp.getStackTraceString() );
        }
        System.assertEquals( false, error );
    }

    static testMethod void positiveUnitNotEquals_NoTrigger()
    {
        Opportunity o = [ SELECT ID, StageName
        FROM Opportunity
        LIMIT 1 ];

        Contact c = [ SELECT ID
        FROM Contact
        LIMIT 1 ];

        // workaround the impossibility of inserting metadata
        String theRole = 'Project Manager';
        String rvsData = '[ { "Role_Object__c":"OpportunityContactRole", "Role__c":"' + theRole + '"'
                + ', "Field_To_Check__c":"StageName", "Field_Value_To_Check__c":"' + o.StageName
                + '", "Error_Message__c":"Test Error", "Comparison__c":"not equals"'
                + ', "Count__c":"1" }'
                + ', { "Role_Object__c":"OpportunityContactRole", "Role__c":"Executive Sponsor"'
                + ', "Field_To_Check__c":"StageName", "Field_Value_To_Check__c":"Proposal/Price Quote"'
                + ', "Error_Message__c":"Cannot set stage to price quote", "Comparison__c":"not equals"'
                + ', "Count__c":"1" } ]';
        SG_ContactRoleValidationHelper.roleValidationSettings = (List<Contact_Role_Validation_Setting__mdt>)
                JSON.deserialize( rvsData, List<Contact_Role_Validation_Setting__mdt>.class );

        List<Contact_Role_Validation_Setting__mdt> rvsAssert =
                SG_ContactRoleValidationHelper.getCustomSettings( o, 'OpportunityContactRole' );
        System.assertEquals( 1, rvsAssert.size() );

        // emulate opportunity trigger running once
        Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity> { o.ID => o };
        Boolean error = SG_ContactRoleValidationHelper.validateOpportunityContactRolesHelper( opptyMap );

        system.assertEquals( true, error );

        OpportunityContactRole ocRole = new OpportunityContactRole();
        ocRole.Role = theRole;
        ocRole.ContactId = c.Id;
        ocRole.OpportunityId = o.Id;
        ocRole.IsPrimary = true;
        insert ocRole;

        error = SG_ContactRoleValidationHelper.validateOpportunityContactRolesHelper( opptyMap );

        system.assertEquals( false, error );
    }

    static testMethod void positiveUnitEquals_NoTrigger() {

        Opportunity o = [ SELECT ID, StageName
        FROM Opportunity
        LIMIT 1 ];

        Contact c = [ SELECT ID
        FROM Contact
        LIMIT 1 ];

        // workaround the impossibility of inserting metadata
        String theRole = 'Project Manager';
        String rvsData = '[ { "Role_Object__c":"OpportunityContactRole", "Role__c":"' + theRole + '"'
                + ', "Field_To_Check__c":"StageName", "Field_Value_To_Check__c":"' + o.StageName
                + '", "Error_Message__c":"Test Error", "Comparison__c":"equals"'
                + ', "Count__c":"1" }'
                + ', { "Role_Object__c":"OpportunityContactRole", "Role__c":"Executive Sponsor"'
                + ', "Field_To_Check__c":"StageName", "Field_Value_To_Check__c":"Proposal/Price Quote"'
                + ', "Error_Message__c":"Cannot set stage to price quote", "Comparison__c":"not equals"'
                + ', "Count__c":"1" } ]';
        SG_ContactRoleValidationHelper.roleValidationSettings = (List<Contact_Role_Validation_Setting__mdt>)
                JSON.deserialize( rvsData, List<Contact_Role_Validation_Setting__mdt>.class );

        List<Contact_Role_Validation_Setting__mdt> rvsAssert =
                SG_ContactRoleValidationHelper.getCustomSettings( o, 'OpportunityContactRole' );
        System.assertEquals( 1, rvsAssert.size() );

        OpportunityContactRole ocRole = new OpportunityContactRole();
        ocRole.Role = theRole;
        ocRole.ContactId = c.Id;
        ocRole.OpportunityId = o.Id;
        insert ocRole;

        // emulate opportunity trigger running once
        Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity> { o.ID => o };
        Boolean error = SG_ContactRoleValidationHelper.validateOpportunityContactRolesHelper( opptyMap );

        system.assertEquals( true, error );
    }
}