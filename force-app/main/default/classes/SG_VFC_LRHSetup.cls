/**********************************************************************
* Name:     SG_VFC_LRHSetup
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
* 1.0       25-Jun-2014     rwd           Initial Development
*
***********************************************************************/

/*
	dynamic create trigger using Tooling API
	http://stackoverflow.com/questions/18373574/creating-trigger-dynamically-in-apex
	String json = '{ "Name" : "COTrigger", \'+
                             '"TableEnumOrId" : "Custom_Object__c",'+
                             '"Body" : "trigger COTrigger on Custom_Object__c (after insert) { // Do Something }" }'; // JSON format to create trigger

            Httprequest req = new HttpRequest();
            req.setEndpoint('https://[salesforce instance].salesforce.com/services/data/v27.0/sobjects/ApexTrigger');
            req.setMethod('POST');
            req.setHeader('Content-Type':'application/json');
            req.setHeader('Authorization':'Bearer: '+sessionId);
            req.setBody(json);

        Http httpReq = new HttpReq();
        HttpResponse res = httpReq.send(req);
        System.debug(res.getBody());

        http://salesforce.stackexchange.com/questions/9603/how-do-i-use-the-tooling-api-to-create-a-new-apex-trigger

        SforceService toolingService = //... Get instance of the Tooling API

		ApexTrigger newTrigger = new ApexTrigger();
		newTrigger.Name = 'TestOpportunityBeforeUpdate';
		newTrigger.TableEnumOrId = 'opportunity';
		newTrigger.Body = 'trigger TestOpportunityBeforeUpdate on Opportunity (before update{ \n//Horray\n }';

		SaveResult[] results = toolingService.create(new sObject[] { newTrigger });
		String triggerId = results[0].id;
*/


