import 'package:afdal_uloom_tilawat/features/admin/application/input_error.dart';
import 'package:afdal_uloom_tilawat/features/admin/application/input_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fullName: 2..60 characters, trimmed', () {
    expect(InputValidator.fullName('  '), InputError.required);
    expect(InputValidator.fullName(' أ '), InputError.tooShort);
    expect(InputValidator.fullName('أب'), isNull);
    expect(InputValidator.fullName('ا' * 60), isNull);
    expect(InputValidator.fullName('ا' * 61), InputError.tooLong);
  });

  test('username: 3..20 of a-z 0-9 . _ -, after trim and lower-case', () {
    expect(InputValidator.username(''), InputError.required);
    expect(InputValidator.username('ab'), InputError.tooShort);
    expect(InputValidator.username('a' * 21), InputError.tooLong);
    expect(InputValidator.username(' S013 '), isNull);
    expect(InputValidator.username('ali.k_9-x'), isNull);
    expect(InputValidator.username('has space'), InputError.invalidCharacters);
    expect(InputValidator.username('أحمد'), InputError.invalidCharacters);
    expect(InputValidator.normalizeUsername(' S013 '), 's013');
  });

  test('password: 6..64, spaces kept', () {
    expect(InputValidator.password(''), InputError.required);
    expect(InputValidator.password('12345'), InputError.tooShort);
    expect(InputValidator.password('  1234'), isNull);
    expect(InputValidator.password('x' * 64), isNull);
    expect(InputValidator.password('x' * 65), InputError.tooLong);
  });

  test('studentCode: S + 3..5 digits, upper-cased', () {
    expect(InputValidator.studentCode(' '), InputError.required);
    expect(InputValidator.studentCode('S013'), isNull);
    expect(InputValidator.studentCode('s013'), isNull);
    expect(InputValidator.studentCode('S12345'), isNull);
    expect(InputValidator.studentCode('S12'), InputError.invalidFormat);
    expect(InputValidator.studentCode('S123456'), InputError.invalidFormat);
    expect(InputValidator.studentCode('013'), InputError.invalidFormat);
    expect(InputValidator.normalizeStudentCode(' s013'), 'S013');
  });

  test('halaqaName: 1..60, trimmed; choices are required', () {
    expect(InputValidator.halaqaName(' '), InputError.required);
    expect(InputValidator.halaqaName('ح'), isNull);
    expect(InputValidator.halaqaName('ح' * 61), InputError.tooLong);
    expect(InputValidator.choice(null), InputError.required);
    expect(InputValidator.choice(''), InputError.required);
    expect(InputValidator.choice('t01'), isNull);
  });
}
