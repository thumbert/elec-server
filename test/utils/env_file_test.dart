import 'dart:io';

import 'package:elec_server/src/utils/env_file.dart';
import 'package:test/test.dart';

void tests() {
  group('EnvFile tests', () {
    test('add a key, change a key, remove a key', () {
      var file = File('.env/test.env');
      var envFile = EnvFile(file);
      envFile.updateKey('foo', 'bar');
      var contents = file.readAsLinesSync();
      expect(contents.last, 'foo = bar');

      envFile.updateKey('foo', 'baz');
      contents = file.readAsLinesSync();
      expect(contents.last, 'foo = baz');

      envFile.removeKey('foo');
      contents = file.readAsLinesSync();
      expect(contents.any((e) => e.startsWith('foo')), false);
    });
  });
}

void main() {
  tests();
}
