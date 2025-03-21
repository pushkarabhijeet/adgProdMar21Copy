/***********************************************************************************
 * Name:     	ADG_FileUploader
 * Author:   	
 * Test Class:	ADG_FileUploader_Test
 * ======================================================
 * History:
 * VER   DATE          INITIALS      DESCRIPTION/FEATURES ADDED
 * 1.0   Dec-29-2020   		         Initial Development upload QC Pictures.
 *
 ***********************************************************************************/
public with sharing class FileUploaderClass {
    
    @AuraEnabled
    public static String uploadFile(String base64, String filename, String recordId) {
        ContentVersion cv = createContentVersion(base64, filename);
        ContentDocumentLink cdl = createContentLink(cv.Id, recordId);
        if (cv == null || cdl == null) { return null; }
        return cdl.Id;
    }
    
    private static ContentVersion createContentVersion(String base64, String filename) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        try {
            insert cv;
            return cv;
        } catch(Exception e) {
            SG_ErrorHelper.notifyOnError( 'FileUploaderClass', 'FileUploaderClass - DB to SF', 'FileUploaderClass - createContentVersion', e.getMessage() );
            return null;
        }
    }
    
    private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
        if (contentVersionId == null || recordId == null) { return null; }
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id =: contentVersionId
        ].ContentDocumentId;
        cdl.LinkedEntityId = recordId;
        // ShareType is either 'V', 'C', or 'I'
        // V = Viewer, C = Collaborator, I = Inferred
        cdl.ShareType = 'I';
        try {
            insert cdl;
            return cdl;
        } catch(Exception e) {
            //System.debug(e);
            SG_ErrorHelper.notifyOnError( 'FileUploaderClass', 'FileUploaderClass - DB to SF', 'FileUploaderClass - ContentDocumentLink', e.getMessage() );
            return null;
        }
    }
    
}