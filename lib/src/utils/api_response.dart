import 'dart:collection' as collection;

class ApiResponse {
  String? result;

  ApiResponse();

  ApiResponse.fromJson(Map json) {
    if (json.containsKey('result')) {
      result = json['result'] as String?;
    }
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{};
    if (result != null) {
      json['result'] = result;
    }
    return json;
  }
}

class ListOfint extends collection.ListBase<int> {
  final List<int> _inner;

  ListOfint() : _inner = [];

  ListOfint.fromJson(List json)
      : _inner = json.map((value) => value as int).toList();

  List<int> toJson() {
    return _inner.map((value) => value).toList();
  }

  @override
  int operator [](int key) => _inner[key];

  @override
  void operator []=(int key, int value) {
    _inner[key] = value;
  }

  @override
  int get length => _inner.length;

  @override
  set length(int newLength) {
    _inner.length = newLength;
  }
}

class ListOfString extends collection.ListBase<String> {
  final List<String> _inner;

  ListOfString() : _inner = [];

  ListOfString.fromJson(List json)
      : _inner = json.map((value) => value as String).toList();

  List<String> toJson() {
    return _inner.map((value) => value).toList();
  }

  @override
  String operator [](int key) => _inner[key];

  @override
  void operator []=(int key, String value) {
    _inner[key] = value;
  }

  @override
  int get length => _inner.length;

  @override
  set length(int newLength) {
    _inner.length = newLength;
  }
}
