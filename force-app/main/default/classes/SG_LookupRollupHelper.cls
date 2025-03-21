/**********************************************************************
* Name:   	SG_LookupRollupHelper
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
* 1.0     	21 OCT 2010     RD			Initial Development
* 2.0		?? ??? 2012		CS			Updated code to have less code in the trigger
* 3.0       ?? JUL 2013		RD			added another constructor that takes a third parameter (parentRelationshipValue)
*										This will allow multiple, separate lookups on the same object.
*										When the parent relationship is specified in the trigger, the lookup code will look for that specific config and roll it up
*										Useful for when having a child roll up to itself, in addition to rolling up to another object
* 4.0       12 Sep 2018     RD          Added Queueable and a new config to determine if trigger should be asynchronous or synchronous
*
***********************************************************************/

/*
		/////////// standard trigger invocation -- using synchronous call OR using rollup helper UI to configure queueable/additional clause ///////////////
		trigger Sample_Child_Trigger on Contact (after delete, after insert, after undelete, after update)
		{
			//Pass in the name of the child record, for example 'Contact' and the name of the parent record, for example 'Account';
			SG_LookupRollupHelper lh = new SG_LookupRollupHelper( 'Contact', 'Account');

			// take care of assigning the correct lists based on the trigger type (Insert vs Update vs Delete vs Undelete)
    		lh.setTriggerLists(Trigger.isUpdate, Trigger.isDelete, Trigger.new, Trigger.old);

			// do the rollup
    		lh.doRollupSummary();
		}

*/



