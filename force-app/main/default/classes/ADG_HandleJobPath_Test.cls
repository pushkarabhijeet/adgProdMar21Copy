@isTest
private class ADG_HandleJobPath_Test {
  @TestSetup
  static void setup() {
    ADG_TestSetup.Setup();
  }

  public static Asset getHouse() {
    List<Asset> house = [
      SELECT Id, ADG_JobPath__c
      FROM Asset
      WHERE Name = 'identifier'
    ];
    System.assertEquals(house.size(), 1, 'Expected to find one house.');
    return house[0];
  }
  
  @isTest
  static void testCreateNewAsset() {
    Test.startTest();

    Asset house = getHouse();

    ADG_JobPathCalloutMockup hcm = new ADG_JobPathCalloutMockup();
    Test.setMock(HttpCalloutMock.class, hcm);
    hcm.setJobPathsBody(house.Id);

    System.assertEquals(
      house.ADG_JobPath__c,
      'NEW JOB PATH',
      'Expected Job Path to be defined by trigger.'
    );
    Test.stopTest();
  }

  @isTest
  static void testRefreshDocumentLinkAdd() {
    Test.startTest();

    Asset house = getHouse();

    ADG_JobPathCalloutMockup hcm = new ADG_JobPathCalloutMockup();
    hcm.setSingleJobPathBody(house.Id, true);
    Test.setMock(HttpCalloutMock.class, hcm);
    ADG_JobPathUtils.refreshDocumentsLink(house.Id);

    house = getHouse();

    System.assertEquals(
      'NEW JOB PATH',
      house.ADG_JobPath__c,
      'Expected Job Path to be defined'
    );
    Test.stopTest();
  }

  @isTest
  static void testRefreshDocumentLinkRemove() {
    Test.startTest();

    Asset house = getHouse();

    ADG_JobPathCalloutMockup hcm = new ADG_JobPathCalloutMockup();
    hcm.setSingleJobPathBody(house.Id, false);
    Test.setMock(HttpCalloutMock.class, hcm);
    ADG_JobPathUtils.refreshDocumentsLink(house.Id);

    house = getHouse();

    System.assertEquals(
      null,
      house.ADG_JobPath__c,
      'Expected Job Path to be null.'
    );
    Test.stopTest();
  }

  @isTest
  static void testDocmentRefreshResultError() {
    ADG_DocumentRefreshResult res = ADG_DocumentRefreshResult.getFailed();
    System.assert(res.hasError, 'Expected hasError to be true');
  }
}