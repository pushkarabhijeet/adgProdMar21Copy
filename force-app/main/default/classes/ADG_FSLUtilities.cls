/***********************************************************************************
 * Name:     	ADG_FSLUtilities
 * Author:   	Pushkar
 * ======================================================
 * History:
 * VER   DATE          INITIALS      DESCRIPTION/FEATURES ADDED
 * 1.0   May 18 2021   pushkar       Initial Development for FSL utilities
 *
 ***********************************************************************************/

public class ADG_FSLUtilities {
    //This method renames fetches all ContentDocumentId and passes the info to SG_ContentDocumentHelper.doCustomQcFileName
   @InvocableMethod(label='Rename Files')
    public static void renameFiles(List<FlowInputs> req){
        //String parRecId = req[0].recId;
        //String prefix = req[0].prefix;
        String srchFileNames = '';
        String[] files1 = req[0].fileNames.split(',');
        for (String t :files1){
            if (srchFileNames.length()>0)
            	srchFileNames+=', ';
            String[] t1 = t.split('\\.');
            srchFileNames+= '\'' + t1[0] + '\'' ;
            //System.debug('@@@ LoopFileNames@@@' + srchFileNames);
        }
        for (String t :files1){
            if (srchFileNames.length()>0)
            	srchFileNames+=', ';
            srchFileNames+= '\'' + t + '\'' ;
            //System.debug('@@@ LoopFileNames@@@' + srchFileNames);
        }
        //System.debug('@@@ FinalFileNames@@@' + srchFileNames);
        String queryString = 'SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = ' +'\''+ req[0].recId + '\''+ ' AND ContentDocument.Title IN ' + '(' + srchFileNames + ')';
        //System.debug('@@@ query@@@' + queryString);
        List<ContentDocumentLink> MyQuery = DataBase.query(queryString); 
        String recIds ='';
        //Set<Id> recIds = new Set<Id>();
        for (ContentDocumentLink temp : MyQuery) {
            if (recIds.length()>0)
                recIds+=',';
            recIds+= temp.ContentDocumentId;
            //recIds.add(temp.ContentDocumentId);
        }
        //System.debug('@@@ recIds@@@' + recIds);
        if (recIds.length()>0){
            Boolean invokeRenameFiles = SG_ContentDocumentHelper.doCustomQcFileName(recIds, req[0].prefix+'_');
        }	
    }
    
    public class FlowInputs{
        @InvocableVariable public String recId;
        @InvocableVariable public String prefix;
        @InvocableVariable public String fileNames;
    }
}