/**********************************************************************
* Name:     SG_VFC_RetailLead_Test
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
* 1.0       04-Feb-2020     rwd           Initial Development           
*   
***********************************************************************/


@IsTest
private class SG_VFC_RetailLead_Test {

	private static SG_TestDataGenerator td;
	private static List<Lead> leads;


	static testMethod void testBehavior() {
		td = new SG_TestDataGenerator();
		refreshData();


		System.assertEquals( 0, leads.size() );

		Lead theLead = new Lead();
		PageReference theScreen = Page.RetailLead;
		Test.setCurrentPage(theScreen);

		ApexPages.StandardController con = new ApexPages.Standardcontroller( theLead );
		SG_VFC_RetailLead controller = new SG_VFC_RetailLead( con );

		controller.theLead.FirstName = 'Test';
		// test w/o a last name - should fail
		controller.customSave();

		refreshData();
		System.assertEquals( 0, leads.size() );

		controller.theLead.LastName = 'Lead';
		controller.customSave();

		refreshData();
		System.assertEquals( 1, leads.size() );
		System.assertNotEquals( null, leads[0].Company ); // we want the company to populate, but the exact format might change; so just assert it is populated

		controller.startOver();
	}

	public static void refreshData() {
		leads = [SELECT Id, Name, Company FROM Lead];
	}


}