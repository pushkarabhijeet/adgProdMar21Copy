public class ADG_DocumentRefreshResult {

    @AuraEnabled
    public String entityPath { get; set; }
    @AuraEnabled
    public String jobPath { get; set; }
    @AuraEnabled
    public Boolean isAssetUpdated { get; set; }
    @AuraEnabled
    public Boolean hasError { get; set; }

    public static ADG_DocumentRefreshResult getFailed() {
        ADG_DocumentRefreshResult val = new ADG_DocumentRefreshResult();
        val.hasError = true;
        return val;
    }
}