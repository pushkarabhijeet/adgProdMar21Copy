/**********************************************************************
* Name:   	SG_TDG_LookupRollupSummary
* Author: 	Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date: 	2009
* ======================================================
* ======================================================
* Purpose:                                                            
* This class is used to create test data. It is virtual so that it can be extended
*                                                            
* ======================================================
* ======================================================
* History:                                                            
* VERSION	DATE            INITIALS	DESCRIPTION/FEATURES ADDED
* 1.0     	2009	        CS			Initial Development           
*   
***********************************************************************/

@isTest
public class SG_TDG_LookupRollupSummary extends SG_TestDataGenerator 
{
	private RollupConfigs__c config; 
	
	public SG_TDG_LookupRollupSummary(){ 
		super();
	}
	
	public RollupConfigs__c getRollupConfiguration() {
		if(config == null) {
			List<RollupConfigs__c> existingContactAccountConfig = [SELECT Id 
																   FROM RollupConfigs__c 
																   WHERE Child_Object_Name__c = 'Contact' 
																   AND Parent_Object__c = 'Account'];
			if(existingContactAccountConfig != null && existingContactAccountConfig.size() == 1) {
				config = existingContactAccountConfig[0];
			} else {
				config = new RollupConfigs__c();
			}
			config.Child_Object_Name__c = 'Contact';
			config.Parent_Object__c = 'Account';
			config.Name = 'ContactToAccount';
			config.parentRowCount__c = 'NumberOfEmployees';
			config.queryField_parentRelationshipName__c = 'AccountId';
			config.queryField1__c = 'Unit_Contact__c';
			config.queryField2__c = null;
			config.queryField3__c = null;
			config.queryField4__c = null;
			config.queryField5__c = null;
			config.parentQueryField1__c = 'Description';
			config.parentQueryField2__c = null;
			config.parentQueryField3__c = null;
			config.parentQueryField4__c = null;
			config.parentQueryField5__c = null;
			config.Active__c = true;
			
			if(config.Id == null) {
				insert config;
			} else {
				update config;
			}
		}
		return config;
	}


	public override void initAllTestData() 
	{			
		super.initAllTestData();
		getRollupConfiguration();				
	}    
}