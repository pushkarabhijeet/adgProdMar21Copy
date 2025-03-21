global class ADG_BatchJobPathValidate implements Database.Batchable<sObject>, Database.AllowsCallouts {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String q = 'SELECT Asset.Id FROM Asset WHERE Id IN (SELECT AssetId FROM WorkOrder WHERE (Start_Day__c >= LAST_N_DAYS: 7 OR Job_End_Day__c >= LAST_N_DAYS: 7))';
        return Database.getQueryLocator(q);
    }

    global void execute(Database.BatchableContext BC, List<Asset> assets) {
        Map<ID, Asset> nm = new Map<ID, Asset>(assets);
        Map<ID, Asset> om = new Map<ID, Asset>();
        System.debug('ADG Running batch job path validation...');
        ADG_JobPathUtils.linkJobPaths(System.TriggerOperation.AFTER_INSERT, nm, om);
    }

    global void finish(Database.BatchableContext BC) {}
}