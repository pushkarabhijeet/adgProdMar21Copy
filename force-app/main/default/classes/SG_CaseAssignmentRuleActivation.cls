/***************************************************
* Name:         SG_CaseAssignmentRuleActivation
* Author:       Strategic Growth, Inc. (www.strategicgrowthinc.com)
* Date:         21 May 2020
* ==================================================
* ==================================================
* Purpose:      ...
*
* ==================================================
* ==================================================
* History:
* VERSION   DATE            INITIALS    DESCRIPTION/FEATURES ADDED
* 1.0       21 May 2020     FMF     Initial Development
* 
****************************************************/

public without sharing class SG_CaseAssignmentRuleActivation {

    @InvocableMethod( label = 'Apply Assignment Rules'
            description = 'Updates case record in order to run default assignment rules.' )
    public static void applyAssignmentRules( List<Id> caseID ) 
    {
        System.debug('BEGIN: applyAssignmentRules from LIST');
        System.debug('applyAssignmentRules caseID = ' + caseID);
        Set<ID> caseIDSet = new Set<ID>();		
        
        caseIDSet.add( caseID[ 0 ] );
        
        applyAssignmentRules( caseIDSet );
        System.debug('END: applyAssignmentRules');
    }
    
	@future
    public static void applyAssignmentRules_ATFUTURE(Set<Id> caseIdSet)
    {
        applyAssignmentRules(caseIdSet);
    }
    
    public static void applyAssignmentRules( Set<Id> caseIDSet ) {
        System.debug('BEGIN: applyAssignmentRules from SET');
		System.debug('applyAssignmentRules caseIDSet = ' + caseIDSet);        
        // set flag to run assignment rules
        Database.DMLOptions dmo = new Database.DMLOptions();
        
        List<AssignmentRule> theRuleToUse = [SELECT Id, Name FROM AssignmentRule WHERE SobjectType = 'Case' and Active = TRUE LIMIT 1];
        
        //dmo.assignmentRuleHeader.useDefaultRule = true;
        if(theRuleToUse == null || theRuleToUse.size() == 0)
        {
            System.debug('ABORTING: applyAssignmentRules because no active assignment rules found.');
            return;
        }
        
        System.debug('applyAssignmentRules theRuleToUse[0] = ' + theRuleToUse[0]);
		dmo.assignmentRuleHeader.assignmentRuleId = theRuleToUse[0].Id;
            
        // prepare update of cases
        List<Case> caseList = new List<Case>();
        for( ID caseID : caseIDSet ) 
        {
            Case aCase = new Case( ID = caseID );
            aCase.setOptions( dmo );
            caseList.add( aCase );
        }

        System.debug('applyAssignmentRules caseList = ' + caseList);
        System.debug('applyAssignmentRules before update with DMO');
        SG_CaseHelper.hasDoneCaseRollups = true;
        Database.update(caseList,dmo);        
        System.debug('applyAssignmentRules after update with DMO');
        System.debug('END: applyAssignmentRules from SET');
    }

}