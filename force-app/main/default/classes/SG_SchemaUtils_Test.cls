@isTest
private class SG_SchemaUtils_Test {

    static testMethod void simpleMethodRunThrough() {
        
        if(SG_SchemaUtils.hasRecordTypeEnabled('Account'))
        {
	        System.assertEquals(null,SG_SchemaUtils.getRecordTypeId('Account', 'fake'));
	        
	        System.assertNotEquals(0,SG_SchemaUtils.getRecordTypeIds(new Account()).size());
	        
	        System.assertNotEquals(0,SG_SchemaUtils.getRecordTypeIds('Account').size());        	
        }
        else
        {
        	System.assertEquals(null,SG_SchemaUtils.getRecordTypeId('Account', 'fake'));
        
	        System.assertEquals(0,SG_SchemaUtils.getRecordTypeIds(new Account()).size());
	        
	        System.assertEquals(0,SG_SchemaUtils.getRecordTypeIds('Account').size());        
        }
        
        SG_TestDataGenerator tdg = new SG_TestDataGenerator();
        String accountIdStr = tdg.getAccounts(true)[0].Id;
       	String the15charID = accountIdStr.subString(0,15);
                                                 
        System.assertEquals(accountIdStr,SG_SchemaUtils.to18(the15charID));                
        
        SG_SchemaUtils.isCreatable((List<SObject>)tdg.getAccounts(true));
        
        SG_SchemaUtils.isUpdateable((List<SObject>)tdg.getAccounts(true));
        
        SG_SchemaUtils.isUpsertable((List<SObject>)tdg.getAccounts(true));
        
        SG_SchemaUtils.isDeletable((List<SObject>)tdg.getAccounts(true));

        Map<String, Schema.SObjectField> fieldMap =
                SG_SchemaUtils.getFieldMap((List<SObject>)tdg.getAccounts(true));

        List<SObject> acctList = SG_SchemaUtils.queryFullSObject(
                    fieldMap, 'Account', 'Name = \'Test 0\'' );
        system.assertEquals( 1, acctList.size(), 'dynamic query test' );
        
        SG_SchemaUtils.isValidFieldName((List<SObject>)tdg.getAccounts(true),'foo');


    }   
    
}