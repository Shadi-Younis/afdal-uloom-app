import 'package:afdal_uloom_tilawat/core/utils/map_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final map = <String, dynamic>{
    'name': 'x',
    'count': 3,
    'empty': null,
    'tags': ['a', 'b'],
  };

  test('readRequired returns the typed value', () {
    expect(readRequired<String>(map, 'name'), 'x');
    expect(readRequired<int>(map, 'count'), 3);
  });

  test('readRequired throws for missing, null or mistyped fields', () {
    expect(() => readRequired<String>(map, 'nope'), throwsFormatException);
    expect(() => readRequired<String>(map, 'empty'), throwsFormatException);
    expect(() => readRequired<String>(map, 'count'), throwsFormatException);
  });

  test('readOptional returns null for missing and null fields', () {
    expect(readOptional<int>(map, 'nope'), isNull);
    expect(readOptional<int>(map, 'empty'), isNull);
    expect(readOptional<int>(map, 'count'), 3);
    expect(() => readOptional<int>(map, 'name'), throwsFormatException);
  });

  test('readStringList', () {
    expect(readStringList(map, 'tags'), ['a', 'b']);
    expect(readStringList(map, 'nope'), isEmpty);
    expect(() => readStringList({'tags': 'a'}, 'tags'), throwsFormatException);
  });
}
