public class ADG_ManageQC {
    @AuraEnabled
    public static String submitBatch(Date qcCreatedDate, String strEntity, String strFieldName, String strFieldLabel, String strButtonClk){
        List<Community__c> commList = [SELECT Id FROM Community__c where Entity__c =: strEntity WITH SECURITY_ENFORCED];
        if (commList.size()> 0){
            List<Community__c> commUpdList = new List<Community__c>();
            for (Community__c c: commList){
                if (strButtonClk == 'disable'){
                    //fl.put(fieldName,12.0);
                    c.put(strFieldName, 'No');  
                } else if (strButtonClk == 'enable'){
                    c.put(strFieldName, 'Yes');
                }
                commUpdList.add(c);
            }
            //system.debug('@commList' + Json.serialize(commList));
            //system.debug('@commUpdList' + Json.serialize(commUpdList)); 
            update commUpdList;
            
            if (strButtonClk == 'disable' && qcCreatedDate != null){ //Delete QCs
                List<Quality_Control__c> qcList = [SELECT Id FROM Quality_Control__c WHERE Status__c != 'Completed' 
                                                   AND QCType__c =: strFieldLabel
                                                   AND House_Unit__r.Community__r.Entity__c =: strEntity
                                                   AND CreatedDate <= :qcCreatedDate
                                                   WITH SECURITY_ENFORCED];
                //system.debug('ListOfQCs' + Json.serialize(qcList)); 
                if (qcList.size() > 0){
                    delete qcList;
                }
            }
        }
        return ('SUCCESS');
    } 
}