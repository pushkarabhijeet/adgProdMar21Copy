@isTest
private class SG_DB_Test {

	/* 
	  ****************************************
	              UPDATE PARENT OBJECTS
	  ****************************************
	*/

    static testMethod void updateParentNoErrors_ThrowException() {
    	SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        tdg.getAccounts(true); //setup accounts (parent)
        tdg.getContacts(true); //setup contacts (child)
        for(Account a : tdg.getAccounts(true))
        {
        	a.Name = a.Name + 'Update';
        }
        
        SG_DB.updateParentObjects(tdg.getAccounts(true), tdg.getContacts(true), 'AccountId', null, false, 'SG_DB_Test', new SG_DB.GenericException('test'));
        
        Integer counter = [SELECT count() FROM Account WHERE Name LIKE '%Update'];
        System.assertEquals(tdg.getAccounts(true).size(),counter);        
    }
    
    static testMethod void updateParentNoErrors_EmailErrors() {
    	SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        tdg.getAccounts(true); //setup accounts (parent)
        tdg.getContacts(true); //setup contacts (child)
        for(Account a : tdg.getAccounts(true))
        {
        	a.Name = a.Name + 'Update';
        }
        
        SG_DB.updateParentObjects(tdg.getAccounts(true), tdg.getContacts(true), 'AccountId', null, true, 'SG_DB_Test', new SG_DB.GenericException('test'));
        
        Integer counter = [SELECT count() FROM Account WHERE Name LIKE '%Update'];
        System.assertEquals(tdg.getAccounts(true).size(),counter);                  
    }
    
    static testMethod void updateParentExceptions_ThrowException() {
    	SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        tdg.getAccounts(true); //setup accounts (parent)
        tdg.getContacts(true); //setup contacts (child)
        for(Account a : tdg.getAccounts(true))
        {
        	a.Name = null; //This will throw an error on update
        }
        
        Boolean wasError = false;
        try
        {
        	SG_DB.updateParentObjects(tdg.getAccounts(true), tdg.getContacts(true), 'AccountId', null, false, 'SG_DB_Test', new SG_DB.GenericException('test'));
        }
        catch(Exception exp)
        {
        	System.debug('updateParentExceptions_ThrowException exp = ' + exp);
        	wasError = true;
        }
                
        System.assertEquals(true,wasError);        
    }
    
    static testMethod void updateParentExceptions_EmailErrors() {
    	SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        tdg.getAccounts(true); //setup accounts (parent)
        tdg.getContacts(true); //setup contacts (child)
        for(Account a : tdg.getAccounts(true))
        {
        	a.Name = null; //This will throw an error on update
        }
        
        Boolean wasError = false;
        try
        {
        	SG_DB.updateParentObjects(tdg.getAccounts(true), tdg.getContacts(true), 'AccountId', null, true, 'SG_DB_Test', new SG_DB.GenericException('test'));
        }
        catch(Exception exp)
        {
        	System.debug('updateParentExceptions_EmailErrors exp = ' + exp);
        	wasError = true;
        }
                
        System.assertEquals(false,wasError);        
    }
    
    static testMethod void updateTestWithDMLOptions() {
    	SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        tdg.getAccounts(true); //setup accounts (parent)
        tdg.getContacts(true); //setup contacts (child)
        for(Account a : tdg.getAccounts(true))
        {
        	a.Name = a.Name + 'Update';
        }
        
        Database.Dmloptions dmlOptions = new Database.Dmloptions();        
        SG_DB.updateParentObjects(tdg.getAccounts(true), tdg.getContacts(true), 'AccountId', dmlOptions, true, 'SG_DB_Test', new SG_DB.GenericException('test'));
        
        Integer counter = [SELECT count() FROM Account WHERE Name LIKE '%Update'];
        System.assertEquals(tdg.getAccounts(true).size(),counter);                           
    }
 
	/* 
	  ****************************************
	              UPDATE CHILD OBJECTS
	  ****************************************
	*/

