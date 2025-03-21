@IsTest
global class ADG_ContractProRegisterMockup implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody('{"success": true, "error_message": null}');
      res.setStatusCode(200);
      return res;
    }
  }