
library utils.api_response;

import 'dart:collection' as collection;

class ApiResponse {
  String result;

  ApiResponse();

  ApiResponse.fromJson(Map _json) {
    if (_json.containsKey("result")) {
      result = _json["result"];
    }
  }

  Map<String, Object> toJson() {
    final Map<String, Object> _json = new Map<String, Object>();
    if (result != null) {
      _json["result"] = result;
    }
    return _json;
  }
}


class ListOfint extends collection.ListBase<int> {
  final List<int> _inner;

  ListOfint() : _inner = [];

  ListOfint.fromJson(List json) : _inner = json.map((value) => value).toList();

  List<int> toJson() {
    return _inner.map((value) => value).toList();
  }

  int operator [](int key) => _inner[key];

  void operator []=(int key, int value) {
    _inner[key] = value;
  }

  int get length => _inner.length;

  void set length(int newLength) {
    _inner.length = newLength;
  }
}

class ListOfString extends collection.ListBase<String> {
  final List<String> _inner;

  ListOfString() : _inner = [];

  ListOfString.fromJson(List json)
      : _inner = json.map((value) => value).toList();

  List<String> toJson() {
    return _inner.map((value) => value).toList();
  }

  String operator [](int key) => _inner[key];

  void operator []=(int key, String value) {
    _inner[key] = value;
  }

  int get length => _inner.length;

  void set length(int newLength) {
    _inner.length = newLength;
  }
}