    static testMethod void updateChildNoErrors_ThrowException() {
    	SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        tdg.getAccounts(true); //setup accounts (parent)
        tdg.getContacts(true); //setup contacts (child)
        for(Contact c : tdg.getContacts(true))
        {
        	c.FirstName = c.FirstName + 'Update';
        }
        
        SG_DB.updateChildObjects(tdg.getContacts(true), new Map<Id,Account>(tdg.getAccounts(true)), 'AccountId', null, false, 'SG_DB_Test', new SG_DB.GenericException('test'));
        
        Integer counter = [SELECT count() FROM Contact WHERE FirstName LIKE '%Update'];
        System.assertEquals(tdg.getContacts(true).size(),counter);        
    }
    
    static testMethod void updateChildNoErrors_EmailErrors() {
    	SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        tdg.getAccounts(true); //setup accounts (parent)
        tdg.getContacts(true); //setup contacts (child)
        for(Contact c : tdg.getContacts(true))
        {
        	c.FirstName = c.FirstName + 'Update';
        }
                
        SG_DB.updateChildObjects(tdg.getContacts(true), new Map<Id,Account>(tdg.getAccounts(true)), 'AccountId', null, true, 'SG_DB_Test', new SG_DB.GenericException('test'));
        
        Integer counter = [SELECT count() FROM Contact WHERE FirstName LIKE '%Update'];
        System.assertEquals(tdg.getContacts(true).size(),counter);  
    }
    
    static testMethod void updateChildExceptions_ThrowException() {
    	SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        tdg.getAccounts(true); //setup accounts (parent)
        tdg.getContacts(true); //setup contacts (child)
        for(Contact c : tdg.getContacts(true))
        {
        	c.LastName = null; //This will throw an error on update
        }
        
        Boolean wasError = false;
        try
        {        	
        	SG_DB.updateChildObjects(tdg.getContacts(true), new Map<Id,Account>(tdg.getAccounts(true)), 'AccountId', null, false, 'SG_DB_Test', new SG_DB.GenericException('test'));
        }
        catch(Exception exp)
        {
        	System.debug('updateChildExceptions_ThrowException exp = ' + exp);
        	wasError = true;
        }
                
        System.assertEquals(true,wasError);        
    }
    
    static testMethod void updateChildExceptions_EmailErrors() {
    	SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        tdg.getAccounts(true); //setup accounts (parent)
        tdg.getContacts(true); //setup contacts (child)
        for(Contact c : tdg.getContacts(true))
        {
        	c.LastName = null; //This will throw an error on update
        }
        
        Boolean wasError = false;
        try
        {
        	SG_DB.updateChildObjects(tdg.getContacts(true), new Map<Id,Account>(tdg.getAccounts(true)), 'AccountId', null, true, 'SG_DB_Test', new SG_DB.GenericException('test'));
        }
        catch(Exception exp)
        {
        	System.debug('updateChildExceptions_EmailErrors exp = ' + exp);
        	wasError = true;
        }
                
        System.assertEquals(false,wasError);        
    }
    
    static testMethod void updateChildWithDMLOptions() {
    	SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        tdg.getAccounts(true); //setup accounts (parent)
        tdg.getContacts(true); //setup contacts (child)
        for(Contact c : tdg.getContacts(true))
        {
        	c.FirstName = c.FirstName + 'Update';
        }
        
        Database.Dmloptions dmlOptions = new Database.Dmloptions();        
        SG_DB.updateChildObjects(tdg.getContacts(true), new Map<Id,Account>(tdg.getAccounts(true)), 'AccountId', dmlOptions, true, 'SG_DB_Test', new SG_DB.GenericException('test'));
        
        Integer counter = [SELECT count() FROM Contact WHERE FirstName LIKE '%Update'];
        System.assertEquals(tdg.getContacts(true).size(),counter);                           
    } 
 
	/* 
	  ****************************************
	              INSERT CHILD OBJECTS
	  ****************************************
	*/

