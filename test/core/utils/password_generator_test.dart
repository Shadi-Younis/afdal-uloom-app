import 'dart:math';

import 'package:afdal_uloom_tilawat/core/utils/password_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final allowed = RegExp(r'^[abcdefghjkmnpqrstuvwxyz23456789]+$');
  final digit = RegExp('[0-9]');

  test('8 characters, lower-case letters and digits only', () {
    final password = PasswordGenerator().generate();
    expect(password, hasLength(8));
    expect(password, matches(allowed));
  });

  test('never uses look-alike characters, always has 2+ digits', () {
    // Many seeds, so every position and character class is exercised.
    for (var seed = 0; seed < 2000; seed++) {
      final password = PasswordGenerator(Random(seed)).generate();
      expect(password, hasLength(8));
      expect(password, isNot(matches(RegExp('[01oOlIi]'))), reason: password);
      expect(password, matches(allowed), reason: password);
      expect(digit.allMatches(password).length, greaterThanOrEqualTo(2));
    }
  });

  test('digits are not always in the same positions', () {
    final firstTwoDigits = {
      for (var seed = 0; seed < 200; seed++)
        PasswordGenerator(Random(seed))
            .generate()
            .substring(0, 2)
            .contains(RegExp(r'^\d\d$')),
    };
    expect(firstTwoDigits, {true, false});
  });

  test('passwords differ between calls', () {
    final generator = PasswordGenerator();
    final passwords = {for (var i = 0; i < 50; i++) generator.generate()};
    expect(passwords.length, greaterThan(45));
  });

  test('the same seed gives the same password (tests can rely on it)', () {
    expect(
      PasswordGenerator(Random(7)).generate(),
      PasswordGenerator(Random(7)).generate(),
    );
  });
}
