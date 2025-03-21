public class OpportunityTriggerHandler {
    
    public static void validateStagesBeforeUpdate(Map<Id, Opportunity> oldOppsMap, Map<Id, Opportunity> newOppsMap) {
        
        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Construction Opportunity')?.getRecordTypeId();
        List<Opportunity> stageUpdatedOpps = new List<Opportunity>();
        
        for (Id key : newOppsMap.keySet()) {
            Opportunity oldOpp = oldOppsMap.get(key);
            Opportunity newOpp = newOppsMap.get(key);
            
            if (newOpp.StageName != oldOpp.StageName && newOpp.RecordTypeId == recordTypeId) {
                stageUpdatedOpps.add(newOpp);
            }
        }
        
        if (stageUpdatedOpps.size() > 0) {
            Map<String, Schema.SObjectField> fieldDescribeMap = Opportunity.sObjectType.getDescribe().fields.getMap();
            List<Opportunity_Staging__mdt> picklistMTD = [SELECT Label, Order__c, Mandatory_Fields__c, Related_Date_Field__c 
                                                          FROM Opportunity_Staging__mdt];
            
            Map<String, Opportunity_Staging__mdt> stagesOrderMap = new Map<String, Opportunity_Staging__mdt>();
            Map<String, Opportunity_Staging__mdt> validationStagesMap = new Map<String, Opportunity_Staging__mdt>();
            
            for (Opportunity_Staging__mdt pmtd: picklistMTD) {
                stagesOrderMap.put(pmtd.Label, pmtd);
                if(!pmtd.Label.contains('Close') && !pmtd.Label.contains('ITB')) {
                    validationStagesMap.put(pmtd.Label, pmtd);
                }
            }
            
            for (Opportunity opp : stageUpdatedOpps) {
                String previousStage = oldOppsMap.get(opp.Id).stageName;
                String currentStage = newOppsMap.get(opp.Id).stageName;
                Opportunity_Staging__mdt previouspmtd = stagesOrderMap.get(previousStage);
                Opportunity_Staging__mdt currentpmtd = stagesOrderMap.get(currentStage);
                Decimal previousOrder = previouspmtd.Order__c;
                Decimal currentOrder = currentpmtd.Order__c;
                String mandatoryFields = currentpmtd.Mandatory_Fields__c;
                String errorMsg = '';
                if(!String.isBlank(mandatoryFields)) {
                    for(String mf : mandatoryFields.split(','))                     {
                        if(opp.get(mf) == null) {
                            errorMsg = '[' + fieldDescribeMap.get(mf).getDescribe().getLabel() + '] Should be populated before moving the opportunity to ' + currentStage;
                        }
                    }
                }
                if(previousOrder != null && currentOrder != null && previousOrder > currentOrder) {
                    errorMsg = 'New Construction Type Opportunities, Can Not Be Updated To A Previous Stage';
                }
                if(String.isBlank(errorMsg)) {
                    if(!String.isBlank(currentpmtd.Related_Date_Field__c)) {
                    	opp.put(currentpmtd.Related_Date_Field__c, Date.today());
                    }
                } else {
                    opp.addError(errorMsg);
                }
            }
        }
    }
}