import 'package:afdal_uloom_tilawat/core/models/analysis_status.dart';
import 'package:afdal_uloom_tilawat/core/models/feedback_kind.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_source.dart';
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
      'merging',
      'pending',
      'done',
      'mono',
      'failed',
    ]);
    for (final status in AnalysisStatus.values) {
      expect(AnalysisStatus.fromValue(status.value), status);
    }
  });

  test(
    'RecordingSource values match the Firestore strings; missing is stereo',
    () {
      expect(RecordingSource.values.map((s) => s.value), ['stereo', 'stems']);
      for (final source in RecordingSource.values) {
        expect(RecordingSource.fromValue(source.value), source);
      }
      expect(RecordingSource.fromValue(null), RecordingSource.stereo);
      // A source this app does not know (a newer server's): one file.
      expect(RecordingSource.fromValue('Stems'), RecordingSource.stereo);
      expect(RecordingSource.fromValue('three-files'), RecordingSource.stereo);
    },
  );

  test('an unknown AnalysisStatus is pending: never fails a document', () {
    expect(AnalysisStatus.fromValue('Done'), AnalysisStatus.pending);
    expect(AnalysisStatus.fromValue('transcribing'), AnalysisStatus.pending);
  });

  test('FeedbackKind values match the Firestore strings', () {
    expect(FeedbackKind.values.map((k) => k.value), ['voice', 'text']);
    for (final kind in FeedbackKind.values) {
      expect(FeedbackKind.fromValue(kind.value), kind);
    }
  });

  test('the strict enums: unknown strings throw FormatException', () {
    expect(() => UserRole.fromValue('Admin'), throwsFormatException);
    expect(() => UserRole.fromValue(''), throwsFormatException);
    expect(() => RecordingType.fromValue('studio'), throwsFormatException);
    expect(() => FeedbackKind.fromValue('audio'), throwsFormatException);
  });
}