    static testMethod void insertChildNoErrors_ThrowException() {
    	SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        tdg.getAccounts(true); //setup accounts (parent)        
        for(Contact c : tdg.getContacts(false))
        {
        	c.FirstName = c.FirstName + 'Update';
        }
        
        SG_DB.insertChildObjects(tdg.getContacts(false), new Map<Id,Account>(tdg.getAccounts(true)), 'AccountId', null, false, 'SG_DB_Test', new SG_DB.GenericException('test'));
                
        Integer counter = [SELECT count() FROM Contact WHERE FirstName LIKE '%Update'];
        System.assertEquals(tdg.getContacts(false).size(),counter);        
    }
    
    static testMethod void insertChildNoErrors_EmailErrors() {
    	SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        tdg.getAccounts(true); //setup accounts (parent)        
        for(Contact c : tdg.getContacts(false))
        {
        	c.FirstName = c.FirstName + 'Update';
        }
                
        SG_DB.insertChildObjects(tdg.getContacts(false), new Map<Id,Account>(tdg.getAccounts(true)), 'AccountId', null, true, 'SG_DB_Test', new SG_DB.GenericException('test'));
        
        Integer counter = [SELECT count() FROM Contact WHERE FirstName LIKE '%Update'];
        System.assertEquals(tdg.getContacts(false).size(),counter);  
    }
    
    static testMethod void insertChildExceptions_ThrowException() {
    	SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        tdg.getAccounts(true); //setup accounts (parent)
        for(Contact c : tdg.getContacts(false))
        {
        	c.LastName = null; //This will throw an error on update
        }
        
        Boolean wasError = false;
        try
        {        	
        	SG_DB.insertChildObjects(tdg.getContacts(false), new Map<Id,Account>(tdg.getAccounts(true)), 'AccountId', null, false, 'SG_DB_Test', new SG_DB.GenericException('test'));
        }
        catch(Exception exp)
        {
        	System.debug('insertChildExceptions_ThrowException exp = ' + exp);
        	wasError = true;
        }
                
        System.assertEquals(true,wasError);        
    }
    
    static testMethod void insertChildExceptions_EmailErrors() {
    	SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        tdg.getAccounts(true); //setup accounts (parent)        
        for(Contact c : tdg.getContacts(false))
        {
        	c.LastName = null; //This will throw an error on update
        }
        
        Boolean wasError = false;
        try
        {
        	SG_DB.updateChildObjects(tdg.getContacts(false), new Map<Id,Account>(tdg.getAccounts(true)), 'AccountId', null, true, 'SG_DB_Test', new SG_DB.GenericException('test'));
        }
        catch(Exception exp)
        {
        	System.debug('insertChildExceptions_EmailErrors exp = ' + exp);
        	wasError = true;
        }
                
        System.assertEquals(false,wasError);        
    }

    static testMethod void insert_And_update_Simple() {
        SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        List<Account> accounts = tdg.getAccounts(false);
        //This causes errors
        SG_DB.updateRecords((List<SObject>)accounts);

        SG_DB.insertRecords((List<SObject>)accounts);

        //This causes errors
        SG_DB.insertRecords((List<SObject>)accounts);

        SG_DB.updateRecords((List<SObject>)accounts);
    }


/*  TODO DML Options Causes an Error
    static testMethod void insertChildWithDMLOptions() {
    	SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        tdg.getAccounts(true); //setup accounts (parent)        
        for(Contact c : tdg.getContacts(false))
        {
        	c.FirstName = c.FirstName + 'Update';
        }
        
        Database.Dmloptions dmlOptions = new Database.Dmloptions();        
        SG_DB.updateChildObjects(tdg.getContacts(false), new Map<Id,Account>(tdg.getAccounts(true)), 'AccountId', dmlOptions, true, 'SG_DB_Test', new SG_DB.GenericException('test'));
        
        Integer counter = [SELECT count() FROM Contact WHERE FirstName LIKE '%Update'];
        System.assertEquals(tdg.getContacts(false).size(),counter);                           
    }  
*/ 
 
}