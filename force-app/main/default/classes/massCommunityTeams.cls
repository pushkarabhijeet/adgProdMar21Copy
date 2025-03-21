public without sharing class massCommunityTeams {
    
    private static Map<string,Community__c> communityWithBuilderMap = new Map<string,Community__c>();
    private static Map<string,Id> serviceResourceMap = new Map<string,Id>();
    private static Set<string> communitySet = new Set<string>();
    private static Set<string> builderSet = new Set<string>();
    private static Set<string> FSMSet = new Set<string>();
    private static List<Community__c> commUpdList = new List <Community__c>(); 
    private static List<Community_Team__c> commTeamList = new List<Community_Team__c>();
    
    @AuraEnabled
    public static void uploadCommunityMembers(String inputCasesJSON){
        List<csvRecs> recsList = (List<csvRecs>) System.JSON.deserialize(inputCasesJSON, List<csvRecs>.class);
        List<csvRecs> recsToProcessList = new List<csvRecs>();
        for (csvRecs rec : recsList){
            if (String.isNotEmpty(rec.BuilderName) && String.isNotEmpty(rec.CommunityName) && 
                (String.isNotEmpty(rec.CommunityOwnerEmail) ||
                 (String.isNotEmpty(rec.CommunityTeamMemberEmail) && String.isNotEmpty(rec.JobType)))){
                     String strBuilderName = rec.BuilderName.replaceAll('"', '');
                     String strCommunityName = rec.CommunityName.replaceAll('"', '');
                     rec.BuilderName = strBuilderName;
                     rec.CommunityName = strCommunityName;
                     recsToProcessList.add(rec); //Cleaned List
                     communitySet.add(strCommunityName);
                     builderSet.add(strBuilderName);
                     if (String.isNotEmpty(rec.CommunityOwnerEmail)){
                         FSMSet.add(rec.CommunityOwnerEmail); 
                     }
                     if (String.isNotEmpty(rec.CommunityTeamMemberEmail)){
                         FSMSet.add(rec.CommunityTeamMemberEmail); 
                     }
                 }
        }
        if (!recsToProcessList.isEmpty()){
            String commIdString;
            String commBuilder;
            Id FSMId; //System.assert(!String.isEmpty(whitespace));
            system.debug('@@@ Before Map Builder' + JSON.serialize(builderSet));
            system.debug('@@@ Before Map FSM' + JSON.serialize(FSMSet));
            communityMap();
            FSMMap();
            system.debug('@@@ After Map Builder ' + JSON.serialize(communityWithBuilderMap));
            system.debug('@@@ After Map FSM ' + JSON.serialize(serviceResourceMap));
            if (!(communityWithBuilderMap.isEmpty() && serviceResourceMap.isEmpty())){
                for (csvRecs rec : recsToProcessList){
                    commBuilder = null;
                    FSMId = null;
                    commBuilder = rec.BuilderName.toLowerCase() + '-' + rec.CommunityName.toLowerCase();
                    Community__c commRec = communityWithBuilderMap.get(commBuilder);
                    if (commRec != null){
                        if (commRec.Id != null){
                            if (rec.CommunityOwnerEmail != null){
                                if (String.IsEmpty(commIdString)){
                                    FSMId = serviceResourceMap.get(rec.CommunityOwnerEmail.toLowerCase());                            
                                }
                                else {
                                    if (!(commIdString.contains(commRec.Id))){
                                        FSMId = serviceResourceMap.get(rec.CommunityOwnerEmail.toLowerCase());
                                    }
                                }
                            }
                            if (rec.CommunityOwnerEmail != commRec.Field_Service_Manager__r.RelatedRecord.Email && FSMId != null){
                                commRec.Field_Service_Manager__c = FSMId;
                                if (commIdString == null){
                                    commIdString = commRec.Id;
                                } else {
                                    commIdString += ',' + commRec.Id;   
                                }
                                commUpdList.add(commRec);
                            }
                            if (String.isNotEmpty(rec.CommunityTeamMemberEmail) && String.isNotEmpty(rec.JobType)){
                                FSMId = serviceResourceMap.get(rec.CommunityTeamMemberEmail.toLowerCase());
                                if (FSMId != null){
                                    Community_Team__c ctm = new Community_Team__c(Community__c = commRec.Id, FSM__c = FSMId, Job_Type__c = rec.JobType);
                                    commTeamList.add(ctm);
                                }
                            }
                        }
                    }
                }
            }
            system.debug('@@@ commUpdList  ' + JSON.serialize(commUpdList));
            system.debug('@@@ commTeamList ' + JSON.serialize(commTeamList));
            if (commUpdList.size() > 0){
                Database.SaveResult[] saveResultList = Database.update(commUpdList, false);
            }
            if (commTeamList.size() > 0){
                Database.SaveResult[] saveResultList1 = Database.insert(commTeamList, false);
            }
        }
    }
    
    private static void  communityMap(){
        for (Community__c c : [SELECT Id, Builder__r.Name, Name, Field_Service_Manager__r.RelatedRecord.Email, Field_Service_Manager__c 
                               FROM Community__c where  Name IN: communitySet  AND Builder__r.Name IN: builderSet]){
                                   communityWithBuilderMap.put(c.Builder__r.Name.toLowerCase() + '-' + c.Name.toLowerCase(), c); 
                               }
    }
    
    private static void FSMMap(){
        for (ServiceResource s: [SELECT Id,RelatedRecord.Email  from ServiceResource where RelatedRecord.Email IN: FSMSet]){
            serviceResourceMap.put(s.RelatedRecord.Email.toLowerCase(), s.Id);
        }
    }
    
    public class csvRecs {
        public String BuilderName;
        public String CommunityName;
        public String CommunityOwnerEmail;
        public String CommunityTeamMemberEmail;
        public String JobType;
    }
    
}