public without sharing class SG_LookupRollupHelper implements Queueable
{
    public List<SObject> childObjectList;
    public List<SObject> oldChildObjectList;


    public String parentName;
    public String childName;

    public String parentRelationshipKey;
    public String parentRelationshipValue;
    public Double RowCount = 0;
    public RollupConfigs__c config;
    public String additionalClause {get; set;} // by default the helper gets all children of parent; use this to add SOQL "AND" clauses to filter results

    public Boolean doDateQuery {get; set;}
   // public String dateQueryType {get; set;} // MAX, MIN, etc
    public Boolean isDateTime {get; set;} // if true, query for DateTime; if False (or blank) query for a Date
    public String mappingToUse {get; set;} // override to use a specific mapping, not just the Object's default value; useful when doing special logic for some but not all fields

    public Boolean doMathQuery {get; set;}
   // public String mathQueryType {get; set;} // AVG, SUM, MAX, etc

    public String dateMathQueryType {get; set;} // SUM, MAX, AVG (for numeric), etc

    private Set<String> fieldNames;
    private Map<String, RollupConfigs__c> configMap;
    private Map<String, String> childFieldMap;
    private Map<String, String> parentFieldMap;
    private Set<String> queryFields;
    private Map<String, String> childToParentMap;

    private final String QUERY_FIELD_PREFIX = 'queryfield';
    private final String PARENT_QUERY_FIELD_PREFIX = 'parentqueryfield';
    private final Integer MAX_LENGTH_ALIAS = 22; //Actual max is 25, however leave 3 characters for numbers

    public static Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

    public SG_LookupRollupHelper( String childName, String parentName)
    {
        this.childName = childName;
        this.parentName = parentName;
        this.parentRelationshipKey = 'queryfield_parentrelationshipname__c';

      //  initConfiguration();
    }

    public void execute(QueueableContext qc)
    {
        System.debug(LoggingLevel.WARN, '---> start LU executable');
        //initConfiguration();
        rollupSummary(childObjectList, oldChildObjectList);


    }

    public void initConfiguration() {
        // get all the fields from the config
        System.debug(LoggingLevel.WARN, '---> start LU initConfiguration');


        this.fieldNames = getFieldsFromRollupConfigs();
        System.debug('fieldNames = ' + fieldNames);
        System.debug(LoggingLevel.WARN, '---> fieldNames: ' + fieldNames);

        System.debug(LoggingLevel.WARN, '---> do date query: ' + doDateQuery);
        System.debug(LoggingLevel.WARN, '---> is dateTime: ' + isDateTime);
        System.debug(LoggingLevel.WARN, '---> do math query: ' + doMathQuery);


        // special rollups
        if ( doDateQuery == null ) doDateQuery = false;
        if ( isDateTime == null ) isDateTime = false;
        if ( doMathQuery == null ) doMathQuery = false;

        // get the config we are interested in
        //this.configMap = RollupConfigs__c.getAll();
        //System.debug(LoggingLevel.WARN, '---> configMap: ' + configMap );
        //config = getCurrentConfig( configMap, this.parentName, childName );
        System.debug(LoggingLevel.WARN, '---> current config: ' + config );

        System.debug(LoggingLevel.WARN, '---> additionalClause: ' + additionalClause );

        // build a map of query fields/values
        this.childFieldMap = getSpecifiedFieldMap( config, fieldNames, QUERY_FIELD_PREFIX );
        System.debug('sumChildren:childFieldMap: ' + childFieldMap);
        // build a map of parent fields/values
        this.parentFieldMap = getSpecifiedFieldMap( config, fieldNames, PARENT_QUERY_FIELD_PREFIX );

        // build a set of the fields we're interested in to query
        this.queryFields = new Set<String>();
        queryFields.addAll( childFieldMap.values() );
        System.debug('sumChildren:queryFields: ' + queryFields);

        // build the map of child/parent fields
        this.childToParentMap = getChildParentMap(childFieldMap, parentFieldMap);


        /*this.fieldNames = getFieldsFromRollupConfigs();
        System.debug('fieldNames = ' + fieldNames);
        System.debug(LoggingLevel.WARN, '---> fieldNames: ' + fieldNames);

        System.debug(LoggingLevel.WARN, '---> do date query: ' + doDateQuery);
        System.debug(LoggingLevel.WARN, '---> is dateTime: ' + isDateTime);
        System.debug(LoggingLevel.WARN, '---> do math query: ' + doMathQuery);


        // special rollups
        if ( doDateQuery == null ) doDateQuery = false;
        if ( isDateTime == null ) isDateTime = false;
        if ( doMathQuery == null ) doMathQuery = false;

        // get the config we are interested in
        this.configMap = RollupConfigs__c.getAll();
        System.debug(LoggingLevel.WARN, '---> configMap: ' + configMap );
        config = getCurrentConfig( configMap, this.parentName, childName );
        System.debug(LoggingLevel.WARN, '---> current config: ' + config );

        System.debug(LoggingLevel.WARN, '---> additionalClause: ' + additionalClause );

        // build a map of query fields/values
        this.childFieldMap = getSpecifiedFieldMap( config, fieldNames, QUERY_FIELD_PREFIX );
        System.debug('sumChildren:childFieldMap: ' + childFieldMap);
        // build a map of parent fields/values
        this.parentFieldMap = getSpecifiedFieldMap( config, fieldNames, PARENT_QUERY_FIELD_PREFIX );

        // build a set of the fields we're interested in to query
        this.queryFields = new Set<String>();
        queryFields.addAll( childFieldMap.values() );
        System.debug('sumChildren:queryFields: ' + queryFields);

        // build the map of child/parent fields
        this.childToParentMap = getChildParentMap(childFieldMap, parentFieldMap);*/


    }


    private void updateParentIdToChildAndParentIdSet(Id parentId, sObject child, Set<Id> parentIds, Map<Id,List<sObject>> parentIdToChild) {
        //This will be used for error handling
        if( !parentIdToChild.containsKey(parentId) ) {
            List<sObject> tmpList = new List<sObject>();
            tmpList.add(child);
            parentIdToChild.put(parentId,tmpList);
        } else {
            parentIdToChild.get(parentId).add(child);
        }

        if(parentId != null) {
            parentIds.add(parentId);
        }
    }

    public void doRollupSummary()
    {
        System.debug(LoggingLevel.WARN, '---> start doRollupSummary');
        System.debug(LoggingLevel.WARN, '---> childObjectList: ' + childObjectList);
        System.debug(LoggingLevel.WARN, '---> oldChildObjectList: ' + oldChildObjectList);

        //initConfiguration();

        configMap = RollupConfigs__c.getAll();
        System.debug(LoggingLevel.WARN, '---> configMap: ' + configMap );

        List<RollupConfigs__c> triggerConfigs = getConfigsForTrigger();
        if ( triggerConfigs != null && triggerConfigs.size() > 0 )
        {
            for ( RollupConfigs__c tmpConfig : triggerConfigs )
            {
                System.debug(LoggingLevel.WARN, '---> looping config: ' + tmpConfig );

                config = tmpConfig;

                initConfiguration();

                Boolean isActive = false;
                Boolean doAsynch = false;
                additionalClause = null;

                // reset the agg boxes
                doDateQuery = false;
                isDateTime = false;
                doMathQuery = false;

                // set up for the config
                if ( config.Active__c )
                {
                    isActive = true;
                }

                if ( config.Use_Queueable__c )
                {
                    doAsynch = true;
                }

                if ( config.Do_Date_Query__c )
                {
                    doDateQuery = true;
                }

                if ( config.Do_Date_Time_Query__c )
                {
                    doDateQuery = true;
                    isDateTime = true;
                }

                if ( config.Do_Math_Query__c )
                {
                    doMathQuery = true;
                }

                System.debug(LoggingLevel.WARN, '---> testing date_math_query_type__c: ' + config.Date_Math_Query_Type__c);
                if ( String.isNotBlank(config.Date_Math_Query_Type__c ) )
                {
                    dateMathQueryType = config.Date_Math_Query_Type__c;
                }

                if ( String.isNotBlank( config.Additional_Filter_Clause__c ) )
                {
                    additionalClause = ' ' + config.Additional_Filter_Clause__c + ' ';
                }

                mappingToUse = config.Name;

                System.debug(LoggingLevel.WARN, '---> config queueable: ' + config.Use_Queueable__c );

                // now execute the config
                if ( !isActive )
                {
                    System.debug(LoggingLevel.WARN, '---> this rollup configuration is not active. Skip!');
                }
                else
                {
                    if ( doAsynch )
                    {
                        System.debug(LoggingLevel.WARN, '---> performing asynch rollup: ' + config.Name );
                        ID jobID = System.enqueueJob(this);
                    }
                    else
                    {
                        System.debug(LoggingLevel.WARN, '---> doing real-time lookup');
                        rollupSummary(childObjectList,oldChildObjectList);
                    }
                }
            }
        }
    }

    public void rollupSummary(List<SObject> childObjectList, List<SObject> oldChildObjectList) {

        System.debug(LoggingLevel.WARN, '---> start LU rollupSummary');
        System.debug(LoggingLevel.WARN, '---> do math query (in rollup method): ' + doMathQuery);
        System.debug(LoggingLevel.WARN, '---> do date query (in rollup method): ' + doDateQuery);
        System.debug(LoggingLevel.WARN, '---> named mapping (in rollup method): ' + mappingToUse);
        System.debug(LoggingLevel.WARN, '---> incoming child list: ' + childObjectList);
        System.debug(LoggingLevel.WARN, '---> incoming oldChildObjectList list: ' + oldChildObjectList);

        System.debug('--------------> Starting rollupSummary');

        System.debug(LoggingLevel.WARN, '---> (RU Helper) Queries performed: ' + Limits.getQueries() );
        System.debug(LoggingLevel.WARN, '---> (RU Helper) Queries allowed: ' + Limits.getLimitQueries() );
        System.debug(LoggingLevel.WARN, '---> (RU Helper) Queries usage percentage: ' + (Decimal.valueOf(Limits.getQueries() ) / Decimal.valueOf(Limits.getLimitQueries() )) * 100 );

        System.debug(LoggingLevel.WARN, '---> childObjectList: ' + childObjectList);
        if(childObjectList != null && childObjectList.size() > 0 && parentRelationshipValue != null && parentRelationshipValue.length() > 0) {
            Set<Id> parentIds = new Set<Id>();

            //This will be used for error handling
            Map<Id,List<sObject>> parentIdToChild = new Map<Id,List<sObject>>();

            Integer i = 0;
            for ( sObject child : childObjectList )
            {
                Id parentId = (Id)child.get(parentRelationshipValue);

                //If we have an old child list then compare parent Ids...
                if(oldChildObjectList != null && i < oldChildObjectList.size()) {
                    Id oldParentId = (Id)(oldChildObjectList[i].get(parentRelationshipValue));
                    if(oldParentId != parentId) {
                        updateParentIdToChildAndParentIdSet(oldParentId, child, parentIds, parentIdToChild);
                    }
                }

                //Also do this for the new child
                updateParentIdToChildAndParentIdSet(parentId, child, parentIds, parentIdToChild);
                i++;
            }

			/*
				Here's where you actually invoke the lookup code...
			*/
            // assign the rollups to the parent...
            System.debug(LoggingLevel.WARN, '---> parentIds: ' + parentIds );
            if ( parentIds != null && parentIds.size() > 0 )
            {
                System.debug('updating parents to reflect new totals...');

			    /*
			    	Use the "additionalClause" property to add filter clauses if you don't want to rollup all children
			    */
                String query = 'SELECT Id FROM ' + this.parentName + ' WHERE ID IN (' + getFormattedIdList(parentIds) + ') FOR UPDATE';
                List<SObject> parentObjectList = Database.query(query);
                System.debug('parentObjectList = ' + parentObjectList);

                sumChildren(parentObjectList);

				/*
			    	Update the parent to reflect the new rollup counts
			    */
                System.debug('saving parents!');
                System.debug(LoggingLevel.WARN, '---> saving parents in LU');
                Database.Saveresult[] results = Database.update(parentObjectList, false);
                //We don't want to fail every child, only those that have a matching parent that failed
                for(Database.Saveresult result : results) {
                    System.debug('result : ' + result);
                    if(!result.isSuccess())
                    {
                        String allErrorsForOneRecord = '';
                        for(Database.Error err : result.getErrors())
                        {
                            System.debug(LoggingLevel.WARN, '---> adding error: ' + err.getMessage() );
                            allErrorsForOneRecord += err.getMessage();
                        }
                        System.debug('result is: ' + result);
                        System.debug('result.id is: ' + result.getId() );

                        List<sObject> children = parentIdToChild.get(result.getId());
                        if(children != null) {
                            for(SObject child : children) {
                                child.addError('Rollup Summary Error: ' + allErrorsForOneRecord);
                            }
                        } else {
                            System.debug('UNKNOWN ERROR!');
                        }
                    }
                }
            } //end if
        }
    }

    public void sumChildren( List<sObject> parentList)
    {
        if ( parentList != null && parentList.size() > 0 )
        {
            // get the Ids
            Set<Id> parentIds = getIdsFromObjects(parentList);

            // query for the children
            List<sObject> resultList = queryForChildren( parentIds, childFieldMap, this.parentName, childName, childToParentMap, queryFields, parentRelationshipValue );

            // assign rollups to parents
            assignRollupResults( resultList, parentList);
        }
    }

    public Map<String, String> getSpecifiedFieldMap( RollupConfigs__c config, Set<String> fieldNames, String fieldType )
    {
        System.debug( 'Start getSpecifiedFieldMap');
        Map<String, String> fieldMap = new Map<String, String>();
        System.debug( 'getting fieldMap for type (' + fieldType + '); config, fieldNames: ' + config + ', ' + fieldNames );
        if ( config != null && fieldNames != null && fieldType != null)
        {
            for ( String key : fieldNames )
            {
                System.debug('specified field map: examining field: ' + key);
                // only work with query fields we're interested in...
                if ( key.toLowerCase().startsWith( fieldType ))
                {
                    System.debug('adding queryField: ' + key );
                    String val = (String)config.get( key );
                    System.debug('adding key/val pair: ' + key + ', ' + val );
                    if ( val != null && key.toLowerCase() != parentRelationshipKey.toLowerCase())
                    {
                        System.debug( 'adding val to fieldmap: ' + val);
                        fieldMap.put( key, val );
                    }
                    else if ( key.toLowerCase() == parentRelationshipKey.toLowerCase())
                    {
                        System.debug( 'adding parent relationship to fieldmap: ' + val);
                        parentRelationshipValue = val;
                    }
                }
            }
        }
        System.debug('returning fieldMap for '+ fieldType +': ' + fieldMap );
        return fieldMap;
    }

    public Map<String, String> getChildParentMap( Map<String, String> childFieldMap, Map<String, String> parentFieldMap )
    {
        System.debug( 'getting child/parent map for child: ' + childFieldMap );
        System.debug( 'getting child/parent map for parent: ' + parentFieldMap );
        Map<String, String> childToParentMap = new Map<String, String>();

        // first lets process the parent map to make it easier to match after we process the child field names below...
        Map<String, String> tmpParentMap = new Map<String, String>();
        for ( String p : parentFieldMap.keyset() )
        {
            String parentValue = parentFieldMap.get( p );
            // first, strip off "__c" and work with the word stem
            System.debug('--------------> parsing parent field ' + p + ' value is: ' + parentValue );
            List<String> splitted = p.split('__c');
            String theFieldName = splitted[0];
            System.debug('--------------> parent field split: ' + theFieldName );
            // strip off the parentfield prefix...
            String fieldNumber = theFieldName.substring(PARENT_QUERY_FIELD_PREFIX.length());
            System.debug('--------------> parent field number: ' + fieldNumber );

            String queryField = childFieldMap.get(QUERY_FIELD_PREFIX + fieldNumber + '__c');
            if ( queryField != null )
            {
                childToParentMap.put(queryField, parentFieldMap.get( p ) );
            }
        }

        System.debug('returning childToParentMap: ' + childToParentMap);
        return childToParentMap;
    }

    public List<sObject> queryForChildren( Set<ID> parentIds, Map<String, String> childFieldMap, String parentName,
            String childName, Map<String, String> childToParentMap, Set<String> queryFields, String parentRelationshipValue )
    {
        System.debug(LoggingLevel.WARN, '---> start queryForChildren');
        System.debug(LoggingLevel.WARN, '---> parentIds: ' + parentIds );
        System.debug(LoggingLevel.WARN, '---> childFieldMap: ' + childFieldMap );
        System.debug(LoggingLevel.WARN, '---> parentName: ' + parentName );
        System.debug(LoggingLevel.WARN, '---> childName: ' + childName );
        System.debug(LoggingLevel.WARN, '---> queryFields: ' + queryFields );

        if ( parentIds != null && childFieldMap != null && queryFields != null && childName != null && parentName != null )
        {
            String ids = getFormattedIdList( parentIds );
            System.debug('should be querying for queryFields: ' + queryFields);
            List<SObject> resultList = getSumsOfFullSObject(queryFields, childName, parentName, childToParentMap, parentRelationshipValue, 'WHERE ' + parentRelationshipValue + ' IN (' + ids + ')');
            System.debug ('resultList: ' + resultList );
            return resultList;
        }
        else
        {
            return null;
        }
    }

    public List<SObject> getSumsOfFullSObject(Set<String> queryFields, String objectName, String parentField,
            Map<String, String> childToParentMap, String parentRelationshipValue, String whereClause)
    {
        System.debug('getSumsOfFullSObject:queryFields: ' + queryFields);
        System.debug('getSumsOfFullSObject:childToParentMap: ' + childToParentMap);

        List<SObject> fullObjects;

        try
        {
            String allFields;

            // build up the query fields
            if(queryFields != null) {
                Integer counter = 0;
                for(String fieldName : queryFields)
                {
                    // create a field alias for assigning the values
                    String parentName = '';
                    if ( childToParentMap != null )
                    {
                        parentName = childToParentMap.get( fieldName );
                    }

                    System.debug('getSumsOfFullSObject:parentName: ' + parentName);
                    System.debug('getSumsOfFullSObject:counter: ' + counter);
                    System.debug('getSumsOfFullSObject:queryFields.size(): ' + queryFields.size());

                    if ( fieldName != null )
                    {
                        Integer trimUntil = MAX_LENGTH_ALIAS;
                        trimUntil = Math.min(MAX_LENGTH_ALIAS, parentName.length());
                        //todo: consolidate date/math queries

                        System.debug(LoggingLevel.WARN, '---> doDateQuery: ' + doDateQuery);
                        System.debug(LoggingLevel.WARN, '---> dateMath query type: ' + dateMathQueryType);
                        if(allFields == null)
                        {
                            if ( doDateQuery && dateMathQueryType != null )
                            {
                                allFields = dateMathQueryType + '(' + fieldName + ') ' + parentName.substring(0,trimUntil) + counter;
                            }
                            else if( doMathQuery && dateMathQueryType != null)
                            {
                                allFields = dateMathQueryType + '(' + fieldName + ') ' + parentName.substring(0,trimUntil) + counter;
                            }
                            else
                            {
                                allFields = 'sum(' + fieldName + ') ' + parentName.substring(0,trimUntil) + counter;
                            }
                        }
                        else
                        {
                            if ( doDateQuery && dateMathQueryType != null)
                            {
                                allFields = allFields + ', ' + dateMathQueryType + '(' + fieldName + ') ' + parentName.substring(0,trimUntil) + counter;
                            }
                            else if( doMathQuery && dateMathQueryType != null)
                            {
                                allFields = allFields + ', ' + dateMathQueryType + '(' + fieldName + ') ' + parentName.substring(0,trimUntil) + counter;
                            }
                            else
                            {
                                allFields = allFields + ', ' + 'sum(' + fieldName + ') ' + parentName.substring(0,trimUntil) + counter;
                            }
                        }
                    }
                    counter++;
                }
            }

            System.debug('getSumsOfFullSObject:allFields: ' + allFields);

            if(allFields == null || allFields.length() == 0) {
                allFields = 'count(Id) RowCount';
            } else {
                // count the number of child objects
                allFields = allFields + ', ' + 'count(Id) RowCount';
            }

            System.debug('getSumsOfFullSObject:parentField: ' + parentField);

            // add the parent field relationship to the select list
            if ( parentField != null )
            {
                allFields = allFields + ',' + parentRelationshipValue;
            }

            System.debug('getSumsOfFullSObject:allFields: ' + allFields);

            String qry = 'SELECT ' + allFields + ' FROM ' + objectName;

            System.debug('getSumsOfFullSObject:whereClause: ' + whereClause);

            if(whereClause != null)
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
                    qry = qry + ' WHERE ' + whereClause;
                }
                if (additionalClause != null )
                {
                    qry = qry + ' ' + additionalClause;
                }
            }

            // add the group by clause
            if ( parentField != null )
            {
                qry = qry + ' GROUP BY ' + parentRelationshipValue;
            }
            System.debug(LoggingLevel.WARN, '---> the query for rollup: ' + qry );
            System.debug('The query = ' + qry);
            fullObjects = Database.query(qry);
        }
        catch ( Exception e )
        {
            system.debug('caught exception getting aggregate query: ' + e.getMessage() );
        }
        return fullObjects;
    }

    public void assignRollupResults( List<sObject> resultList, List<sObject> parentList)
    {
        System.debug('starting assignRollupResults. resultList is: ' + resultList );
        System.debug(LoggingLevel.WARN, '---> starting assignRollupResults. resultList is: ' + resultList );
        // initialize the parentlist to null in case rollups do not apply...
        Map<Id,sObject> parentObjectMap = new Map<Id, sObject>();
        if ( parentList != null && parentList.size() > 0 )
        {
            for ( sObject parent : parentList )
            {
                parentObjectMap.put( parent.Id, parent );
            }
        }

        // parse out the aggregate results...
        List<AggregateResult> rollups = new List<AggregateResult>();
        if ( resultList != null && resultList.size() > 0 )
        {
            rollups = (List<AggregateResult>)resultList;
            for ( AggregateResult ar : rollups )
            {
                System.debug( 'looking at rollup: ' + ar );
                System.debug( 'trying to get parent by parentRelationshipValue: ' + parentRelationshipValue);
                Id parentId = (Id)ar.get( parentRelationshipValue );
                SObject parentObject = parentObjectMap.get(parentId);
                RowCount = (Double)ar.get('RowCount');
                // put the total count into the config; might not be a field on the parent object to hold, so put it into config if needed
                System.debug('rowCount is: ' + rowCount );
                if ( config != null && config.parentRowCount__c != null)
                {
                    try {
                        parentObject.put(config.parentRowCount__c, RowCount );
                    } catch (Exception exp) {
                        if(exp.getMessage().contains('Illegal assignment from Double to Integer')) {
                            parentObject.put(config.parentRowCount__c, RowCount.intValue() );
                        }
                    }
                }

                if ( childToParentMap != null )
                {
                    try
                    {
                        Integer counter = 0;
                        for ( String s : childToParentMap.keySet() )
                        {
                            System.debug( 'getting value for field: ' + s );
                            String parentField = childToParentMap.get( s );

                            Integer trimUntil = MAX_LENGTH_ALIAS;
                            trimUntil = Math.min(MAX_LENGTH_ALIAS, parentField.length());

                            String parentFieldALIAS = parentField.subString(0,trimUntil) + counter;

                            System.debug( '-->filling parent field: ' + parentField );
                            System.debug( '-->parentField value: ' + ar.get( parentFieldALIAS ));

                            // date specific fields
                            if ( doDateQuery )
                            {
                                if ( isDateTime )
                                {
                                    DateTime parentFieldValue = (DateTime)ar.get( parentFieldALIAS );
                                    if ( parentFieldValue == null ) parentFieldValue = null;
                                    parentObject.put( parentField, parentFieldValue );
                                }
                                else
                                {
                                    Date parentFieldValue = (Date)ar.get( parentFieldALIAS );
                                    if ( parentFieldValue == null ) parentFieldValue = null;
                                    parentObject.put( parentField, parentFieldValue );
                                }
                            }
                            else
                            {
                                Double parentFieldValue = (Double)ar.get( parentFieldALIAS );
                                if ( parentFieldValue == null ) parentFieldValue = 0;
                                parentObject.put( parentField, parentFieldValue );
                            }

                            counter++;
                        }
                    }
                    catch (Exception e)
                    {
                        System.debug('caught exception: ' + e.getMessage() );
                    }
                }
            }
        }
        else
        {
            System.debug('no result list found -- zero-out the values');
            try
            {
                System.debug('parentList: ' + parentList );
                System.debug('parentObjectMap: ' + parentObjectMap );
                if ( parentList != null && parentList.size() > 0 )
                {
                    for ( SObject parent : parentList )
                    {
                        SObject parentObject = parentObjectMap.get(parent.Id);
                        for ( String s : childToParentMap.keySet() )
                        {
                            System.debug( 'getting value to zero-out field: ' + s );
                            String parentField = childToParentMap.get( s );
                            System.debug( '-->filling parent field: ' + parentField );

                            // date-specific
                            if ( doDateQuery )
                            {
                                System.debug(LoggingLevel.WARN, '---> in date specific update');
                                if ( isDateTime )
                                {
                                    System.debug(LoggingLevel.WARN, '---> in date/time specific update');
                                    DateTime parentFieldValue = null;
                                    parentObject.put( parentField, parentFieldValue );
                                }
                                else
                                {
                                    Date parentFieldValue = null;
                                    parentObject.put( parentField, parentFieldValue );
                                }
                            }
                            else
                            {
                                Double parentFieldValue = 0;
                                parentObject.put( parentField, parentFieldValue );
                            }

                        }
                        // zero-out the count, if it exists
                        if ( config != null && config.parentRowCount__c != null)
                        {
                            Double tmpParentRowCount = 0;
                            try {
                                parentObject.put(config.parentRowCount__c, tmpParentRowCount );
                            } catch(Exception exp) {
                                if(exp.getMessage().contains('Illegal assignment from Double to Integer')) {
                                    parentObject.put(config.parentRowCount__c, tmpParentRowCount.intValue());
                                }
                            } //catch
                        }
                    } // for
                }
            }
            catch (Exception e)
            {
                System.debug('caught exception: ' + e.getMessage() );
            }
        }


    }

