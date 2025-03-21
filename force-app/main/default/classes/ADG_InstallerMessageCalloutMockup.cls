@isTest
global class ADG_InstallerMessageCalloutMockup implements HttpCalloutMock {

  global HTTPResponse respond(HTTPRequest req) {
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    res.setBody(
      '[{ "server_message_id": "5Wa0bBuGABP4kdrrSuP4w","sender_message_id": "4682dea8-7587-4c27-83f0-5eb36dbc6c97","work_order_id": "0WO4T000000taU5WAI","sent_by_id": "0054T000001N9HsQAK","sender_type": 1,"sent_by_name": "Parker Strode","installer_account_id": "0014T000009nt5NQAQ","message_text": "ssssssssss","server_timestamp": "2022-04-14T16:17:02.091375+00:00"}]'
    );
    res.setStatusCode(200);
    return res;
  }
}