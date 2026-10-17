import 'package:afdal_uloom_tilawat/core/models/recording.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_type.dart';
import 'package:afdal_uloom_tilawat/core/utils/recording_titles.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The app's Arabic dates, as its Material localizations load them.
  setUpAll(() => GlobalMaterialLocalizations.delegate.load(const Locale('ar')));

  Recording build({int? surah, int? from, int? to}) => Recording(
    id: 'r1',
    studentId: 's1',
    halaqaId: 'h1',
    teacherId: 't1',
    uploadedBy: 't1',
    type: RecordingType.official,
    surahNumber: surah,
    ayahFrom: from,
    ayahTo: to,
    storagePath: 'recordings/s1/r1.mp3',
    recordedAt: DateTime(2026, 10, 16, 9),
    createdAt: DateTime(2026, 10, 16, 10),
    unreadFeedback: false,
    reviewed: false,
  );

  test('surah and ayat', () {
    final r = build(surah: 2, from: 1, to: 20);
    expect(recordingTitleOf(r), 'البقرة: الآيات ١–٢٠');
    expect(recordingHeadingOf(r), 'سورة البقرة');
    expect(recordingAyatOf(r), 'الآيات ١–٢٠');
  });

  test('a surah without ayat: its name, no ayat line', () {
    final r = build(surah: 67);
    expect(recordingTitleOf(r), 'سورة الملك');
    expect(recordingHeadingOf(r), 'سورة الملك');
    expect(recordingAyatOf(r), isNull);
  });

  test('no surah: «تسجيل» and the recorded day, no ayat line', () {
    final r = build();
    expect(recordingTitleOf(r), 'تسجيل ١٦ أكتوبر ٢٠٢٦');
    expect(recordingHeadingOf(r), 'تسجيل ١٦ أكتوبر ٢٠٢٦');
    expect(recordingAyatOf(r), isNull);
  });
}
