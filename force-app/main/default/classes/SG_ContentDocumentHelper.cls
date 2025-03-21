/**********************************************************************
* Name:     SG_ContentDocumentHelper
* Author:   Strategic Growth, Inc. (www.strategicgrowthinc.com)
*  
* ======================================================
* ======================================================
* Purpose:  Utility methods for working with ContentDocuments (aka Files)
* 
* ======================================================
* ======================================================
* History:                                                            
* VERSION   DATE            INITIALS      DESCRIPTION/FEATURES ADDED
* 1.0       17-Jun-2020     rwd           Initial Development           
*   
***********************************************************************/


public class SG_ContentDocumentHelper
{
	public static Boolean hasSetAsset = false;
	public static Boolean hasSetFileNames = false;
	public static Boolean hasSetFileNames_CDL = false;

	private static Map <String, Schema.SObjectType> schemaMap;

	@AuraEnabled
	public static Boolean setHiddenPictureFieldForQC( String recordId, String fieldName, String fieldValue 	)
	{
		System.debug(LoggingLevel.WARN, '---> start setHiddenPictureField');
		Boolean isSuccess = false;
		try
		{
			if (  String.isNotBlank(recordId) && String.isNotBlank(fieldName) && String.isNotBlank(fieldValue) )
			{
				System.debug(LoggingLevel.WARN, '---> fieldName: ' + fieldName );
				System.debug(LoggingLevel.WARN, '---> fieldValue: ' + fieldValue );
				Quality_Control__c qc = new Quality_Control__c(id=recordId);
				qc.put( fieldName, fieldValue );
				update qc;

				isSuccess = true;
			}
		}
		catch (Exception e)
		{
			isSuccess = false;
			System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );
		}
		return isSuccess;
	}


	// invoked by Lightning Web Components to rename a File to something more meaningful than just the image name
	@AuraEnabled
	public static Boolean doCustomQcFileName(String fileIds, String prefix)
	{
		System.debug(LoggingLevel.WARN, '---> start doCustomQcFileName');
		System.debug(LoggingLevel.WARN, '---> fileIds: ' + fileIds );
		System.debug(LoggingLevel.WARN, '---> prefix: ' + prefix );
		Boolean isSuccess = false;
		try
		{
			if ( fileIds != null && String.isNotBlank(prefix) )
			{
				Set<String> parsedIds = SG_DisplayUtils.parseIncomingStringIntoSet( fileIds );
				List<ContentDocument> updateList = new List<ContentDocument>();
				for ( ContentDocument doc : [SELECT Id, Title FROM ContentDocument WHERE Id IN :parsedIds])
				{
					String title = prefix + doc.Title;
					doc.Title = title.left(254);
					updateList.add( doc );
				}

				System.debug(LoggingLevel.WARN, '---> updateList: ' + updateList);
				if ( updateList != null && updateList.size() > 0 )
				{
					update updateList;
					isSuccess = true;
				}
			}
		}
		catch (Exception e)
		{
			System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );
		}

		return isSuccess;

	}

	// link the new File to a Work Order's Asset record (House/Unit)
	public static void addFileToAsset(System.TriggerOperation triggerEvent, List<ContentDocumentLink> newCdls, Map<Id, ContentDocumentLink> oldCdls)
	{
		System.debug(LoggingLevel.WARN, '---> start addFileToAsset');

		// set the enum of allowed trigger operations (before insert, after update, etc)
		List<TriggerOperation> triggerTypes = new List<TriggerOperation>{
				TriggerOperation.AFTER_INSERT
		};
		if ( !SG_DisplayUtils.canFireTrigger( triggerEvent, triggerTypes, hasSetAsset ) )
		{
			System.debug(LoggingLevel.WARN, '---> already hasSetAsset: ' + hasSetAsset + ' or wrong trigger type; skip');
			return;
		}

		if ( newCdls != null && newCdls.size() > 0 )
		{
			String keyPrefix = Quality_Control__c.sObjectType.getDescribe().getKeyPrefix();
            
			Map<Id, Set<Id>> entityToDocIdsMap = new Map<Id, Set<Id>>();
			Set<Id> allDocIds = new Set<Id>();
			List<ContentDocumentLink> insertCdls = new List<ContentDocumentLink>();

			//System.debug(LoggingLevel.WARN, '---> keyPrefix: ' + keyPrefix);

			for ( ContentDocumentLink cdl : newCdls )
			{
				System.debug(LoggingLevel.WARN, '---> cdl: ' + cdl );
				String prefix = String.valueOf(cdl.LinkedEntityId).substring(0,3);
				if ( prefix == keyPrefix )
				{
					System.debug(LoggingLevel.WARN, '---> QC file!');

					Set<Id> tmpSet = entityToDocIdsMap.get( cdl.LinkedEntityId );
					if ( tmpSet == null ) tmpSet = new Set<Id>();
					tmpSet.add( cdl.ContentDocumentId );
					entityToDocIdsMap.put( cdl.LinkedEntityId, tmpSet );

					allDocIds.add( cdl.ContentDocumentId );
				}
			}

			// get the documents...
			if ( entityToDocIdsMap != null && entityToDocIdsMap.keySet().size() > 0 && allDocIds != null )
			{
				// get all the documents and group by QC...

				Map<Id, Quality_Control__c> qcMap = new Map<Id, Quality_Control__c>([SELECT Id, House_Unit__c FROM Quality_Control__c WHERE Id IN :entityToDocIdsMap.keySet()]);
				for ( Id entityId : entityToDocIdsMap.keySet() )
				{
					Quality_Control__c qc = qcMap.get( entityId );
					Set<Id> docIds = entityToDocIdsMap.get( entityId );
					if ( qc != null && qc.House_Unit__c != null && docIds != null )
					{
						for ( Id docId : docIds )
						{
							System.debug(LoggingLevel.WARN, '---> creating a new content document link...');

							ContentDocumentLink cdl = new ContentDocumentLink();
							cdl.contentdocumentid = docId;
							cdl.LinkedEntityId = qc.House_Unit__c;
							cdl.ShareType= 'I';

							insertCdls.add( cdl );

						}
						System.debug(LoggingLevel.WARN, '---> cdls to insert: ' + insertCdls );
						if ( insertCdls != null && insertCdls.size() > 0 )
						{
							try
							{
								insert insertCdls;
							}
							catch (Exception e )
							{
								System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );
							}
						}
					}
				}

			}
            addCaseFilesToAsset(newCdls); //Share Case Files to House
		}

	}


	// FSL Mobile does not always trigger the QC file rename upon file upload. So, let's force it to fire when a file is uploaded
	public static void setFileNamesFromCDLUpload(System.TriggerOperation triggerEvent, List<ContentDocumentLink> newDocs, Map<Id, ContentDocumentLink> oldDocs)
	{
		System.debug(LoggingLevel.WARN, '---> start setFileNamesFromCDLUpload');
		List<TriggerOperation> triggerTypes = new List<TriggerOperation>{
				TriggerOperation.AFTER_INSERT
				, TriggerOperation.AFTER_UPDATE
		};
		if ( !SG_DisplayUtils.canFireTrigger( triggerEvent, triggerTypes, hasSetFileNames_CDL ) )
		{
			System.debug(LoggingLevel.WARN, '---> already hasSetFileNames_CDL: ' + hasSetFileNames_CDL + ' or wrong trigger type; skip');
			return;
		}

		String keyPrefix = Quality_Control__c.sObjectType.getDescribe().getKeyPrefix();
		Set<Id> qcIds = new Set<Id>();
		List<Quality_Control__c> qcList = new List<Quality_Control__c>();
		System.debug(LoggingLevel.WARN, '---> keyPrefix: ' + keyPrefix);

		if ( newDocs != null && newDocs.size() > 0 )
		{
			for ( ContentDocumentLink cdl : newDocs )
			{
				System.debug(LoggingLevel.WARN, '---> cdl: ' + cdl );
				String prefix = String.valueOf(cdl.LinkedEntityId).substring(0,3);
				if ( prefix == keyPrefix )
				{
					System.debug(LoggingLevel.WARN, '---> QC file!');
					qcIds.add( cdl.LinkedEntityId );
				}
			}

			System.debug(LoggingLevel.WARN, '---> found QC links: ' + qcIds );
			if ( qcIds != null && qcIds.size() > 0 )
			{
				qcList = getFullQcs( qcIds );
				System.debug(LoggingLevel.WARN, '---> passing qcs to the QC setFileName record...');
				setFileNames( triggerEvent, qcList, null );
			}
		}

	}

	// for Mobile flow - rename an uploaded file to a QC to reflect what it is (ex: garage photo, baseboard photo, etc)
	// uses a field set to control which hidden fields store the collection of images for each type of upload

	// heper method to do the renaming
	public static void setFileNames(System.TriggerOperation triggerEvent, List<Quality_Control__c> newQcs, Map<Id, Quality_Control__c> oldQcs)
	{
		System.debug(LoggingLevel.WARN, '---> start setFileNames');
		// set the enum of allowed trigger operations (before insert, after update, etc)
		List<TriggerOperation> triggerTypes = new List<TriggerOperation>{
				TriggerOperation.AFTER_INSERT
				, TriggerOperation.AFTER_UPDATE
		};
		if ( !SG_DisplayUtils.canFireTrigger( triggerEvent, triggerTypes, hasSetFileNames ) )
		{
			System.debug(LoggingLevel.WARN, '---> already hasSetFileNames: ' + hasSetFileNames + ' or wrong trigger type; skip');
			return;
		}

		// prevents recursive triggers
		hasSetFileNames = true;

		String keyPrefix = Quality_Control__c.sObjectType.getDescribe().getKeyPrefix();
		Map<Id, Set<Id>> entityToDocIdsMap = new Map<Id, Set<Id>>();
		List<ContentDocument> upsertDocs = new List<ContentDocument>();
		Set<Id> allDocIds = new Set<Id>();

		System.debug(LoggingLevel.WARN, '---> keyPrefix: ' + keyPrefix);

		if ( newQcs != null && newQcs.size() > 0 )
		{
			// get all the QC's related files...
			Map<Id, Quality_Control__c> qcMap = new Map<Id, Quality_Control__c>();
			Map<Id, Id> qcToHouseholdId = new Map<Id, Id>();
			for ( Quality_Control__c qc : newQcs )
			{
				qcMap.put( qc.Id, qc );
				qcToHouseholdId.put( qc.Id, qc.House_Unit__c );
				System.debug(LoggingLevel.WARN, '---> qc work order: ' + qc.Work_Order__c);
			}

			for ( ContentDocumentLink cdl : [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :qcMap.keySet()] )
			{
				System.debug(LoggingLevel.WARN, '---> cdl: ' + cdl );

				// let's just double check it's really tied to a QC...
				String type = String.valueOf( cdl.LinkedEntityId.getSobjectType() );

				if ( type == 'Quality_Control__c' )
				{
					System.debug(LoggingLevel.WARN, '---> QC file!');

					Set<Id> tmpSet = entityToDocIdsMap.get( cdl.LinkedEntityId );
					if ( tmpSet == null ) tmpSet = new Set<Id>();
					tmpSet.add( cdl.ContentDocumentId );
					entityToDocIdsMap.put( cdl.LinkedEntityId, tmpSet );

					allDocIds.add( cdl.ContentDocumentId );
				}
			}


			System.debug(LoggingLevel.WARN, '---> entityToDocIdsMap: ' + entityToDocIdsMap);
			// get the documents...
			if ( entityToDocIdsMap != null && entityToDocIdsMap.keySet().size() > 0 && allDocIds != null )
			{
				Map<Id, ContentDocument> docMap = new Map<Id, ContentDocument>([SELECT Id, Title FROM ContentDocument WHERE Id IN :allDocIds]);
				Map<Id, RecordType> rtMap = new Map<Id, RecordType>([SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Quality_Control__c']);
				System.debug(LoggingLevel.WARN, '---> found record types for QC: ' + rtMap );

				for ( Id entityId : entityToDocIdsMap.keySet() )
				{
					Quality_Control__c qc = qcMap.get( entityId );
					Set<Id> docIds = entityToDocIdsMap.get( entityId );
					System.debug(LoggingLevel.WARN, '---> looping docs for entity; entityId: ' + entityId + ' docIds: ' + docIds );
					if ( qc != null && docIds != null )
					{
						// TODO: get all RT Names...
					//	Integer ctr = 1;
						RecordType rt;
						String rtName = 'File';
						if ( qc.RecordTypeId != null )
						{
							rt = rtMap.get( qc.RecordTypeId );
							if ( rt != null ) rtName = rt.DeveloperName;
						}
						System.debug(LoggingLevel.WARN, '---> rt name: ' + rtName );

						// read a Field Set for all of our picture files and loop over that to rename everything...
						List<Schema.FieldSetMember> pictureFieldNames = SG_SchemaUtils.getFieldSetMembers( 'Picture_Upload_Fields', 'Quality_Control__c');
						if ( pictureFieldNames != null && pictureFieldNames.size() > 0 )
						{
							for ( Schema.FieldSetMember field : pictureFieldNames )
							{
								System.debug(LoggingLevel.WARN, '---> looping potential field of picture names: ' + field.getFieldPath() );
								String photoPrefix = field.getFieldPath() + '_';
								photoPrefix = photoPrefix.replace('__c', '' );
								Set<String> fieldStrs = getQcPicFileNames( qc, field.getFieldPath() );
								if ( fieldStrs != null && fieldStrs.size() > 0 )
								{
									for ( Id docId : docIds )
									{
										ContentDocument doc = docMap.get( docId );
										System.debug(LoggingLevel.WARN, '---> doc: ' + doc );
										//if ( fieldStrs.contains( doc.Title ))
										if ( fieldStrs.contains( doc.Title ))
										{
											System.debug(LoggingLevel.WARN, '---> found this file in the field!');

											String tmpTitle = doc.Title;
											String title = rtName + photoPrefix + '_' + tmpTitle;
											doc.Title = title.left(254);
											upsertDocs.add( doc );
//										ctr++;
										}
									}
								}


							}
						}
					}
				}
				System.debug(LoggingLevel.WARN, '---> upsertDocs: ' + upsertDocs );

				if ( upsertDocs != null && upsertDocs.size() > 0 )
				{
					try
					{
						upsert upsertDocs;
					}
					catch (Exception e )
					{
						System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );
					}
				}

			}
		}

	}

	// helper method to get the hidden picture name fields contained in a fieldset
	public static Set<String> getQcPicFileNames( Quality_Control__c qc, String fieldApiName)
	{
		Set<String> fieldStrs;
		System.debug(LoggingLevel.WARN, '---> getQcPicFileNames; fieldApiName: ' + fieldApiName );
		if ( String.isNotBlank( fieldApiName ) )
		{
			try
			{
				String fieldVal = (String)qc.get(fieldApiName);
				System.debug(LoggingLevel.WARN, '---> fieldVal: ' + fieldApiName );
				// so - depending on where the file gets uploaded (desktop, mobile, FSL) -- the document title sometimes strips out the file extension, sometimes not
				// so -- we need to store BOTH WITH the extension and WITHOUT the extension

				if ( String.isNotBlank( fieldVal ))
				{
					// with the extension...
					System.debug(LoggingLevel.WARN, '---> pic field: ' + fieldVal );
					fieldStrs = SG_DisplayUtils.parseIncomingStringIntoSet( fieldVal );
					System.debug(LoggingLevel.WARN, '---> fieldStrs: ' + fieldStrs );

					// without the extension...
					String strippedFieldVal = fieldVal;
					System.debug(LoggingLevel.WARN, '---> strippedFieldVal before parsing: ' + strippedFieldVal);
					// strip out some extensions
					strippedFieldVal = strippedFieldVal.replace( '.jpg', '' );
					strippedFieldVal = strippedFieldVal.replace( '.jpeg', '' );
					strippedFieldVal = strippedFieldVal.replace( '.png', '' );
					strippedFieldVal = strippedFieldVal.replace( '.txt', '' );
					strippedFieldVal = strippedFieldVal.replace( '.pdf', '' );
					strippedFieldVal = strippedFieldVal.replace( '.gif', '' );
					strippedFieldVal = strippedFieldVal.replace( '.mov', '' );
					strippedFieldVal = strippedFieldVal.replace( '.mp4', '' );
					strippedFieldVal = strippedFieldVal.replace( '.mov', '' );
					System.debug(LoggingLevel.WARN, '---> strippedFieldVal after parsing: ' + strippedFieldVal);
					if ( String.isNotBlank( strippedFieldVal ) )
					{
						Set<String> tmpSet = SG_DisplayUtils.parseIncomingStringIntoSet( strippedFieldVal );
						fieldStrs.addAll( tmpSet );
					}
					System.debug(LoggingLevel.WARN, '---> final fieldStrs: ' + fieldStrs );

				}
			}
			catch( Exception e )
			{
				System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );
			}

		}
		System.debug(LoggingLevel.WARN, '---> returning fields: ' + fieldStrs );
		return fieldStrs;

	}

	public static List<Quality_Control__c> getFullQcs( Set<Id> qcIds )
	{
		List<Quality_Control__c> qcList;

		Map<String, Schema.SObjectField> fieldMap =  getFieldMap('Quality_Control__c');
		Set<String> fieldNames = new Set<String>();
		fieldNames.addAll(fieldMap.keySet());
		String formattedIds = SG_DisplayUtils.getFormattedIdList( qcIds );
		List<SObject> tmpObjList = getFullSObject(fieldNames, 'Quality_Control__c',' WHERE Id IN (' + formattedIds + ')');
		if(tmpObjList != null && tmpObjList.size() == 1)
		{
			qcList = (List<Quality_Control__c>)tmpObjList;
		}

		return qcList;
	}

	/*
        * Example of useage -- Single

        if ( objUtils == null ) objUtils = new SG_ObjectUtils();
	   Map<String, Schema.SObjectField> fieldMap =  objUtils.getFieldMap(‘Quote’);
        Set<String> fieldNames = new Set<String>();
        fieldNames.add(‘Quote.OpportunityId’); // for relationship fields
        fieldNames.addAll(fieldMap.keySet());
        List<SObject> tmpObjList = objUtils.getFullSObject(fieldNames, 'Quote',' WHERE Id = \'' + currentQuoteId + '\'');
        if(tmpObjList != null && tmpObjList.size() == 1)
        {
            currentQuote = (Quote)tmpObjList[0];
        }
        else
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Failed to find quote.'));
        }

        * Example of usage -- List
	if ( objUtils == null ) objUtils = new SG_ObjectUtils();
        Map<String, Schema.SObjectField> fieldMap =  objUtils.getFieldMap('Time_Card__c');
        Set<String> fieldNames = new Set<String>();
        fieldNames.addAll(fieldMap.keySet());
        //List<SObject> tmpObjList = objUtils.getFullSObject(fieldNames, 'Time_Card__c',' WHERE Id = \'' + formattedIds + '\'');
        List<SObject> tmpObjList = objUtils.getFullSObject(fieldNames, 'Time_Card__c',' WHERE Id IN (' + formattedIds + ')'); // DisplayUtils took care of formatting Ids
        if(tmpObjList != null && tmpObjList.size() > 0)
        {
            timeCards = (List<Time_Card__c>)tmpObjList;
        }
        else
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, Label.noTimeCardsError ));
        }
*/
	public static List<SObject> getFullSObject(Set<String> fieldNames, String objectName, String whereClause)
	{
		if(fieldNames == null || fieldNames.size() < 1) return null;
		System.debug('---> incoming WHERE clause: ' + whereClause);

		String allFields;
		for(String fieldName : fieldNames)
		{
			if(allFields == null)
			{
				allFields = fieldName;
			}
			else
			{
				allFields = allFields + ',' + fieldName;
			}
		}
		System.debug('allFields = ' + allFields);

		String qry = 'SELECT ' + allFields + ' FROM ' + objectName;

		if(whereClause != null && whereClause.trim().length() > 0)
		{
			if(whereClause.contains('WHERE'))
			{
				if(whereClause.startsWith(' WHERE '))
				{
					qry = qry + whereClause;
				}
				else
				{
					qry = qry + ' ' +whereClause;
				}
			}
			else
			{
				//qry = qry + ' WHERE ' + whereClause;
				qry = qry + ' ' + whereClause;
			}
		}
		System.debug('The query = ' + qry);
		List<SObject> fullObjects = Database.query(qry);

		return fullObjects;
	}

	public static Map<String, Schema.SObjectField> getFieldMap( String objectName )
	{
		Map<String, Schema.SObjectField> fieldMap;
		if ( schemaMap == null ) schemaMap = Schema.getGlobalDescribe();
		if ( objectName != null && objectName.length() > 0 )
		{
			Schema.SObjectType schemaObjType = schemaMap.get( objectName );
			if ( schemaObjType != null )
			{
				fieldMap = schemaObjType.getDescribe().fields.getMap();
			}
		}

		return fieldMap;
	}
    
    public static void addCaseFilesToAsset(List<ContentDocumentLink> allCdls){
        String casePrefix = Case.sObjectType.sObjectType.getDescribe().getKeyPrefix();
        Map<Id, Set<Id>> entityToDocIdsMap = new Map<Id, Set<Id>>();
        Set<Id> allDocIds = new Set<Id>();
        List<ContentDocumentLink> insertCdls = new List<ContentDocumentLink>();
        for ( ContentDocumentLink cdl : allCdls ){
            String prefix = String.valueOf(cdl.LinkedEntityId).substring(0,3);
            if ( prefix == casePrefix ){
                Set<Id> tmpSet = entityToDocIdsMap.get( cdl.LinkedEntityId );
                if ( tmpSet == null ) tmpSet = new Set<Id>();
                	tmpSet.add( cdl.ContentDocumentId );
                entityToDocIdsMap.put( cdl.LinkedEntityId, tmpSet );
                allDocIds.add( cdl.ContentDocumentId );
            }
        }
        
        if ( entityToDocIdsMap != null && entityToDocIdsMap.keySet().size() > 0 && allDocIds != null )
        {
            // get all the documents and group by QC...
            
            Map<Id, Case> recMap = new Map<Id, Case>([SELECT Id, AssetId FROM Case WHERE Id IN :entityToDocIdsMap.keySet()]);
            for ( Id entityId : entityToDocIdsMap.keySet() )
            {
                Case rec = recMap.get( entityId );
                Set<Id> docIds = entityToDocIdsMap.get( entityId );
                if ( rec != null && rec.AssetId != null && docIds != null )
                {
                    for ( Id docId : docIds )
                    {
                       
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.contentdocumentid = docId;
                        cdl.LinkedEntityId = rec.AssetId;
                        cdl.ShareType= 'I';
                        
                        insertCdls.add( cdl );
                        
                    }
               
                    if ( insertCdls != null && insertCdls.size() > 0 )
                    {
                        try
                        {
                            insert insertCdls;
                        }
                        catch (Exception e )
                        {
                            System.debug(LoggingLevel.WARN, '---> message, stacktrace: ' + e.getMessage() + ' ' + e.getStackTraceString() );
                        }
                    }
                }
            }
            
        }
        
    }

}