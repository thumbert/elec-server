library api.polygraph.api_polygraph;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class ApiPolygraph {
  late DbCollection coll;
  String collectionName = 'projects';

  ApiPolygraph(Db db) {
    coll = db.collection(collectionName);
  }
  var headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();
    router.get('/users', (Request request) async {
      var users = await getUsers();
      return Response.ok(json.encode(users), headers: headers);
    });

    router.get('/user/<userId>/project_names', (Request request, String userId) async {
      var projects = await projectsForUserId(userId);
      return Response.ok(json.encode(projects), headers: headers);
    });

    router.get('/user/<userId>/project_name/<projectName>',
            (Request request, String userId, String projectName) async {
          projectName = Uri.decodeComponent(projectName);
          var project = await getProject(userId, projectName);
          return Response.ok(json.encode(project), headers: headers);
        });

    /// If the calculator already exists in the collection, it will fail.
    router.post('/save_project', (Request request) async {
      final payload = await request.readAsString();
      var data = json.decode(payload) as Map<String, dynamic>;
      var res = await coll.insert(data);
      var out = <String, dynamic>{'err': res['err'], 'ok': res['ok']};
      return Response.ok(json.encode(out), headers: headers);
    });

    router.delete('/user/<userId>/project_name/<projectName>',
            (Request request, String userId, String projectName) async {
          await removeProject(userId, projectName);
          return Response.ok(json.encode({'ok': 1.0}), headers: headers);
        });

    return router;
  }

  Future<List<String>> getUsers() async {
    var data = await coll.distinct('userId');
    var types = (data['values'] as List).cast<String>();
    types.sort((a, b) => a.compareTo(b));
    return types;
  }

  Future<List<String>> projectsForUserId(String userId) async {
    var data =
    await coll.distinct('calculatorName', where.eq('userId', userId));
    var names = (data['values'] as List).cast<String>();
    names.sort((a, b) => a.compareTo(b));
    return names;
  }

  Future<Map<String,dynamic>> getProject(
      String userId, String projectName) async {
    var res = await (coll
        .findOne({'userId': userId, 'projectName': projectName}));
    if (res == null) {
      return <String,dynamic>{};
    } else {
      res.remove('_id');
      return res;
    }
  }

  Future<Map<String,dynamic>> removeProject(
      String userId, String projectName) async {
    var res =
    await coll.remove({'userId': userId, 'calculatorName': projectName});
    var out = <String, dynamic>{'err': res['err'], 'ok': res['ok']};
    return out;
  }
}
