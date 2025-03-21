public with sharing class AdgFmsUtils {

    static Boolean changeRequiresUpdate(Asset oldAsset, Asset newAsset) {
        return (oldAsset == null ||
                oldAsset.Community__c != newAsset.Community__c ||
                oldAsset.AccountId != newAsset.AccountId ||
                oldAsset.Name != newAsset.Name);
    }

    public static void handleJobPaths(System.TriggerOperation triggerEvent, Map<Id, Asset> newAssets, Map<Id, Asset> oldAssets) {
        if (triggerEvent != TriggerOperation.AFTER_INSERT && triggerEvent != TriggerOperation.AFTER_UPDATE) {
            return;
        }

        try {
            Set<Id> ids = newAssets.keySet();
    
            List<Asset> assets = [SELECT Id, Name, Account.Account_Short_Name__c, Account.Integration_Key_Account__c, Community__r.Name, Community__r.Location__c FROM Asset WHERE Id in :ids];
            List<ADG_JobPathTarget> targets = new List<ADG_JobPathTarget>();
            for (Asset asset : assets) {

                ADG_JobPathTarget target = new ADG_JobPathTarget(asset);
                if (!target.isValid()) {
                    continue;
                }

                Asset oldAsset = oldAssets != null ? oldAssets.get(asset.Id) : null;
                Asset newAsset = newAssets.get(asset.Id);
                if (changeRequiresUpdate(oldAsset, newAsset)){
                    targets.add(target);
                }

            }
            if (!targets.isEmpty()) {
                AdgFmsUtils.createJobPaths(JSON.serialize(targets));
            }
        } catch(Exception e) {
            System.debug('Failed to execute adgHandleJobPaths(): ' + e);
        }
    }

    @future (callout=true)
    public static void createJobPaths(String targetsJSON) {

        ADG_SfapiConfig__c cfg = ADG_SfapiConfig__c.getInstance();
        if (cfg == null || cfg.baseUrl__c == null || cfg.apiKey__c == null) {
            return;
        }

        String host = cfg.baseUrl__c.removeEnd('/');
        String endpoint = '/job-paths';

        HttpRequest request = new HttpRequest();
        request.setEndpoint(host + endpoint);
        request.setMethod('POST');
        request.setHeader('X-API-KEY', cfg.apiKey__c);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setBody(targetsJSON);
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            System.debug('ADG RESPONSE ' + response.getBody());
            List<ADG_JobPathResult> results = (List<ADG_JobPathResult>) JSON.deserialize(response.getBody(), List<ADG_JobPathResult>.class);
            System.debug('ADG BODY ' + results);
            updateAssetFields(results);
        }
    }

    static void updateAssetFields(List<ADG_JobPathResult> results) {
        List<Asset> toBeUpdated = new List<Asset>();
        for (ADG_JobPathResult result : results) {

            // TODO: should we clear the fields for any failed houses?
            if (!result.success) continue;

            toBeUpdated.add(new Asset(
                Id = result.sf_asset_id,
                ADG_JobPath__c = result.job_path,
                ADG_EntityPath__c = result.entity_path
            ));
        }
        System.debug('ADG UPDATES ' + toBeUpdated);
        update toBeUpdated;
    }
}