/***************************************************
* Name:         SG_CaseAssignmentRuleActivation_Test
* Author:       Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date:         21 May 2020
* ==================================================
* ==================================================
* Purpose:      ...
*
* ==================================================
* ==================================================
* History:
* VERSION   DATE            INITIALS    DESCRIPTION/FEATURES ADDED
* 1.0       21 May 2020     FMF     Initial Development
* 
****************************************************/

@isTest
public with sharing class SG_CaseAssignmentRuleActivation_Test {
    @TestSetup
    public static void setupData() {
        Case c = new Case ();
        c.Subject = 'Test';
        insert c;
    }

    public static TestMethod void myUnitTest() {
        Test.startTest();

        Case c = [ SELECT ID FROM Case LIMIT 1 ];

        List<Id> caseIDs = new List<Id>{ c.ID };
        SG_CaseAssignmentRuleActivation.applyAssignmentRules( caseIDs );

        Test.stopTest();

        //system.assertEquals( 0, variable, 'Test' );


        //Database.Error[] errors = new Database.Error[] {};
        //String listOfErrors = VFC_Controller.ConcatenateErrors( errors );
    }
}