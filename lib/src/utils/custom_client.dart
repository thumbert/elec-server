library utils.custom_client;

import 'package:http/http.dart';
import 'package:http/browser_client.dart';


/// discoveryapis_commons.requester tries to set these two headers which results in 
/// errors in the js console.  You can avoid all that, by using this CustomClient.
class CustomClient extends BrowserClient {
  CustomClient();
  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    request.headers.remove('user-agent');
    request.headers.remove('content-length');
    StreamedResponse response = await super.send(request);
    return response;
  }
}