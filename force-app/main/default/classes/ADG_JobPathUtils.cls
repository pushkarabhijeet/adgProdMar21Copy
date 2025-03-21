public with sharing class ADG_JobPathUtils {
  static Boolean changeRequiresUpdate(Asset oldAsset, Asset newAsset) {
    return (oldAsset == null ||
    oldAsset.Community__c != newAsset.Community__c ||
    oldAsset.AccountId != newAsset.AccountId ||
    oldAsset.Name != newAsset.Name ||
    oldAsset.Street__c != newAsset.Street__c);
  }

  public static void createJobPaths(
    System.TriggerOperation triggerEvent,
    Map<Id, Asset> newAssets,
    Map<Id, Asset> oldAssets
  ) {
    handleJobPaths(triggerEvent, newAssets, oldAssets, '/paths/create');
  }

  public static void linkJobPaths(
    System.TriggerOperation triggerEvent,
    Map<Id, Asset> newAssets,
    Map<Id, Asset> oldAssets
  ) {
    handleJobPaths(triggerEvent, newAssets, oldAssets, '/paths/link');
  }

  private static void handleJobPaths(
    System.TriggerOperation triggerEvent,
    Map<Id, Asset> newAssets,
    Map<Id, Asset> oldAssets,
    String endpoint
  ) {
    if (
      triggerEvent != TriggerOperation.AFTER_INSERT &&
      triggerEvent != TriggerOperation.AFTER_UPDATE
    ) {
      return;
    }

    try {
      Set<Id> ids = newAssets.keySet();

      List<Asset> assets = [
        SELECT
          Id,
          Name,
          Street__c,
          Account.Name,
          Account.Account_Short_Name__c,
          Account.Integration_Key_Account__c,
          Community__r.Name,
          Community__r.Location__c
        FROM Asset
        WHERE Id IN :ids
      ];
      List<ADG_JobPathTarget> targets = new List<ADG_JobPathTarget>();
      for (Asset asset : assets) {
        ADG_JobPathTarget target = new ADG_JobPathTarget(asset);
        if (!target.isValid()) {
          continue;
        }

        Asset oldAsset = oldAssets != null ? oldAssets.get(asset.Id) : null;
        Asset newAsset = newAssets.get(asset.Id);
        if (changeRequiresUpdate(oldAsset, newAsset)) {
          targets.add(target);
        }
      }
      if (!targets.isEmpty()) {
        dispatchJobPathsRequest(JSON.serialize(targets), endpoint);
      }
    } catch (Exception e) {
      System.debug('Failed to execute ADG_JobPathUtils.handleJobPaths(): ' + e);
    }
  }

  public static void dispatchJobPathsRequest(
    String targetsJSON,
    String endpoint
  ) {
    if (System.isFuture() || System.isBatch()) {
      dispatchJobPathsRequestSync(targetsJSON, endpoint);
    } else {
      dispatchJobPathsRequestAsync(targetsJSON, endpoint);
    }
  }

  @future(callout=true)
  public static void dispatchJobPathsRequestAsync(
    String targetsJSON,
    String endpoint
  ) {
    dispatchJobPathsRequestSync(targetsJSON, endpoint);
  }

  public static void dispatchJobPathsRequestSync(
    String targetsJSON,
    String endpoint
  ) {
    ADG_SfapiConfig__c cfg = ADG_SfapiConfig__c.getInstance();
    if (cfg == null || cfg.baseUrl__c == null || cfg.apiKey__c == null) {
      return;
    }

    String host = cfg.baseUrl__c.removeEnd('/');

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
      List<ADG_JobPathResult> results = (List<ADG_JobPathResult>) JSON.deserialize(
        response.getBody(),
        List<ADG_JobPathResult>.class
      );
      System.debug('ADG BODY ' + results);
      updateAssetFields(results);
    }
  }

  static void updateAssetFields(List<ADG_JobPathResult> results) {
    List<Asset> toBeUpdated = new List<Asset>();
    for (ADG_JobPathResult result : results) {
      Asset asset;
      if (result.success) {
        asset = new Asset(
          Id = result.sf_asset_id,
          ADG_JobPath__c = result.job_path,
          ADG_EntityPath__c = result.entity_path
        );
      } else {
        asset = new Asset(
          Id = result.sf_asset_id,
          ADG_JobPath__c = null,
          ADG_EntityPath__c = null
        );
      }
      toBeUpdated.add(asset);
    }
    update toBeUpdated;
  }

  @AuraEnabled
  public static ADG_DocumentRefreshResult refreshDocumentsLink(String assetId) {
    Asset targetAsset = [
      SELECT
        Id,
        Name,
        Street__c,
        Account.Name,
        Account.Account_Short_Name__c,
        Account.Integration_Key_Account__c,
        Community__r.Name,
        Community__r.Location__c,
        ADG_JobPath__c,
        ADG_EntityPath__c
      FROM Asset
      WHERE Id = :assetId
    ];

    if (targetAsset == null) return ADG_DocumentRefreshResult.getFailed();

    ADG_JobPathTarget target = new ADG_JobPathTarget(targetAsset);

    String endpoint = 'callout:ADG_SFAPI/path/link';
    HttpRequest request = new HttpRequest();
    request.setEndpoint(endpoint);
    request.setHeader('X-Api-Key', '{!$Credential.Password}');
    request.setHeader('Accept', 'application/json');
    request.setHeader('Content-Type', 'application/json');
    request.setMethod('POST');
    request.setBody(JSON.serialize(target));

    Http http = new Http();
    HttpResponse response = http.send(request);

    if (response.getStatusCode() == 200) {
      ADG_JobPathResult pathResult = (ADG_JobPathResult)JSON.deserialize(
        response.getBody(),
        ADG_JobPathResult.class
      );
      ADG_DocumentRefreshResult refreshResult = new ADG_DocumentRefreshResult();
      refreshResult.entityPath = pathResult.entity_path;
      refreshResult.jobPath = pathResult.job_path;
      if (pathResult.job_path != targetAsset.ADG_JobPath__c
          || pathResult.entity_path != targetAsset.ADG_EntityPath__c) {
        updateAssetFields(new List<ADG_JobPathResult> { pathResult });
        refreshResult.isAssetUpdated = true;
      }
      return refreshResult;
    }
    return ADG_DocumentRefreshResult.getFailed();
  }
}