public with sharing class SG_VFC_LRHSetup
{




// ************************     PUBLIC VARIABLES    **************************
	//public Opportunity opp {get; set;}
	public RollupConfigs__c mapping { get; set; }
	public Map<String, RollupConfigs__c> configMap { get; set; }
	public List<RollupConfigs__c> existingConfigs { get; set; }
	public RollupConfigs__c theConfig { get; set; }
	public String doEdit {get; set;}

	public Boolean showSampleTrigger { get; set; }
	public Boolean showCreateSection {get; set;}
	public Boolean isDateQuery {get; set;}
	public Boolean isDateTimeQuery {get; set;}
	public Boolean isMathQuery {get; set;}

	public String selectedConfigName {get; set;}
	public String childObject { get; set; }
	public String parentObject { get; set; }
	public String childObject_Friendly { get; set; }
	public String parentObject_Friendly { get; set; }

	public Set<String> allowedFieldTypes_Rollup {get; set;}
	public Set<String> allowedFieldTypes_Lookup {get; set;}
	public Set<String> rowCountFieldTypes {get; set;}

	public List<SelectOption> childObjects { get; set; }
	public List<SelectOption> parentObjects { get; set; }
	public List<SelectOption> aggFunctionOptions {get; set;}

	public List<SelectOption> childObjectFields { get; set; }
	public List<SelectOption> childObjectFields_Lookups { get; set; }
	public List<SelectOption> parentObjectFields { get; set; }
	public List<SelectOption> parentRowcountFields { get; set; }

	public List<SG_ObjectWrapper> childObjectWrappers { get; set; }
	public List<SG_ObjectWrapper> childObjectWrappers_Lookups { get; set; }
	public List<SG_ObjectWrapper> parentObjectWrappers { get; set; }
	public List<SG_ObjectWrapper> parentRowCountWrappers { get; set; }

	public List<String> allObjects { get; set; }


// ************************     PRIVATE VARIABLES   **************************
	private ApexPages.StandardController controller;
	private Map <String, Schema.SObjectType> schemaMap;
	private List<Schema.SObjectType> gd;


// ************************     CONSTRUCTOR         **************************
	public SG_VFC_LRHSetup(ApexPages.StandardController controller)
	{
		System.debug('---> starting SG_VFC_LRHSetup constructor');
		this.controller = controller;
		if (schemaMap == null) schemaMap = Schema.getGlobalDescribe();
		if (gd == null) gd = Schema.getGlobalDescribe().Values();

		showSampleTrigger = false;
		showCreateSection = false;
		doEdit = 'false';

		isDateQuery = false;
		isDateTimeQuery = false;
		isMathQuery = false;

		init();
	}

	public void init()
	{
		System.debug('---> start init; gd: ' + gd);
		configMap = getRollupConfigs();
		existingConfigs = getExistingConfigs(configMap);

		allObjects = new List<String>();
		Map<String, Schema.SObjectType> objectMap = new Map<String, Schema.SObjectType>();
		for (Schema.SObjectType obj : gd)
		{
			allObjects.add(obj.getDescribe().getLabel());
			objectMap.put(obj.getDescribe().getLabel(), obj);
	//		System.debug('---> number of custom fields for obj (' + obj.getDescribe().getLabel() + '): ' + obj.getDescribe().fields.getMap().size());
	//		System.debug('---> getChildRelationships() (' + obj.getDescribe().getLabel() + '): ' + obj.getDescribe().getChildRelationships());
	//		System.debug('---> isCustomSetting() (' + obj.getDescribe().getLabel() + '): ' + obj.getDescribe().isCustomSetting());

			//options.add(new SelectOption(f.getDescribe().getName(),f.getDescribe().getLabel()));
		}
		allObjects.sort();

		childObjects = getObjectSelectOptions(allObjects, objectMap);
		parentObjects = getObjectSelectOptions(allObjects, objectMap);

		// set up the agg options
		setAggregates();


	}

	public void setAggregates()
	{
		if ( theConfig != null )
		{
			if (theConfig.Do_Date_Query__c )
			{
				isDateQuery = true;
				isDateTimeQuery = false;
				isMathQuery = false;
			}
			else if (theConfig.Do_Date_Time_Query__c )
			{
				isDateQuery = false;
				isDateTimeQuery = true;
				isMathQuery = false;
			}
			else if (theConfig.Do_Math_Query__c )
			{
				isDateQuery = false;
				isDateTimeQuery = false;
				isMathQuery = true;
			}
			else
			{
				isDateQuery = false;
				isDateTimeQuery = false;
				isMathQuery = false;
			}
		}
		setQueryTypes();
	}

	public void setQueryTypes()
	{
		aggFunctionOptions = new List<SelectOption>();
		aggFunctionOptions.add(new SelectOption('', '-- Select --'));
		aggFunctionOptions.add(new SelectOption('MAX', 'MAX'));
		aggFunctionOptions.add(new SelectOption('MIN', 'MIN'));

		if ( isMathQuery )
		{
			aggFunctionOptions.add(new SelectOption('AVG', 'AVG'));
		}
	}

	public PageReference editConfiguration()
	{
		System.debug(LoggingLevel.WARN, '---> start editConfiguration');
		System.debug(LoggingLevel.WARN, '---> child object: ' + childObject);

		setObjects();
		showCreateSection = false;
		return null;
	}

	public PageReference doShowCreateSection()
	{
		showCreateSection = true;
		doEdit = 'false';
		childObject = null;
		parentObject = null;
		return null;
	}

	public RollupConfigs__c getRollupConfiguration(String childObjectName, String parentObjectName, String doEdit)
	{
		System.debug(LoggingLevel.WARN, '---> selectedConfigName: ' + selectedConfigName);
		RollupConfigs__c config;
		String suffix = '';
		List<RollupConfigs__c> configList =
		[
				SELECT Id, Name, Child_Object_Name__c, Parent_Object__c, parentRowCount__c, queryField_parentRelationshipName__c, Active__c, Use_Queueable__c
						, queryField1__c, queryField2__c, queryField3__c, queryField4__c, queryField5__c
						//, queryField6__c, queryField7__c, queryField8__c, queryField9__c, queryField10__c
						, parentQueryField1__c, parentQueryField2__c, parentQueryField3__c, parentQueryField4__c, parentQueryField5__c,
						Config_Notes__c, Additional_Filter_Clause__c, Do_Date_Query__c, Do_Date_Time_Query__c, Do_Math_Query__c, Date_Math_Query_Type__c
				//, parentQueryField6__c, parentQueryField7__c, parentQueryField8__c, parentQueryField9__c, parentQueryField10__c
				FROM RollupConfigs__c
				WHERE Child_Object_Name__c = :childObjectName
				AND Parent_Object__c = :parentObjectName
		];

		if (configList != null && configList.size() > 0)
		{
			if ( doEdit == 'true' )
			{
				if ( String.isNotBlank(selectedConfigName) )
				{
					for ( RollupConfigs__c tmpConfig : configList )
					{
						if ( tmpConfig.Name == selectedConfigName )
						{
							config = tmpConfig;
							break;
						}
					}
				}
				if ( config == null )
				{
					config = configList[0];
				}

			}
			else
			{
				suffix = ' (' + configList.size() + ')';
			}

		}

		if ( config == null )
		{
			config = new RollupConfigs__c();
			config.Name = childObject_Friendly + ' to ' + parentObject_Friendly + suffix;
			config.Child_Object_Name__c = childObjectName;
			config.Parent_Object__c = parentObjectName;
			config.Active__c = true;
		}


		return config;
	}

	public Map<String, RollupConfigs__c> getRollupConfigs()
	{
		Map<String, RollupConfigs__c> instanceMap = RollupConfigs__c.getAll();
		return instanceMap;
	}


	public List<RollupConfigs__c> getExistingConfigs(Map<String, RollupConfigs__c> configMap)
	{
		System.debug('---> start getExistingConfigs');
		List<RollupConfigs__c> configs;
		if (configMap != null && configMap.keySet().size() > 0)
		{
			configs = new List<RollupConfigs__c>();
			for (String s : configMap.keySet())
			{
				RollupConfigs__c config = configMap.get(s);
				configs.add(config);
			}
		}
		return configs;
	}

	public List<SelectOption> getObjectSelectOptions(List<String> allObjects, Map<String, Schema.SObjectType> objectMap)
	{
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('', '-- Select --'));

		if (allObjects != null && allObjects.size() > 0)
		{

			for (String objName : allObjects)
			{
				System.debug('---> objName: ' + objName);
				Schema.SObjectType o = objectMap.get(objName);
				if (o != null && !o.getDescribe().isCustomSetting() && o.getDescribe().getKeyPrefix() != null && o.getDescribe().isCreateable() && o.getDescribe().isAccessible())
				{
					System.debug('---> eligible child objects: ' + o.getDescribe().getChildRelationships());
					options.add(new SelectOption(o.getDescribe().getName(), o.getDescribe().getLabel() + ' (' + o.getDescribe().getName() + ')'));
				}
			}
		}

        /*
        else
        {
            // some sort of error message
        }
        */
		return options;
	}

    /* Save Methods */

	public PageReference customCancel()
	{
		PageReference pageRef = Page.SG_LRHSetup;
		pageRef.setRedirect(true);
		return pageRef;
	}

	public PageReference deleteConfig()
	{
		System.debug('---> start deleteConfig');
		if (theConfig != null && theConfig.Id != null)
		{
			try
			{
				delete theConfig;
				SG_DisplayUtils.addConfirm('Configuration deleted');
			}
			catch (Exception e)
			{
				System.debug('---> error deleting config: ' + e.getMessage());
				SG_DisplayUtils.addError('We encountered an error deleting your configuration. For reference, the error was: ' + e.getMessage()); // custom label...
				return null;
			}
		}
		return customCancel();
	}

	public PageReference saveConfig()
	{
		System.debug('---> start saveConfigs');

		Boolean hasError = false;

    	/* todo: validations */
		if (theConfig.queryField_parentRelationshipName__c == null || theConfig.queryField_parentRelationshipName__c.trim().length() < 1)
		{
			SG_DisplayUtils.addError('Please select the Lookup field on ' + childObject + ' that points to ' + parentObject);
			hasError = true;

			//SG_DisplayUtils.addError('Please select the Lookup field that points to the Parent');
			//return null;
		}
		if ( String.isBlank(theConfig.Date_Math_Query_Type__c) && (theConfig.Do_Date_Query__c || theConfig.Do_Date_Time_Query__c || theConfig.Do_Math_Query__c ))
		{
			SG_DisplayUtils.addError('Please select an Agggregate Query Type');
			hasError = true;
			//SG_DisplayUtils.addError('Please select an Agggregate Query Type');
			//return null;
		}

		if ( hasError )
		{
			System.debug(LoggingLevel.WARN, '---> failed validations');
			return null;
		}

		//showSampleTrigger = false;
		try
		{
			upsert theConfig;
			SG_DisplayUtils.addConfirm('Configuration saved');
			if (showSampleTrigger)
			{
				//showSampleTrigger = true;
				SG_DisplayUtils.addConfirm('Sample Trigger displayed at bottom of screen');
			}

			init();
		}
		catch (Exception e)
		{
			System.debug('---> exception saving lookup admin config: ' + e.getMessage());
			SG_DisplayUtils.addError('We encountered an error saving your configuration. For reference, the error was: ' + e.getMessage()); // custom label...
			return null;
		}
		return null;
	}

	public PageReference doShowTriggerReload()
	{

		return null;
	}

	public PageReference doMathQuerySelect()
	{
		theConfig.Do_Date_Time_Query__c = false;
		theConfig.Do_Date_Query__c = false;
		return doPageReload();
	}

	public PageReference doDateTimeSelect()
	{
		theConfig.Do_Math_Query__c = false;
		theConfig.Do_Date_Query__c = false;
		return doPageReload();
	}

	public PageReference doDateSelect()
	{
		theConfig.Do_Math_Query__c = false;
		theConfig.Do_Date_Time_Query__c = false;
		return doPageReload();
	}

	public PageReference doPageReload()
	{
		setAggregates();
		setAllowedFields();
		setDropDowns();
		return null;
	}


	public void setAllowedFields()
	{
		if ( isDateQuery )
		{
			allowedFieldTypes_Rollup = new Set<String>{ 'date' };
		}
		else if ( isDateTimeQuery )
		{
			allowedFieldTypes_Rollup = new Set<String>{ 'datetime' };
		}
		else
		{
			allowedFieldTypes_Rollup = new Set<String>{ 'currency', 'double', 'integer', 'percent' };
		}

		// set the lookup to parent fields
		allowedFieldTypes_Lookup = new Set<String>{ 'reference' };

		// set the parent rowcount field...
		rowCountFieldTypes = new Set<String>{  'double', 'integer' };

	}

	public void setDropDowns()
	{
		System.debug(LoggingLevel.WARN, '---> start setDropDowns');
		childObjectWrappers = getFieldWrappersForObject(childObject, allowedFieldTypes_Rollup, false);
		if (childObjectWrappers != null && childObjects.size() > 0)
		{
			childObjectFields = new List<SelectOption>();
			childObjectFields.add(new SelectOption('', '-- Select --'));
			if ( childObjectWrappers == null || childObjectWrappers.size() < 1)
			{
				childObjectFields.add(new SelectOption('', '-- No eligible rollup fields on ' + childObject + ' --'));
			}
			else
			{
				for (SG_ObjectWrapper wrap : childObjectWrappers)
				{
					childObjectFields.add(new SelectOption(wrap.key, wrap.label));
				}
			}

		}
		// build the list of Lookup fields for the parent relation...
		childObjectWrappers_Lookups = getFieldWrappersForObject(childObject, allowedFieldTypes_Lookup, false);
		if (childObjectWrappers_Lookups != null && childObjects.size() > 0)
		{
			childObjectFields_Lookups = new List<SelectOption>();
			childObjectFields_Lookups.add(new SelectOption('', '-- Select --'));

			for (SG_ObjectWrapper wrap : childObjectWrappers_Lookups)
			{
				childObjectFields_Lookups.add(new SelectOption(wrap.key, wrap.label));
			}
		}


		parentObjectWrappers = getFieldWrappersForObject(parentObject, allowedFieldTypes_Rollup, true);
		if (parentObjectWrappers != null && parentObjects.size() > 0)
		{
			parentObjectFields = new List<SelectOption>();
			parentObjectFields.add(new SelectOption('', '-- Select --'));
			if ( parentObjectWrappers == null || parentObjectWrappers.size() < 1)
			{
				parentObjectFields.add(new SelectOption('', '-- No eligible rollup fields on ' + parentObject + ' --'));
			}

			for (SG_ObjectWrapper wrap : parentObjectWrappers)
			{
				parentObjectFields.add(new SelectOption(wrap.key, wrap.label));
			}
			
			parentRowCountWrappers = getFieldWrappersForObject(parentObject, rowCountFieldTypes, true);
			parentRowcountFields = new List<SelectOption>();
			parentRowcountFields.add(new SelectOption('', '-- Select --'));

			if ( parentRowCountWrappers == null || parentRowCountWrappers.size() < 1)
			{
				parentRowcountFields.add(new SelectOption('', '-- No eligible row count fields on ' + parentObject + ' --'));
			}

			for (SG_ObjectWrapper wrap : parentRowCountWrappers)
			{
				parentRowcountFields.add(new SelectOption(wrap.key, wrap.label));
			}
		}


	}

	public PageReference setObjects()
	{
		System.debug('---> start setObjects');
		System.debug('---> childObject, parentObject: ' + childObject + ', ' + parentObject);

		//showSampleTrigger = false;

		if (childObject != null && parentObject != null)
		{

			childObject_Friendly = childObject.replace('__c', '');
			if (childObject_Friendly.length() > 22)
			{
				childObject_Friendly = childObject_Friendly.substring(0, 22);
			}

			parentObject_Friendly = parentObject.replace('__c', '');
			if (parentObject_Friendly.length() > 22)
			{
				parentObject_Friendly = parentObject_Friendly.substring(0, 22);
			}

			setAllowedFields();

			System.debug('---> looking for existing or new configuration for this child/parent');
			theConfig = getRollupConfiguration(childObject, parentObject, doEdit);

			setAggregates();
			setAllowedFields();
			setDropDowns();

		}
		else
		{
			SG_DisplayUtils.addError('Please select both a Child and a Parent object'); // custom label...
		}


		return null;
	}


	public Map<String, Schema.SObjectField> getFieldMap(String objectName)
	{
		Map<String, Schema.SObjectField> fieldMap;
		if (objectName != null && objectName.length() > 0)
		{
			Schema.SObjectType schemaObjType = schemaMap.get(objectName);
			if (schemaObjType != null)
			{
				fieldMap = schemaObjType.getDescribe().fields.getMap();
			}
		}

		return fieldMap;
	}

	public List<SG_ObjectWrapper> getFieldWrappersForObject(String objectName, Set<String> allowedFieldTypes, Boolean isParent)
	{
		List<SG_ObjectWrapper> wrappers;

		Map<String, Schema.SObjectField> fieldMap = getFieldMap(objectName);
		System.debug('---> allowedFieldTypes: ' + allowedFieldTypes);

		if (fieldMap != null && fieldMap.keySet() != null && fieldMap.keySet().size() > 0 && allowedFieldTypes != null && allowedFieldTypes.size() > 0)
		{
			wrappers = new List<SG_ObjectWrapper>();
			for (Schema.SObjectField field : fieldMap.values())
			{
				Schema.describeFieldResult descField = field.getDescribe();

				if (descField != null)
				{
					System.debug('---> descField: ' + descField.getName());

					String fieldType = String.valueOf(descField.getType());
					System.debug('---> fieldType: ' + fieldType);
					System.debug(LoggingLevel.WARN, '---> allowedFieldTypes: ' + allowedFieldTypes);
					System.debug(LoggingLevel.WARN, '---> field type toLowerCase: ' + fieldType.toLowerCase());
					if (fieldType != null && allowedFieldTypes.contains(fieldType.toLowerCase())  && descField.isAccessible() )
					{
						if ( isParent && !descField.isUpdateable() )
						{
							System.debug(LoggingLevel.WARN, '---> parent field not updateable...');
							continue;
						}
						else
						{
							System.debug('---> found match');
							Boolean isMultiValue = false; // TODO: do we care about this???
							SG_ObjectWrapper wrap = new SG_ObjectWrapper(descField, isMultiValue);
							wrappers.add(wrap);
						}

					}
				}
			}
			wrappers = getSortedObjectWrappers(wrappers);
		}
		else
		{
			System.debug('---> encountered error getting field map for: ' + objectName);
			SG_DisplayUtils.addError('Encountered an error getting fields for your object (' + objectName + ').  Please ensure this object is supported.');
		}

		return wrappers;
	}

	/* todo: use wrapper sorter */
	public List<SG_ObjectWrapper> getSortedObjectWrappers(List<SG_ObjectWrapper> wrappers)
	{
		List<SG_ObjectWrapper> returnList = new List<SG_ObjectWrapper>();
		if (wrappers != null && wrappers.size() > 0)
		{
			List<SG_ObjectWrapper> beforeMidList = new List<SG_ObjectWrapper>();
			List<SG_ObjectWrapper> afterMidList = new List<SG_ObjectWrapper>();
			Integer midpoint = wrappers.size() / 2;

			// use midpoint as the reference point -- remove it from the list
			SG_ObjectWrapper midpointValue = wrappers[midpoint];
			wrappers.remove(midpoint);

			for (SG_ObjectWrapper x : wrappers)
			{
				if (x.label <= midpointValue.label)
				{
					beforeMidList.add(x);
				}
				else if (x.label > midpointValue.label)
				{
					afterMidList.add(x);
				}
			}

			// now recursively build out the lists -- the ones that were less than the midpoint, the midpoint, and then those greater than the midpoint
			returnList.addAll(getSortedObjectWrappers(beforeMidList));
			returnList.add(midpointValue);
			returnList.addAll(getSortedObjectWrappers(afterMidList));
		}

		return returnList;
	}

	public class SG_ObjectWrapper {


		public Boolean isSelected {get; set;}
		public Boolean isMultiValue {get; set;}
		public String key {get; set;}
		public String label {get; set;}
		public String type {get; set;}
		//public List<SG_PicklistWrapper> picklistValues {get; set;}


		public SG_ObjectWrapper( Schema.describeFieldResult descField, Boolean isMultiValue )
		{
			this.isMultiValue = ( isMultiValue == null ? false : isMultiValue ); // default to false
			if ( descField != null )
			{
				this.key = descField.getName();
				this.type = String.valueOf(descField.getType());
				this.label = descField.getLabel();
				
				System.debug('---> building wrapper for: ' + this.label);

				// get a map of maps -- the field, and a map of all the key/value pairs for tags
				Map<String, String> sfdcFieldToTagValueMap;

				// if we have an entry in the map for this field, we know we have previously saved it -- so, select the Wrapper
				Boolean isMappedField = false;
				if ( sfdcFieldToTagValueMap != null && sfdcFieldToTagValueMap.keySet().size() > 0 )
				{
					this.isSelected = true; 
					isMappedField = true;
				}
      
			}
		}

	}

}