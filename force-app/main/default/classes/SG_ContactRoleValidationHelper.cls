/**********************************************************************
* Name:   	SG_ContactRoleValidationHelper
* Author: 	Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date: 	28-Aug-2018
* ======================================================
* ======================================================
* Purpose: The purpose of this class is to                                                            
* 
* ======================================================
* ======================================================
* History:                                                            
* VERSION	DATE            INITIALS	DESCRIPTION/FEATURES ADDED
* 1.0     	28-Aug-2018     CS			Initial Development
* 1.01      29-Aug-2018     FMF         Convert to use metadata instead of custom settings
*   
***********************************************************************/


/* To Use this code create or update existing Opportunity Trigger with this code

    System.debug( 'OpportunityTrigger:RoleValidationHelper' );

	if( Trigger.isAfter && Trigger.isUpdate )
	{
		System.debug( 'Calling SG_ContactRoleValidationHelper' );
		SG_ContactRoleValidationHelper.validateOpportunityContactRolesHelper( Trigger.newMap );
	}


 */

public without sharing class SG_ContactRoleValidationHelper
{

    public static List<Contact_Role_Validation_Setting__mdt> roleValidationSettings {
        get {
            if( roleValidationSettings == null ) {
                roleValidationSettings =
                            [ SELECT ID, Comparison__c, Field_Value_to_Check__c, Field_To_Check__c
                                    , Role_Object__c, Role__c, Error_Message__c, Count__c
                            FROM Contact_Role_Validation_Setting__mdt ];
            }
            return roleValidationSettings;
        }
        set;
    }

    public static List<Contact_Role_Validation_Setting__mdt> getCustomSettings( Opportunity oppty, String roleObject )
    {
        List<Contact_Role_Validation_Setting__mdt> applicableValidationSettings =
                new List<Contact_Role_Validation_Setting__mdt>();

        for( Contact_Role_Validation_Setting__mdt rvs : roleValidationSettings )
        {
            try
            {
                String fieldValue = ( String ) oppty.get( rvs.Field_To_Check__c );
                if( rvs.Role_Object__c.equalsIgnoreCase( roleObject )
                            && fieldValue != null
                            && fieldValue.equalsIgnoreCase( rvs.Field_Value_To_Check__c ) )
                {
                    applicableValidationSettings.add( rvs );
                }
            }
            catch( Exception exp )
            {
                // The main exception will be if the field doesn't exist or null values
                System.debug( exp );
            }
        }

        System.debug( '@@@ getCustomSettings : applicableValidationSettings ' + applicableValidationSettings );
        return applicableValidationSettings;
    }

    public static Boolean validateOpportunityContactRolesHelper( Map<Id, Opportunity> opptyMap )
    {
        Boolean atLeastOneValidationError = false;

        System.debug( 'validateOpportunityContactRolesHelper BEGIN' );

        Map<Id,Map<String,Double>> opptyIdToRoleToCount = new Map<Id,Map<String,Double>>();

        // NOTE:  it is not possible to add an OpportunityContactRole with null Role
        //        AND Role <> NULL
        List<AggregateResult> resultList =
                [ SELECT OpportunityId, Role, count( Id ) RowCount
                FROM OpportunityContactRole
                WHERE OpportunityId IN :opptyMap.keySet()
                GROUP BY OpportunityId, Role ];

        // organize the counts in a map of counts per role indexed by oppty id
        if( resultList != null && resultList.size() > 0 )
        {
            for( AggregateResult ar : resultList )
            {
                System.debug( 'looking at aggregate: ' + ar );

                Id opptyId = ( Id ) ar.get( 'OpportunityId' );
                String role = ( String ) ar.get( 'Role' );
                Double rowCount = ( Double ) ar.get( 'RowCount' );

                System.debug( 'OpptyId = ' + opptyId );
                System.debug( 'Role = ' + role );
                System.debug( 'RowCount = ' + rowCount );

                Map<String,Double> roleToCount = opptyIdToRoleToCount.get( opptyId );

                if( roleToCount == null )
                {
                    roleToCount = new Map<String,Double>();
                }

                roleToCount.put( role, rowCount );

                // save count for all roles
                Double allCount = roleToCount.get( 'ANY' );
                if( allCount == null ) {
                    allCount = 0;
                }
                allCount = allCount + rowCount;
                roleToCount.put( 'ANY', allCount );

                opptyIdToRoleToCount.put( opptyId, roleToCount );
            }
        }

        system.debug( 'opptyIdToRoleToCount (before primary) = ' + opptyIdToRoleToCount );

        List<OpportunityContactRole> contactRoles =
        [ SELECT OpportunityId, IsPrimary
        FROM OpportunityContactRole
        WHERE OpportunityId IN :opptyMap.keySet()
        ];

        if(contactRoles != null && contactRoles.size() > 0)
        {
            for( OpportunityContactRole contactRole : contactRoles )
            {
                System.debug( 'looking at contactRole: ' + contactRole );

                if(contactRole.IsPrimary)
                {
                    Id opptyId = contactRole.OpportunityId;
                    String role = 'IsPrimary';
                    Double rowCount = 1;

                    System.debug('OpptyId = ' + opptyId);
                    System.debug('Role = ' + role);
                    System.debug('RowCount = ' + rowCount);

                    Map<String, Double> roleToCount = opptyIdToRoleToCount.get(opptyId);

                    if (roleToCount == null)
                    {
                        roleToCount = new Map<String, Double>();
                    }

                    roleToCount.put(role, rowCount);

                    opptyIdToRoleToCount.put(opptyId, roleToCount);
                }
            }
        }

        system.debug( 'opptyIdToRoleToCount (with primary) = ' + opptyIdToRoleToCount );

        for( Opportunity o : opptyMap.values() )
        {
            System.debug( 'o = ' + o );

            Map<String,Double> roleToCount = new Map<String,Double>();

            if( opptyIdToRoleToCount.containsKey( o.Id ) )
            {
                roleToCount = opptyIdToRoleToCount.get( o.Id );
            }

            List<Contact_Role_Validation_Setting__mdt> applicableValidationSettings =
                            getCustomSettings( o, 'OpportunityContactRole' );
            System.debug( 'applicableValidationSettings = ' + applicableValidationSettings );

            for( Contact_Role_Validation_Setting__mdt customSetting : applicableValidationSettings )
            {
                System.debug( 'customSetting = ' + customSetting ); //Project Manager = 1
                if( customSetting.Role__c == null ) {
                    continue;
                }

                Double rowCount = 0;
                if( roleToCount.containsKey( customSetting.Role__c ) )
                {
                    rowCount = roleToCount.get( customSetting.Role__c );
                }
                System.debug( 'rowCount = ' + rowCount );
                System.debug( 'customSetting.Count__c = ' + customSetting.Count__c );

                Boolean validationError = false;

                // NOTE:  better test coverage this way
                Map<String, Boolean> comparisonMap = new Map<String, Boolean> {
                        'equals' => ( rowCount == customSetting.Count__c )
                        , 'not equals' => ( rowCount != customSetting.Count__c )
                        , 'less than' => ( rowCount < customSetting.Count__c )
                        , 'greater than' => ( rowCount > customSetting.Count__c )
                        , 'less than or equals' => ( rowCount <= customSetting.Count__c )
                        , 'greater than or equals' => ( rowCount >= customSetting.Count__c )
                };

                validationError = comparisonMap.get( customSetting.Comparison__c );
                System.debug( 'validationError for ' + customSetting.Comparison__c + ' = ' + validationError );

                if( validationError == true )
                {
                    atLeastOneValidationError = true;
                    o.addError( customSetting.Error_Message__c );
                    System.debug( 'added error = ' + customSetting.Error_Message__c );
                }
            }
        }

        return atLeastOneValidationError;
    }

}