/**********************************************************************
* Name:     SG_ServiceResourceHelper_Test
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
* 1.0       23-Mar-2020     rwd           Initial Development           
*   
***********************************************************************/


@IsTest
private class SG_ServiceResourceHelper_Test {
	private static SG_TestDataGenerator td;
	private static List<User> users;
	private static List<ServiceResource> resources;


	static testMethod void testBehavior() {
		td = new SG_TestDataGenerator();
		td.userNum = 2;
		users = td.getUsers(null);
		refreshData();

		System.debug(LoggingLevel.WARN, '---> users: ' + users );
		ServiceResource res = new ServiceResource();
		res.Name = 'Test';
		res.RelatedRecordId = users[0].Id;
		res.IsActive = true;

		insert res;
		refreshData();
		User u = users[0];
		for ( ServiceResource r : resources )
		{
			System.assertEquals( u.Id, r.Service_Resource_User_ID__c );
		}

		// rerun to validate recursion check...
		update res;

		// now test the disable on the trigger
		SG_ServiceResourceHelper.isTest = true;
		update res;

	}

	public static void refreshData()
	{
		users = [SELECT Id, Name FROM User WHERE IsActive = true AND Email LIKE '%.net.test' ];
		resources = [SELECT Id, Name, RelatedRecordId, Service_Resource_User_ID__c FROM ServiceResource];
	}
}