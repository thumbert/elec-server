import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';


/// Login into Microsoft Graph explorer
/// https://developer.microsoft.com/en-us/graph/graph-explorer and get your
/// token to get profile
Future<void> getMyProfile(String token) async {
  var headers = {
    'Authorization': 'Bearer $token'
  };
  var url = Uri.parse('https://graph.microsoft.com/v1.0/me');
  var res = await http.get(url, headers: headers);
  print('status code: ${res.statusCode}');
  print(res.body);
}

/// To send an email I could not use the http package, I had to use the
/// HttpClient class from dart:io because I needed to set the content-type
/// header to 'application/json'.
///
/// The [token] expires too soon.  Need to find a way to extend it!
///
Future<void> sendEmail(
    String token, String subject, String content, List<String> toRecipients,
    {String contentType = 'HTML', String importance = 'normal'}) async {
  var rs = toRecipients
      .map((e) => {
            'emailAddress': {
              'address': e,
            }
          })
      .toList();

  var body = json.encode({
    'message': {
      'toRecipients': rs,
      'subject': subject,
      'importance': importance,
      'body': {
        'contentType': contentType,
        'content': content,
      },
    }
  });

  var url = Uri.parse('https://graph.microsoft.com/v1.0/me/sendMail');
  var client = HttpClient();
  var request = await client.postUrl(url);
  request.headers.set('content-type', 'application/json');
  request.headers.set('Authorization', 'Bearer $token');
  request.add(utf8.encode(body));
  var res = await request.close();
  if (res.statusCode == 202) {
    print('Success!  Email sent!');
  } else {
    print(res.statusCode);
    var reply = await res.transform(utf8.decoder).join();
    print(reply);
  }
  client.close();
}


/// Try to get a token either from an existing file, or login and get a new
/// one.
/// Run python3.10 test/utils/azure/ms_graph.py to acquire a token and save
/// it to a file.
Future<String> getToken({int n=0}) async {
  var file = File('ms_graph_api_token.json');
  String? token;
  if (file.existsSync()) {
    var contents = json.decode(file.readAsStringSync()) as Map<String,dynamic>;
    var accessToken = contents['AccessToken'] as Map<String,dynamic>;
    var kv = accessToken.values.first as Map;
    if (!kv.containsKey('expires_on')) {
      throw StateError('Format of api token json file changed!');
    }
    var seconds = int.parse(kv['expires_on']!);
    var expirationDate = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);

    if (DateTime.now().isBefore(expirationDate)) {
      if (kv.containsKey('secret')) return kv['secret']!;
    }
  }

  /// If token file doesn't exist or the token is expired
  /// try to get a new one.  Only try once!
  if (token == null && n == 0) {
    /// launch the python sign-in process
    var res = Process.runSync('python3.10', ['test/utils/azure/ms_graph.py']);
    print(res.stderr);
    print(res.stdout);
    return await getToken(n: 1);
  }

  throw StateError('Can\'t find token or get a new one!');
}


Future<void> main() async {

  var token = await getToken();
  // await getMyProfile(token);

  var toRecipients = [
    'tony.humbert27@outlook.com',
  ];
  var subject = 'test email';
  var content = 'Be Awesome.  From Dart! \&#128512;';
  await sendEmail(token, subject, content, toRecipients);

}
