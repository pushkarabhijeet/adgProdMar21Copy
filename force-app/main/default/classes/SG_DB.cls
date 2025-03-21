/**********************************************************************
* Name:   	SG_DB
* Author: 	Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date: 	21 Oct 2012
* ======================================================
* ======================================================
* Purpose:                                                            
* This class is used to ensure consistent error handling for records being inserted, updated, upserted, deleted from the system. 
* This class helps ensure only a single record will fail, but all other records can still succeed in their options.                                                            
* ======================================================
* ======================================================
* History:                                                            
* VERSION	DATE            INITIALS	DESCRIPTION/FEATURES ADDED
* 1.0     	21 Oct 2012     CS			Initial Development           
*   
***********************************************************************/

//TODO - updateParentFromChild, updateChildFromParent, updateSelf (i.e. errors on self)
//insertSelf, insertChildFromParent, insertParentFromChild???
//upsertSelf upsertChildFromParent, upsertParentFromChild???
//deleteChildFromParent, deleteSelf

public class SG_DB 
{
	
	/************
	*
	* DML Methods
	*
	************ */

	/*
	 * The below code is very SIMPLE. It ensures no errors are thrown and are instead put into a String
	 *
	 */
	public static String insertRecords(List<SObject> objectsToInsert)
	{
		// DML statement
		Database.SaveResult[] results = Database.insert(objectsToInsert,false);

		// Iterate through each returned result
		String allErrors = '';
		for (Integer i = 0; i < results.size(); i++)
		{
			Database.SaveResult sr = results[i];
			if (!sr.isSuccess())
			{
				String fullErrorMsg = 'There was an error updating the record with Name ' + objectsToInsert[i].get('Name') + '\n';
				// Operation failed, so get all errors
				for(Database.Error err : sr.getErrors())
				{
					String errorMsg = 'The following error has occurred: ' + '\n';
					errorMsg += err.getStatusCode() + ': ' + err.getMessage() + '\n';
					errorMsg += ' fields that affected this error: ' + err.getFields();
					System.debug(errorMsg);

					fullErrorMsg += errorMsg + '\n';
				}
			}
		}

		return allErrors;
		/* Note that you can then do something like this
		String allErrors = SG_DB.insertRecords(objects);
		if(allErrors.length() > 2)
		{
			SG_ErrorHelper.notifyOnError('ClassName','Exception Name','Email Subject',allErrors);
		}
		*/
	}

	public static String updateRecords(List<Sobject> objectsToUpdate)
	{
		// DML statement
		Database.SaveResult[] results = Database.update(objectsToUpdate,false);

		// Iterate through each returned result
		String allErrors = '';
		for (Database.SaveResult sr : results)
		{
			if (!sr.isSuccess())
			{
				String fullErrorMsg = 'There was an error updating the record with Id ' + sr.getId() + '\n';
				// Operation failed, so get all errors
				for(Database.Error err : sr.getErrors())
				{
					String errorMsg = 'The following error has occurred: ' + '\n';
					errorMsg += err.getStatusCode() + ': ' + err.getMessage() + '\n';
					errorMsg += ' fields that affected this error: ' + err.getFields();
					System.debug(errorMsg);

					fullErrorMsg += errorMsg + '\n';
				}
			}
		}

		return allErrors;
		/* Note that you can then do something like this
		String allErrors = SG_DB.updateRecords(objects);
		if(allErrors.length() > 2)
		{
			SG_ErrorHelper.notifyOnError('ClassName','Exception Name','Email Subject',allErrors);
		}
		*/
	}


	/*
	 * The below code is very complex and powerful. It can be used to add errors to records that boil up.
	 *
	 */

	/************************************************
	                        	INSERT
	******************************************************************************/

