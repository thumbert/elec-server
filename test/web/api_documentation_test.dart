import 'dart:io';
import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:html/parser.dart';

/// Get all the API links from the documentation.html file
List<String> getLinks() {
  File file = File('web/documentation.html');
  var input = file.readAsStringSync();
  var document = parse(input);
  var links = <String>[];
  for (var linkElement in document.querySelectorAll('a')) {
    var link = linkElement.attributes['href']!;

    /// ignore the internal links and the applications
    if (link.startsWith('#') || link.endsWith('.html')) {
      continue;
    }
    link = link.replaceAll('http://localhost:8080', '');
    links.add(link);
  }
  links.sort();
  return links;
}

/// Test if this url returns some content.
// bool hasContent(String url, Client client) {
//
// }

tests(String rootUrl, Set<String> skip) async {
  var links = getLinks();
  //links.forEach(print);

  var client = Client();
  for (var link in links) {
    var uri = Uri.encodeFull(rootUrl + link);
    test('Url $uri', () async {
      var response = await client.get(Uri.parse(uri));
      expect(response.statusCode, 200);
      //var body = response.body;
      //print(body);
    });
  }
}

main() async {
  String rootUrl = 'http://localhost:8080';
  var skip = <String>{}..addAll(['epa_emissions']);

  tests(rootUrl, skip);
}
