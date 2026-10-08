import 'package:afdal_uloom_tilawat/core/models/recording.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final recordedAt = DateTime.utc(2026, 10, 5, 16);
  final createdAt = DateTime.utc(2026, 10, 5, 18);

  Recording build({
    int surahNumber = 2,
    int ayahFrom = 1,
    int ayahTo = 20,
    int? durationSec = 300,
  }) => Recording(
    id: 'r1',
    studentId: 's1',
    halaqaId: 'h1',
    teacherId: 't1',
    uploadedBy: 't1',
    type: RecordingType.official,
    surahNumber: surahNumber,
    ayahFrom: ayahFrom,
    ayahTo: ayahTo,
    storagePath: 'recordings/s1/r1.mp3',
    durationSec: durationSec,
    recordedAt: recordedAt,
    createdAt: createdAt,
    unreadFeedback: false,
    reviewed: true,
  );

  test('toMap uses the contract field names and leaves out the id', () {
    expect(build().toMap(), {
      'studentId': 's1',
      'halaqaId': 'h1',
      'teacherId': 't1',
      'uploadedBy': 't1',
      'type': 'official',
      'surahNumber': 2,
      'ayahFrom': 1,
      'ayahTo': 20,
      'storagePath': 'recordings/s1/r1.mp3',
      'durationSec': 300,
      'recordedAt': recordedAt,
      'createdAt': createdAt,
      'unreadFeedback': false,
      'reviewed': true,
    });
  });

  test('round trip through toMap and fromMap', () {
    final recording = build();
    expect(Recording.fromMap('r1', recording.toMap()), recording);
    final noDuration = build(durationSec: null);
    expect(Recording.fromMap('r1', noDuration.toMap()), noDuration);
  });

  test('missing required field throws FormatException', () {
    final map = build().toMap()..remove('storagePath');
    expect(() => Recording.fromMap('r1', map), throwsFormatException);
  });

  test('wrong type throws FormatException', () {
    expect(
      () => Recording.fromMap('r1', {...build().toMap(), 'surahNumber': '2'}),
      throwsFormatException,
    );
  });

  test('unknown type throws FormatException', () {
    expect(
      () => Recording.fromMap('r1', {...build().toMap(), 'type': 'studio'}),
      throwsFormatException,
    );
  });

  test('accepts the edges of every range', () {
    expect(() => build(surahNumber: 1), returnsNormally);
    expect(() => build(surahNumber: 114), returnsNormally);
    expect(() => build(ayahFrom: 7, ayahTo: 7), returnsNormally);
    expect(() => build(durationSec: 0), returnsNormally);
  });

  test('invalid surah, ayah range or duration throws ArgumentError', () {
    expect(() => build(surahNumber: 0), throwsArgumentError);
    expect(() => build(surahNumber: 115), throwsArgumentError);
    expect(() => build(ayahFrom: 0), throwsArgumentError);
    expect(() => build(ayahFrom: 21, ayahTo: 20), throwsArgumentError);
    expect(() => build(durationSec: -1), throwsArgumentError);
  });

  test('fromMap with an out-of-range value throws ArgumentError', () {
    expect(
      () => Recording.fromMap('r1', {...build().toMap(), 'surahNumber': 200}),
      throwsArgumentError,
    );
  });

  test('copyWith validates too', () {
    expect(() => build().copyWith(ayahTo: 0), throwsArgumentError);
  });

  test('copyWith, equality and hashCode', () {
    final recording = build();
    final read = recording.copyWith(unreadFeedback: true);
    expect(read.unreadFeedback, isTrue);
    expect(read, isNot(recording));
    expect(recording.copyWith(), recording);
    expect(recording.copyWith().hashCode, recording.hashCode);
    expect(recording.toString(), contains('r1'));
  });
}