	/**
	 * INSERT CHILD
	 */
	public static void insertChildObjects(List<SObject> childObjectsToInsert, Map<Id,SObject> parentObjectMap, String fieldNameOnChildThatReferencesParent, Database.Dmloptions dmlOp, Boolean emailOnlyErrors, String callingApexClassName, Exception expForLineNumber) {
		System.debug('*** BEGIN: updateParentObjects');
		
		try {
		
			if(childObjectsToInsert == null || childObjectsToInsert.size() == 0) throw new EmptyListException(callingApexClassName + ' calling SObjectUtils:insertChildObjects: Empty List<SObject>()');
														
			String objectTypeLabel = childObjectsToInsert[0].getSObjectType().getDescribe().getLabel();
			
			if(dmlOp != null) 
			{
				for(SObject objToInsert : childObjectsToInsert) 
				{
					objToInsert.setOptions(dmlOp);
				}
			}
			
			Database.Saveresult[] results;
			/*
				if(dmlOps == null) {
					results = Database.update(cases, false);
				} else {
					results = Database.update(cases, dmlOps);
				}
			*/
			if(dmlOp == null)
			{
	        	results = Database.insert(childObjectsToInsert, false);
			}
			else
			{
				results = Database.insert(childObjectsToInsert, dmlOp);
			}
		  		  
		    Boolean isError = false;		    
		    String allErrorMessages	= '';
		    
		   	Integer counter = 0;    
		    for(Database.Saveresult result : results) 
		    {	    	    	 	    
		    	if(!result.isSuccess()) 
		    	{
		        	isError = true;
		            String allSubErrorMessages = 'Error(s) with insert of ' + objectTypeLabel;		            		            
		            allSubErrorMessages += '.\n';
		            
		            //Could simply just take the first error!?!?
		            for(Database.Error err : result.getErrors()) 
		            {
		            	allSubErrorMessages += SG_DisplayUtils.errorToPrettyString(err) + '\n'; //SG_StringUtils.LF;		            	
		            }	            	            	           	        	                
		            allErrorMessages += allSubErrorMessages;
		            		            
					SG_DisplayUtils.debug('SG_SObjectHelper', 'insertChildObjects', 'allSubErrorMessages = ' + allSubErrorMessages);
					
					if(parentObjectMap != null && parentObjectMap.size() > 0 && childObjectsToInsert[counter].get(fieldNameOnChildThatReferencesParent) != null) 
					{						
		    			SObject affectedParent = parentObjectMap.get((Id)childObjectsToInsert[counter].get(fieldNameOnChildThatReferencesParent));
		    					    			
		    			SG_DisplayUtils.debug('SG_SObjectHelper', 'insertChildObjects', 'affectedParent = ' + affectedParent);
		    			
		    			affectedParent.addError(allSubErrorMessages);
		        	}
	        	}
	        	else //SUCCESS 
	        	{
		        	//On insert of child do nothing. The Id of the parent won't change		        	
		    	}
		    	counter++;
		    }
		    
		    if(isError) 
		    {
		    	if(emailOnlyErrors == null || emailOnlyErrors == true) 
		    	{
			    	notifyOnError(callingApexClassName, 'insertChildObjectsException', expForLineNumber, 'Error Messages: ' + allErrorMessages);
		    	}
		    	else 
		    	{
		    		throw new ErrorsFoundException(allErrorMessages);
		    	}			    
		    }
		}
		catch (Exception exp) 
		{
			SG_DisplayUtils.debug('SG_SObjectHelper', 'insertChildObjects', 'exp = ' + exp);
		    			
			if(emailOnlyErrors == null || emailOnlyErrors == true) //This line of code can pretty much NEVER happen b/c the code above will rarely throw an exception
			{
				notifyOnError(callingApexClassName, 'insertChildObjectsException', exp, 'Error Messages: ' + exp.getMessage());				
			} 
			else 
			{
				throw exp;
			}
		}
	}

	/************************************************
	                        	UPDATE
	******************************************************************************/

