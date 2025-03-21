/**********************************************************************
* Name:     SG_Case_LU_Test
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
* 1.0       25-Jun-2020     rwd           Initial Development           
*   
***********************************************************************/


@IsTest
public class SG_Case_LU_Test {
	private static SG_TestDataGenerator td;
	private static List<Case> cases;


	public static Boolean isTest = false;

	static testMethod void testBehavior() {

		// the LU Helper has it's own test class. We just need to fire the trigger for test coverage
		Case c = new Case ();
		c.Subject = 'Test';
		insert c;

		// test the activator
		SG_CaseHelper.hasDoneCaseRollups = false;
		isTest = true;
		update c;
	}

	public static void refreshData() {
		cases = [SELECT Id, Subject FROM Case];
	}
}