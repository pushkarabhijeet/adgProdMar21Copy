public class ADG_JobPathTarget {
  public String sf_asset_id { get; set; }
  public String entity { get; set; }
  public String market { get; set; }
  public String builder_short { get; set; }
  public String builder_long { get; set; }
  public String community { get; set; }
  public String identifier { get; set; }
  public String address { get; set; }

  public ADG_JobPathTarget() {
  }

  public ADG_JobPathTarget(Asset asset) {
    sf_asset_id = asset.Id;
    entity = asset.Account.Integration_Key_Account__c;
    market = asset.Community__r.Location__c;
    builder_short = asset.Account.Account_Short_Name__c;
    builder_long = asset.Account.Name;
    community = asset.Community__r.Name;
    identifier = asset.Name;
    address = asset.Street__c;
  }

  public Boolean isValid() {
    return !(String.isBlank(sf_asset_id) ||
    String.isBlank(entity) ||
    String.isBlank(market) ||
    String.isBlank(community) ||
    String.isBlank(address) ||
    String.isBlank(identifier));
  }
}