	/**
	 * UPDATE CHILD
	 */
	public static void updateChildObjects(List<SObject> childObjectsToUpdate, Map<Id,SObject> parentObjectMap, String fieldNameOnChildThatReferencesParent, Database.Dmloptions dmlOp, Boolean emailOnlyErrors, String callingApexClassName, Exception expForLineNumber) {
		System.debug('*** BEGIN: updateParentObjects');
		
		try {
		
			if(childObjectsToUpdate == null || childObjectsToUpdate.size() == 0) throw new EmptyListException(callingApexClassName + ' calling SObjectUtils:updateChildObjects: Empty List<SObject>()');
														
			String objectTypeLabel = childObjectsToUpdate[0].getSObjectType().getDescribe().getLabel();
			
			if(dmlOp != null) 
			{
				for(SObject objToUpdate : childObjectsToUpdate) 
				{
					objToUpdate.setOptions(dmlOp);
				}
			}
			
			Database.Saveresult[] results;
			
		    if(dmlOp == null)
			{
	        	results = Database.update(childObjectsToUpdate, false);
			}
			else
			{
				results = Database.update(childObjectsToUpdate, dmlOp);
			}
		    
		    Boolean isError = false;		    
		    String allErrorMessages	= '';
		    
		   	Integer counter = 0;    
		    for(Database.Saveresult result : results) 
		    {	    	    	 	    
		    	if(!result.isSuccess()) 
		    	{
		        	isError = true;
		            String allSubErrorMessages = 'Error(s) with update of ' + objectTypeLabel;
		            
		            if(childObjectsToUpdate[counter].Id != null) 
		           	{
		            	allSubErrorMessages += ' with id ' + childObjectsToUpdate[counter].Id;
		           	}
		             
		            allSubErrorMessages += '.\n';
		            //Could simply just take the first error!?!?
		            for(Database.Error err : result.getErrors()) 
		            {
		            	allSubErrorMessages += SG_DisplayUtils.errorToPrettyString(err) + '\n'; //SG_StringUtils.LF;		            	
		            }	            	            	           	        	                
		            allErrorMessages += allSubErrorMessages;
		            		            
					SG_DisplayUtils.debug('SG_SObjectHelper', 'updateChildObjects', 'allSubErrorMessages = ' + allSubErrorMessages);
					
					if(parentObjectMap != null && parentObjectMap.size() > 0 && childObjectsToUpdate[counter].get(fieldNameOnChildThatReferencesParent) != null) 
					{						
		    			SObject affectedParent = parentObjectMap.get((Id)childObjectsToUpdate[counter].get(fieldNameOnChildThatReferencesParent));
		    					    			
		    			SG_DisplayUtils.debug('SG_SObjectHelper', 'updateChildObjects', 'affectedParent = ' + affectedParent);
		    			
		    			affectedParent.addError(allSubErrorMessages);
		        	}
	        	}
	        	else //SUCCESS 
	        	{
		        	//On update success, do nothing. The Id of the parent can't change		        	
		    	}
		    	counter++;
		    }
		    
		    if(isError) 
		    {
		    	if(emailOnlyErrors == null || emailOnlyErrors == true) 
		    	{
			    	notifyOnError(callingApexClassName, 'updateChildObjectsException', expForLineNumber, 'Error Messages: ' + allErrorMessages);
		    	}
		    	else 
		    	{
		    		throw new ErrorsFoundException(allErrorMessages);
		    	}			    
		    }
		}
		catch (Exception exp) 
		{
			SG_DisplayUtils.debug('SG_SObjectHelper', 'updateChildObjects', 'exp = ' + exp);
		    			
			if(emailOnlyErrors == null || emailOnlyErrors == true) //This line of code can pretty much NEVER happen b/c the code above will rarely throw an exception
			{
				notifyOnError(callingApexClassName, 'updateChildObjectsException', exp, 'Error Messages: ' + exp.getMessage());				
			} 
			else 
			{
				throw exp;
			}
		}
	}

