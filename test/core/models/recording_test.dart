import 'package:afdal_uloom_tilawat/core/models/analysis_status.dart';
import 'package:afdal_uloom_tilawat/core/models/recording.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_analysis.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_source.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_type.dart';
import 'package:afdal_uloom_tilawat/core/models/stem_paths.dart';
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

  test('analysis and playbackPath: absent until the server writes them', () {
    final uploaded = build();
    expect(uploaded.analysis, isNull);
    expect(uploaded.playablePath, 'recordings/s1/r1.mp3');

    final analysed = uploaded.copyWith(
      analysis: RecordingAnalysis(status: AnalysisStatus.done, segmentCount: 2),
      playbackPath: 'recordings/s1/r1.play.mp3',
    );
    expect(analysed.playablePath, 'recordings/s1/r1.play.mp3');
    expect(analysed.toMap()['analysis'], {'status': 'done', 'segmentCount': 2});
    expect(Recording.fromMap('r1', analysed.toMap()), analysed);
    expect(analysed, isNot(uploaded));

    final failed = uploaded.copyWith(
      analysis: RecordingAnalysis(
        status: AnalysisStatus.failed,
        error: 'decode',
      ),
    );
    expect(Recording.fromMap('r1', failed.toMap()), failed);
  });

  group('two-file recordings (Task 11)', () {
    const stemPaths = StemPaths(
      student: 'recordings/s1/r1.student.wav',
      sheikh: 'recordings/s1/r1.sheikh.mp3',
    );
    final stems = build().copyWith(
      source: RecordingSource.stems,
      stemPaths: stemPaths,
    );

    test('a stereo recording writes no source (missing means stereo)', () {
      final map = build().toMap();
      expect(map.containsKey('source'), isFalse);
      expect(map.containsKey('stemPaths'), isFalse);
      expect(Recording.fromMap('r1', map).source, RecordingSource.stereo);
      expect(
        Recording.fromMap('r1', {...map, 'source': 'stereo'}),
        build(),
      );
    });

    test('source and stemPaths round trip with the contract names', () {
      final map = stems.toMap();
      expect(map['source'], 'stems');
      expect(map['stemPaths'], {
        'student': 'recordings/s1/r1.student.wav',
        'sheikh': 'recordings/s1/r1.sheikh.mp3',
      });
      expect(Recording.fromMap('r1', map), stems);
      expect(stems, isNot(build()));
      expect(stems.toString(), contains('stems'));
    });

    test('broken source or stemPaths throw FormatException', () {
      final map = stems.toMap();
      expect(
        () => Recording.fromMap('r1', {...map, 'source': 'mono'}),
        throwsFormatException,
      );
      expect(
        () => Recording.fromMap('r1', {
          ...map,
          'stemPaths': {'student': 'recordings/s1/r1.student.wav'},
        }),
        throwsFormatException,
      );
    });

    test('hasAudio: a stereo recording always, stems once joined', () {
      RecordingAnalysis status(AnalysisStatus s, [String? error]) =>
          RecordingAnalysis(status: s, error: error);
      expect(build().hasAudio, isTrue);
      expect(
        build().copyWith(analysis: status(AnalysisStatus.failed)).hasAudio,
        isTrue,
      );
      expect(stems.hasAudio, isFalse); // uploading, or waiting for a file
      expect(
        stems.copyWith(analysis: status(AnalysisStatus.merging)).hasAudio,
        isFalse,
      );
      for (final joined in [
        AnalysisStatus.pending,
        AnalysisStatus.done,
        AnalysisStatus.mono,
      ]) {
        expect(stems.copyWith(analysis: status(joined)).hasAudio, isTrue);
      }
      expect(
        stems
            .copyWith(
              analysis: status(AnalysisStatus.failed, 'stems_misaligned'),
            )
            .hasAudio,
        isFalse,
      );
      // Joined, then its analysis failed: the joined file plays.
      expect(
        stems
            .copyWith(analysis: status(AnalysisStatus.failed, 'decode'))
            .hasAudio,
        isTrue,
      );
    });
  });

  test('the analysis details round trip; whole dB from Firestore are ints', () {
    final analysis = RecordingAnalysis(
      status: AnalysisStatus.done,
      segmentCount: 3,
      swapped: true,
      bleedDb: -15.4,
      separationDb: 30,
      stemsLagMs: -20,
    );
    final map = analysis.toMap();
    expect(map, {
      'status': 'done',
      'segmentCount': 3,
      'swapped': true,
      'bleedDb': -15.4,
      'separationDb': 30.0,
      'stemsLagMs': -20,
    });
    expect(RecordingAnalysis.fromMap(map), analysis);
    expect(
      RecordingAnalysis.fromMap({...map, 'bleedDb': -15}).bleedDb,
      -15.0,
    );
    expect(analysis.isStemsFailure, isFalse);
    expect(
      RecordingAnalysis(
        status: AnalysisStatus.failed,
        error: 'stems_length_mismatch',
      ).isStemsFailure,
      isTrue,
    );
    expect(analysis.toString(), contains('swapped: true'));
  });

  test('an unknown analysis status throws FormatException', () {
    final map = {
      ...build().toMap(),
      'analysis': {'status': 'thinking'},
    };
    expect(() => Recording.fromMap('r1', map), throwsFormatException);
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
