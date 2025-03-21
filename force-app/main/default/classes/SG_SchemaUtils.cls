/**********************************************************************
* Name:   	SG_SchemaUtils
* Author: 	Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date: 	21 Oct 2012
* ======================================================
* ======================================================
* Purpose:                                                            
* This class is used to help describe SObjects  
*                                                            
* ======================================================
* ======================================================
* History:                                                            
* VERSION	DATE            INITIALS	DESCRIPTION/FEATURES ADDED
* 1.0     	21 Oct 2012     CS			Initial Development           
*   
***********************************************************************/

public with sharing class SG_SchemaUtils {


	/***********************************************************************
	 *
	 * FieldSet Methods
	 *
	 *********************************************************************/
	public static List<Schema.FieldSetMember> getFieldSetMembers(String fieldSetName, String ObjectName)
	{
		Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
		Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
		Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();

		Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
		return fieldSetObj.getFields();
	}

	/***********************************************************************
	*
	* Id Methods
	*
	*********************************************************************/	

    //This will throw an exception if the string isn't a proper Id
    public static String to18(String the15charID){    	
		String the18charID;		
	    ID the18charIDasId = the15charID;
	    the18charId = the18charIDasId;			
		return the18charID;
    }

	/***********************************************************************
	*
	* Record Type Id Methods
	*
	*********************************************************************/
	
	private static Map<String,Map<String,Id>> objectNameToRecordTypeIdMap;

	// hasRecordTypeEnabled
	public static Boolean hasRecordTypeEnabled(String objectName)
	{
		return getRecordTypeIds(objectName).size() > 0;
	}
	
	// getRecordTypeId
	// Example getRecordTypeId('myobject__c', 'Standard Record Type'); //It uses the LABEL of the Record Type
	public static Id getRecordTypeId(String objectName, String name)
	{			
		return 	getRecordTypeIds(objectName).get(name);	
	}
	
	// getRecordTypeIds		
	public static Map<String,Id> getRecordTypeIds(String objectName)
	{	
		
		if(objectNameToRecordTypeIdMap != null && objectNameToRecordTypeIdMap.containsKey(objectName))
		{
			return objectNameToRecordTypeIdMap.get(objectName);
		}
		else
		{	
			Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
			return 	getRecordTypeIds(objectType);
		}
	}

	// getRecordTypeIds
	public static Map<String,Id> getRecordTypeIds(Sobject obj)
	{
		Schema.SObjectType objectType = obj.getsObjectType();		
		return 	getRecordTypeIds(objectType.getDescribe().getName());
	}

	private static Map<String,Id> getRecordTypeIds(Schema.SObjectType objectType)
	{
		if(objectNameToRecordTypeIdMap == null)
		{
			objectNameToRecordTypeIdMap = new Map<String,Map<String,Id>>();
		}
		
		Map<String,Id> recordTypeIdMap = new Map<String,Id>();
		if (objectType != null) 
		{
        	Schema.DescribeSObjectResult describeResult = objectType.getDescribe();
        	List<Schema.RecordTypeInfo> recordTypeInfos = describeResult.getRecordTypeInfos();
        	for(Schema.RecordTypeInfo rtInfo : recordTypeInfos)
        	{   
        		String name = rtInfo.getName();
        		if(rtInfo.isAvailable() && name != null && !name.equalsIgnoreCase('Master'))
        		{	        	
        			recordTypeIdMap.put(name,rtInfo.getRecordTypeId());
        		}
        	}
        	
        	objectNameToRecordTypeIdMap.put(describeResult.getName(),recordTypeIdMap);
        }        
        
        return recordTypeIdMap;	
	}	

	/***********************************************************************
	*
	* Field & Object Security Methods
	*
	*********************************************************************/
	

	//Cache of field maps to reduce describe calls	
	public static Map<String,Map<String,Schema.SObjectField>> objectTofieldMapMap;	
	
	public static Boolean isCreatable(List<SObject> objects)
	{
		if(objects != null && objects.size() > 0)
		{
			return isCreatable(objects[0]);
		}
		return false;
	}
		
	public static Boolean isCreatable(SObject obj) 
	{
		Schema.SObjectType sObjType = obj.getsObjectType();
		return sObjType.getDescribe().isCreateable();
	}
	
	public static Boolean isUpdateable(List<SObject> objects)
	{
		if(objects != null && objects.size() > 0)
		{
			return isUpdateable(objects[0]);
		}
		return false;
	}
	
	public static Boolean isUpdateable(SObject obj) 
	{
		Schema.SObjectType sObjType = obj.getsObjectType();
		return sObjType.getDescribe().isUpdateable();
	}
	
	public static Boolean isUpsertable(List<SObject> objects)
	{
		if(objects != null && objects.size() > 0)
		{
			return isUpsertable(objects[0]);
		}
		return false;
	}
	
	public static Boolean isUpsertable(SObject obj) 
	{
		Schema.SObjectType sObjType = obj.getsObjectType();
		Boolean updatable = sObjType.getDescribe().isUpdateable();
		Boolean creatable = sObjType.getDescribe().isCreateable();
		
		if(updatable && creatable)		
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	
	public static Boolean isDeletable(List<SObject> objects)
	{
		if(objects != null && objects.size() > 0)
		{
			return isDeletable(objects[0]);
		}
		return false;
	}
	
	public static Boolean isDeletable(SObject obj) 
	{
		Schema.SObjectType sObjType = obj.getsObjectType();
		return sObjType.getDescribe().isDeletable();
	}
	/*
	public static Boolean fieldsAreCreatable(SObject obj,List<String> fieldsToCheck)
	{		
		Map<String,Schema.SObjectField> fieldMap = getFieldMap(obj);
	  	for (String fieldToCheck : fieldsToCheck) 
	  	{
			// Check if the user has create access on each field
		    if(fieldMap.get(fieldToCheck) == null)
		    {
		   		return false;
		    }
		    else if (!fieldMap.get(fieldToCheck).getDescribe().isCreateable()) 
		    {
		    	return false;
		    }
		}
		return false;
	}
	
	public static Boolean fieldsAreUpdatable(SObject obj,List<String> fieldsToCheck)
	{
		
		Map<String,Schema.SObjectField> fieldMap = getFieldMap(obj);
		for (String fieldToCheck : fieldsToCheck) 
	  	{
	   		// Check if the user has create access on each field
	   		if(fieldMap.get(fieldToCheck) == null)
	   		{
	   			return false;
	   		}
	   			else if (!fieldMap.get(fieldToCheck).getDescribe().isUpdateable()) 
	   		{
	    		return false;
	   		}
	  	}
	  	return false;
	}
	
	public static Boolean fieldsAreUpsertable(SObject obj,List<String> fieldsToCheck)
	{
		
		Map<String,Schema.SObjectField> fieldMap = getFieldMap(obj);
		for (String fieldToCheck : fieldsToCheck) 
	 	{
		   	// Check if the user has create access on each field
		   	if(fieldMap.get(fieldToCheck) == null)
		   	{
			   	return false;
		   	}		   	
		   	else if (!fieldMap.get(fieldToCheck).getDescribe().isUpdateable()) 
		   	{
			    return false;
		   	}
		   	else if (!fieldMap.get(fieldToCheck).getDescribe().isCreateable()) 
		   	{
			    return false;
		   	}
	  	}
	  	return false;
	}
	*/
	public static Map<String,Schema.SObjectField> getFieldMap(List<SObject> objects) 
	{
		if(objects != null && objects.size() > 0)
		{
			return getFieldMap(objects[0]);
		}		
					
		return new Map<String,Schema.SObjectField>();
	}
	
	
	public static Map<String,Schema.SObjectField> getFieldMap(SObject obj) 
	{		
		if(obj == null) return new Map<String,Schema.SObjectField>();
		
		String objName = obj.getsObjectType().getDescribe().getName();
		
		if(objectTofieldMapMap == null) 
		{
			objectTofieldMapMap = new Map<String,Map<String,Schema.SObjectField>>(); 
		}
		
		Map<String,Schema.SObjectField> fieldMap = new Map<String,Schema.SObjectField>();
		
		if(objectTofieldMapMap.containsKey(objName)) 
		{
			fieldMap = objectTofieldMapMap.get(objName);
		} 
		else 
		{
			Map<String, Schema.SObjectType> gdMap = Schema.getGlobalDescribe();
        	Schema.Describesobjectresult dsr = gdMap.get(objName).getDescribe();
			fieldMap = dsr.fields.getMap();
			objectTofieldMapMap.put(objName,fieldMap);		
		}		
	 	return fieldMap; 
	}

	/*
	** methods to create a dynamic query to retrieve the fields specified in the list from
	** the specified sObject with the specified criteria expression
	** to specify the fields you can use the map returned by getFieldMap() or a Set of strings
	*/
	public static List<SObject> queryFullSObject(
						Map<String, Schema.SObjectField> fieldMap
						, String objectName, String whereClause )
	{
		if( fieldMap == null ) return null;

		return queryFullSObject( fieldMap.keySet(), objectName, whereClause );
	}

	public static List<SObject> queryFullSObject( Set<String> fieldNames
								, String objectName, String whereClause )
	{
		if( fieldNames == null || fieldNames.size() < 1 ) return null;

		List<String> fieldNameList = new List<String>( fieldNames );
		String allFields = String.join( fieldNameList, ',' );
		System.debug( 'allFields = ' + allFields );

		String qry = 'SELECT ' + allFields + ' FROM ' + objectName + ' ';

		if( whereClause != null && whereClause.trim().length() > 0 )
		{
			if( whereClause.contains( 'WHERE' ) )
			{
				qry = qry + whereClause;
			}
			else
			{
				qry = qry + ' WHERE ' + whereClause;
			}
		}

		System.debug( 'Dynamic query = ' + qry );

		System.debug(LoggingLevel.WARN, '---> dynamic full query: ' + qry );

		List<SObject> fullObjects = Database.query( qry );

		return fullObjects;
	}
	
	//TODO
	
	public static Boolean isValidFieldName(List<SObject> objects, String fieldName)
	{
		return isValidFieldName(objects[0],fieldName);
	}
	
	public static Boolean isValidFieldName(SObject obj, String fieldName)
	{
		Boolean hasField = false;
		Map<String,Schema.SObjectField> fieldMap = getFieldMap(obj);
		if(fieldMap != null && fieldMap.containsKey(fieldName))		
		{
  			hasField = true;
		}
		return hasField;
	}
		
}