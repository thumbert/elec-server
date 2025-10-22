import 'package:dotenv/dotenv.dart' as dotenv;
import 'dart:convert';

import 'package:http/http.dart';
import 'package:test/test.dart';

Future<void> tests(String rootUrl) async {
  group('Polygraph api tests:', () {
    test('Get users', () async {
      var url = '$rootUrl/polygraph/v1/users';
      var res = await get(Uri.parse(url));
      var users = json.decode(res.body) as List;
      expect(users.contains('e47187'), true);
    });
    test('Get all projects for one user', () async {
      var url = '$rootUrl/polygraph/v1/user/e47187/project_names';
      var res = await get(Uri.parse(url));
      var projectNames = json.decode(res.body) as List;
      expect(projectNames.contains('project 1'), true);
    });
    test('Get one project', () async {
      var url = '$rootUrl/polygraph/v1/user/e47187/project_name/project 1';
      var res = await get(Uri.parse(url));
      var data = json.decode(res.body) as Map<String, dynamic>;
      expect(data.keys.toSet(), {'userId', 'projectName', 'tabs'});
    });
    test('Save/Delete a project', () async {
      var url = '$rootUrl/polygraph/v1/save_project';
      var userId = 'Testy Tester';
      var projectName = 'Disposable';
      var project = {
        'userId': userId,
        'projectName': projectName,
        'tabs': [
          {
            'name': 'Tab 1',
          }
        ]
      };
      var res = await post(Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(project));
      print(res.body);
      var aux = await get(Uri.parse('$rootUrl/polygraph/v1/users'));
      var users = json.decode(aux.body) as List;
      expect(users.contains('Testy Tester'), true);

      var res2 = await delete(Uri.parse('$rootUrl/polygraph/v1/user'
          '/$userId/project_name/$projectName'));
      print(res2.body);
      aux = await get(Uri.parse('$rootUrl/polygraph/v1/users'));
      users = json.decode(aux.body) as List;
      expect(users.contains('Testy Tester'), false);
    });
  });
}

Future<void> main() async {
  dotenv.load('.env/prod.env');
  var rootUrl = dotenv.env['ROOT_URL']!;
  await tests(rootUrl);
}