/*
    simple helper methods...
*/
    public Set<Id> getIdsFromObjects( List<sObject> objList )
    {

        Set<Id> ids = new Set<Id>();
        if ( objList != null && objList.size() > 0 )
        {
            for ( sObject obj : objList )
            {
                ids.add( obj.Id );
            }
        }
        return ids;
    }

    public Set<String> getFieldsFromRollupConfigs( )
    {
        System.debug('starting getFieldsFromObject');
        Set<String> fieldNames = new Set<String>();

        Map<String, Schema.SObjectField> tmpFieldMap = Schema.SObjectType.RollupConfigs__c.fields.getMap();
        if ( tmpFieldMap != null ) fieldNames.addAll(tmpFieldMap.keySet());
        System.debug('fieldNames: ' + fieldNames);
        return fieldNames;
    }

    public List<RollupConfigs__c> getConfigsForTrigger()
    {
        System.debug(LoggingLevel.WARN, '---> start getConfigsForTrigger');
        System.debug(LoggingLevel.WARN, '---> getting current config; configMap: ' + configMap );
        System.debug(LoggingLevel.WARN, '---> getting current config; parentName: ' + parentName );
        System.debug(LoggingLevel.WARN, '---> getting current config; childName: ' + childName );

        List<RollupConfigs__c> configs = new List<RollupConfigs__c>();

        if ( configMap != null && configMap.values().size() > 0 )
        {
            // see if we are specifying a mapping to use
            System.debug(LoggingLevel.WARN, '---> mappingToUse: ' + mappingToUse);
            if ( mappingToUse != null && mappingToUse.trim().length() > 0)
            {
                RollupConfigs__c config = configMap.get( mappingToUse );
                System.debug(LoggingLevel.WARN, '---> returning named mapping: '+ config );
                configs.add( config );
            }
            else
            {
                for ( RollupConfigs__c config : configMap.values() )
                {
                    System.debug( '--> Parsing for object ' + config.name );
                    if ( config.Parent_Object__c != null && config.Parent_Object__c == parentName && config.Child_Object_Name__c != null && config.Child_Object_Name__c == childName )
                    {
                        configs.add( config );

                    }
                }
            }
        }
        return configs;
    }


    // todo: remove this? replace with getConfigsForTrigger? This really only designed for a single mapping per object
    public RollupConfigs__c getCurrentConfig( Map<String, RollupConfigs__c> configMap, String parentName, String childName )
    {
        System.debug(LoggingLevel.WARN, '---> getting current config; configMap: ' + configMap );
        if ( configMap != null && configMap.values().size() > 0 )
        {
            // see if we are specifying a mapping to use
            System.debug(LoggingLevel.WARN, '---> mappingToUse: ' + mappingToUse);
            if ( mappingToUse != null && mappingToUse.trim().length() > 0)
            {
                RollupConfigs__c config = configMap.get( mappingToUse );
                System.debug(LoggingLevel.WARN, '---> returning named mapping: '+ config );
                return config;
            }
            else
            {
                for ( RollupConfigs__c config : configMap.values() )
                {
                    System.debug( '--> Parsing for object ' + config.name );
                    if ( config.Parent_Object__c != null && config.Parent_Object__c == parentName && config.Child_Object_Name__c != null && config.Child_Object_Name__c == childName )
                    {
                        return config;
                    }
                }
            }
        }
        return null;
    }

    public void setTriggerLists( Boolean isUpdate, Boolean isDelete, List<sObject> triggerNew, List<sObject> triggerOld)
    {
        System.debug(LoggingLevel.WARN, '---> start setTriggerLists');
        // set the child object list - current values of the records
        if( isDelete )
        {
            childObjectList = triggerOld;
        }
        else
        {
            childObjectList = triggerNew;
        }

        // set the "old" child object list used only for updates
        if ( isUpdate )
        {
            oldChildObjectList = triggerOld;
        }
        else
        {
            oldChildObjectList = null;
        }

        System.debug(LoggingLevel.WARN, '---> childObjectList: ' + childObjectList);
        System.debug(LoggingLevel.WARN, '---> oldChildObjectList: ' + oldChildObjectList);


    }

    public String getFormattedIdList( Set<Id> incomingIds )
    {
        String formattedStr = null;
        if ( incomingIds != null )
        {
            formattedStr = '';
            String sep = '';
            for ( Id id : incomingIds )
            {
                formattedStr = formattedStr + sep + '\'' + id + '\'';
                sep = ', ';
            }
        }
        return formattedStr;
    }
}