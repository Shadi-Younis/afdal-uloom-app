import 'package:afdal_uloom_tilawat/core/models/recording_type.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UserRole values match the Firestore strings', () {
    expect(UserRole.values.map((r) => r.value), [
      'admin',
      'teacher',
      'student',
    ]);
    for (final role in UserRole.values) {
      expect(UserRole.fromValue(role.value), role);
    }
  });

  test('RecordingType values match the Firestore strings', () {
    expect(RecordingType.values.map((t) => t.value), ['official', 'practice']);
    for (final type in RecordingType.values) {
      expect(RecordingType.fromValue(type.value), type);
    }
  });

  test('unknown strings throw FormatException', () {
    expect(() => UserRole.fromValue('Admin'), throwsFormatException);
    expect(() => UserRole.fromValue(''), throwsFormatException);
    expect(() => RecordingType.fromValue('studio'), throwsFormatException);
  });
}
