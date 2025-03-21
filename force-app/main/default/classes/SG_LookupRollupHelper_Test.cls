@isTest
private class SG_LookupRollupHelper_Test {
	
	 static testMethod void testNullValues() {
	 	SG_TDG_LookupRollupSummary dataGenerator = new SG_TDG_LookupRollupSummary();    	
    	//Initialize the Configuration Object    
    	dataGenerator.getRollupConfiguration();
    	dataGenerator.getContacts(true);


		 SG_LookupRollupHelper lh = new SG_LookupRollupHelper( 'Contact', 'Account');

		 // take care of assigning the correct lists based on the trigger type (Insert vs Update vs Delete vs Undelete) - test with nulls...
		 lh.setTriggerLists(true, true, null, null);

		 // do the rollup(s) -- will execute all active rollups for current child/parent configuration
		 lh.doRollupSummary();



		 /*
		 //Pass in the name of the child record, in this case 'Contact' and the name of the parent record, in this case 'Account';
		 SG_LookupRollupHelper lh = new SG_LookupRollupHelper( 'Contact', 'Account');
		
		//Test errors
		System.assertEquals(null,lh.queryForChildren(null,null,null,null,null,null,null));		 
		
		//want to pass a null result list
		List<Account> accounts = dataGenerator.getAccounts(false);
		for(Account a : accounts) {
			a.NumberOfEmployees = 1000;
		}
		lh.assignRollupResults(null, (List<sObject>)accounts);		
		for(Account a : accounts) {
			System.assertEquals(0,a.NumberOfEmployees);
		}
		*/
		
		//Test errors		
		System.assertEquals(null,lh.getCurrentConfig(null,null,null));
	 }

    static testMethod void testLookups() {
    
    	SG_TDG_LookupRollupSummary dataGenerator = new SG_TDG_LookupRollupSummary();    	
    	//Initialize the Configuration Object    
    	dataGenerator.getRollupConfiguration();

		List<Contact> contacts = dataGenerator.getContacts(true);

		SG_LookupRollupHelper lh = new SG_LookupRollupHelper( 'Contact', 'Account');

		// take care of assigning the correct lists based on the trigger type (Insert vs Update vs Delete vs Undelete) - test with nulls...
		lh.setTriggerLists(false, false, contacts, null);

		// do the rollup(s) -- will execute all active rollups for current child/parent configuration
		lh.doRollupSummary();


		System.assert(dataGenerator.getContacts(false).size() > 0, 'No Contacts');
		System.assert(dataGenerator.getAccounts(false).size() > 0, 'No Accounts');
		System.assert(dataGenerator.getContacts(false)[0].Id != null,'Null Id');
		System.assert(dataGenerator.getContacts(false)[0].AccountId != null, 'Null AccountId');
		System.assert(dataGenerator.getAccounts(false)[0].Id != null, 'Null Id');
		
		//How many contacts per account are there?
		Map<Id,Integer> accountIdToContactCount = new Map<Id,Integer>();
		
		for(Contact c : dataGenerator.getContacts(false)) {
			Integer counter = 0;			
			if(c.AccountId != null) {
				if(accountIdToContactCount.containsKey(c.AccountId)) {
					counter = accountIdToContactCount.get(c.AccountId);
				}
				counter++;				
				accountIdToContactCount.put(c.AccountId,counter);
			}
		}
				
		//Now make sure that the Account.Description contains the count of Contacts
		List<Account> accounts = [SELECT Id, NumberOfEmployees FROM Account WHERE Id IN :accountIdToContactCount.keySet()];
		
		System.assert(accounts != null && accounts.size() > 0, 'No Accounts: ' + accountIdToContactCount.keySet());
		for(Account account : accounts) {
			Integer contactCount = (account.NumberOfEmployees != null) ? Integer.valueOf(account.NumberOfEmployees) : 0;
			System.assert(accountIdToContactCount.get(account.Id) > 0,'Count is 0');
		}
    }
}