	/**
	 * UPDATE PARENT
	 */
	public static void updateParentObjects(List<SObject> parentObjectsToUpdate, List<SObject> childObjects, String fieldNameOnChildThatReferencesParent, Database.Dmloptions dmlOp, Boolean emailOnlyErrors, String callingApexClassName, Exception expForLineNumber) {
		System.debug('*** BEGIN: updateParentObjects');
		
		try {
		
			if(parentObjectsToUpdate == null || parentObjectsToUpdate.size() == 0) throw new EmptyListException(callingApexClassName + ' calling SObjectUtils:updateParentObjects: Empty List<SObject>()');
			
			//Create a map so we can easily retrieve the child objects based on the parent Id
			Map<Id,List<SObject>> parentIdToChildList = new Map<Id,List<SObject>>();			 
			if(fieldNameOnChildThatReferencesParent != null && childObjects != null && childObjects.size() > 0)
			{
				for(SObject childObject : childObjects)
				{				
					Id parentId = (Id)childObject.get(fieldNameOnChildThatReferencesParent);
					if(parentId != null)
					{
						if(parentIdToChildList.containsKey(parentId))
						{
							parentIdToChildList.get(parentId).add(childObject);
						}
						else //need a new list
						{
							List<SObject> tmpList = new List<SObject>();
							tmpList.add(childObject);
							parentIdToChildList.put(parentId,tmpList);
						}
					}					
				}
			}
									
			String objectTypeLabel = parentObjectsToUpdate[0].getSObjectType().getDescribe().getLabel();
			
			if(dmlOp != null) 
			{
				for(SObject objToUpdate : parentObjectsToUpdate) 
				{
					objToUpdate.setOptions(dmlOp);
				}
			}
			
			Database.Saveresult[] results;
			
			if(dmlOp == null)
			{
	        	results = Database.update(parentObjectsToUpdate, false);
			}
			else
			{
				results = Database.update(parentObjectsToUpdate, dmlOp);
			}
		    
		    Boolean isError = false;		    
		    String allErrorMessages	= '';
		    
		   	Integer counter = 0;    
		    for(Database.Saveresult result : results) 
		    {	    	    	 	    
		    	if(!result.isSuccess()) 
		    	{
		        	isError = true;
		            String allSubErrorMessages = 'Error(s) with update of ' + objectTypeLabel;
		            
		            if(parentObjectsToUpdate[counter].Id != null) 
		           	{
		            	allSubErrorMessages += ' with id ' + parentObjectsToUpdate[counter].Id;
		           	}
		             
		            allSubErrorMessages += '.\n';
		            //Could simply just take the first error!?!?
		            for(Database.Error err : result.getErrors()) 
		            {
		            	allSubErrorMessages += SG_DisplayUtils.errorToPrettyString(err) + '\n'; //SG_StringUtils.LF;		            	
		            }	            	            	           	        	                
		            allErrorMessages += allSubErrorMessages;
		            		            
					SG_DisplayUtils.debug('SG_SObjectHelper', 'updateParentSObjects', 'allSubErrorMessages = ' + allSubErrorMessages);
					
					if(parentIdToChildList != null && parentIdToChildList.size() > 0 && parentObjectsToUpdate[counter].Id != null) 
					{
						
		    			List<SObject> affectedChildren = parentIdToChildList.get(parentObjectsToUpdate[counter].Id);
		    					    			
		    			SG_DisplayUtils.debug('SG_SObjectHelper', 'updateParentSObjects', 'affectedChildren = ' + affectedChildren);
		    			
		    			for(SObject child : affectedChildren)
		    			{
		    				child.addError(allSubErrorMessages);
		    			}
		        	}
	        	}
	        	else //SUCCESS 
	        	{
		        	//On update success, do nothing. The Id of the parent can't change		        	
		    	}
		    	counter++;
		    }
		    
		    if(isError) 
		    {
		    	if(emailOnlyErrors == null || emailOnlyErrors == true) 
		    	{
			    	notifyOnError(callingApexClassName, 'updateParentObjectsException', expForLineNumber, 'Error Messages: ' + allErrorMessages);
		    	}
		    	else 
		    	{
		    		throw new ErrorsFoundException(allErrorMessages);
		    	}			    
		    }
		}
		catch (Exception exp) 
		{
			SG_DisplayUtils.debug('SG_SObjectHelper', 'updateParentSObjects', 'exp = ' + exp);
		    			
			if(emailOnlyErrors == null || emailOnlyErrors == true) //This line of code can pretty much NEVER happen b/c the code above will rarely throw an exception
			{
				notifyOnError(callingApexClassName, 'updateParentObjectsException', exp, 'Error Messages: ' + exp.getMessage());				
			} 
			else
			{
				throw exp;
			}
		}
	}

	private static void notifyOnError(String callingApexClassName, String exceptionName, Exception expForLineNumber, String errorMessage) {
		String errorBody = 'Exception calling SObjectUtils from ' + callingApexClassName + ' line number ' + expForLineNumber.getLineNumber() + '\n';
		errorBody += 'Error Messages: ' + errorMessage;
		
		String subject = 'Exception calling SObjectUtils from ' + callingApexClassName;
		
    	SG_ErrorHelper.notifyOnError(callingApexClassName, exceptionName, subject, errorBody);
	}
	           
	public class EmptyListException extends Exception {}
	public class ErrorsFoundException extends Exception {}
	public class GenericException extends Exception {}
}