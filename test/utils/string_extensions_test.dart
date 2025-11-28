
import 'package:elec_server/src/utils/string_extensions.dart';
import 'package:test/test.dart';

void tests() {
  group('String extension tests', () {
    test('convert string to PascalCase', () {
      expect('hello world'.toPascalCase(), 'HelloWorld');
      expect('hello_world'.toPascalCase(), 'HelloWorld');
      expect('hello-world'.toPascalCase(), 'HelloWorld');
      expect('multiple   spaces here'.toPascalCase(), 'MultipleSpacesHere');
      expect('mixed_separators-here now'.toPascalCase(), 'MixedSeparatorsHereNow');
      expect(''.toPascalCase(), '');
    });

    test('convert string to snake case', () {
      expect('hello world'.toSnakeCase(), 'hello_world');
      expect('helloWorld'.toSnakeCase(), 'hello_world');
      expect('HelloWorld'.toSnakeCase(), 'hello_world');
      expect('thisIsATestString'.toSnakeCase(), 'this_is_a_test_string');
      expect('already_snake_case'.toSnakeCase(), 'already_snake_case');
      expect(''.toSnakeCase(), '');
    });
  });
}

void main() {
  tests();
}
