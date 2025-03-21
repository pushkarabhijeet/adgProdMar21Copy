@isTest
global class ADG_JobPathCalloutMockup implements HttpCalloutMock {

  public String body { get; set; }

  global HTTPResponse respond(HTTPRequest req) {
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    res.setBody(body);
    res.setStatusCode(200);
    return res;
  }

  public void setJobPathsBody(String assetId) {
    body = '[{"sf_asset_id":"' +
    assetId +
    '", "success":true, "job_path":"NEW JOB PATH","entity_path":"NEW ENTITY PATH","error":null}]';
  }

  public void setSingleJobPathBody(String assetId, Boolean isSuccess) {
    if (isSuccess) {
      body = '{"sf_asset_id":"' +
      assetId +
      '", "success":true, "job_path":"NEW JOB PATH","entity_path":"NEW ENTITY PATH","error":null}';
    } else {
      body = '{"sf_asset_id":"' +
        assetId +  '", "success":false, "job_path":null,"entity_path":null,"error":null}';
     }
  }
}