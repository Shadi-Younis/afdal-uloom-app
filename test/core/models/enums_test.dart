import 'package:afdal_uloom_tilawat/core/models/analysis_status.dart';
import 'package:afdal_uloom_tilawat/core/models/feedback_kind.dart';
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

  test('AnalysisStatus values match the Firestore strings', () {
    expect(AnalysisStatus.values.map((s) => s.value), [
      'pending',
      'done',
      'mono',
      'failed',
    ]);
    for (final status in AnalysisStatus.values) {
      expect(AnalysisStatus.fromValue(status.value), status);
    }
  });

  test('FeedbackKind values match the Firestore strings', () {
    expect(FeedbackKind.values.map((k) => k.value), ['voice', 'text']);
    for (final kind in FeedbackKind.values) {
      expect(FeedbackKind.fromValue(kind.value), kind);
    }
  });

  test('unknown strings throw FormatException', () {
    expect(() => UserRole.fromValue('Admin'), throwsFormatException);
    expect(() => UserRole.fromValue(''), throwsFormatException);
    expect(() => RecordingType.fromValue('studio'), throwsFormatException);
    expect(() => AnalysisStatus.fromValue('Done'), throwsFormatException);
    expect(() => FeedbackKind.fromValue('audio'), throwsFormatException);
  });
}
