import 'package:afdal_uloom_tilawat/core/models/analysis_status.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_analysis.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_source.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_type.dart';
import 'package:afdal_uloom_tilawat/features/recordings/application/analysis_notice.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_recording_repository.dart';

void main() {
  // sampleRecording's createdAt.
  final createdAt = DateTime(2026, 9, 8, 18);
  final official = sampleRecording('r1');

  AnalysisNotice? noticeWith(AnalysisStatus status, DateTime now) =>
      analysisNoticeFor(
        official.copyWith(analysis: RecordingAnalysis(status: status)),
        now,
      );

  test('each status of an official recording', () {
    final now = createdAt.add(const Duration(days: 3));
    expect(noticeWith(AnalysisStatus.pending, now), AnalysisNotice.pending);
    expect(noticeWith(AnalysisStatus.mono, now), AnalysisNotice.mono);
    expect(noticeWith(AnalysisStatus.failed, now), AnalysisNotice.failed);
    expect(noticeWith(AnalysisStatus.done, now), isNull);
  });

  test('no analysis: pending for 30 minutes after creation, then nothing', () {
    expect(
      analysisNoticeFor(official, createdAt.add(const Duration(minutes: 29))),
      AnalysisNotice.pending,
    );
    expect(
      analysisNoticeFor(official, createdAt.add(const Duration(minutes: 30))),
      isNull,
    );
  });

  group('a two-file recording', () {
    final stems = official.copyWith(source: RecordingSource.stems);
    final days = createdAt.add(const Duration(days: 3));
    AnalysisNotice? notice(
      RecordingAnalysis? analysis, {
      bool canManage = true,
    }) => analysisNoticeFor(
      analysis == null ? stems : stems.copyWith(analysis: analysis),
      days,
      canManage: canManage,
    );

    test('its teacher: merging while the files arrive or are joined', () {
      expect(notice(null), AnalysisNotice.merging);
      expect(
        notice(RecordingAnalysis(status: AnalysisStatus.merging)),
        AnalysisNotice.merging,
      );
    });

    test('its teacher: why the files could not be joined', () {
      RecordingAnalysis failed(String error) =>
          RecordingAnalysis(status: AnalysisStatus.failed, error: error);
      expect(
        notice(failed('stems_length_mismatch')),
        AnalysisNotice.stemsLengthMismatch,
      );
      expect(
        notice(failed('stems_misaligned')),
        AnalysisNotice.stemsMisaligned,
      );
      expect(notice(failed('stems_decode')), AnalysisNotice.stemsFailed);
    });

    test('once joined: the notices of any recording', () {
      expect(
        notice(RecordingAnalysis(status: AnalysisStatus.pending)),
        AnalysisNotice.pending,
      );
      expect(notice(RecordingAnalysis(status: AnalysisStatus.done)), isNull);
      expect(
        notice(RecordingAnalysis(status: AnalysisStatus.failed, error: 'x')),
        AnalysisNotice.failed,
      );
    });

    test('its student sees nothing about two files', () {
      expect(notice(null, canManage: false), AnalysisNotice.pending);
      expect(
        notice(
          RecordingAnalysis(status: AnalysisStatus.merging),
          canManage: false,
        ),
        AnalysisNotice.pending,
      );
      expect(
        notice(
          RecordingAnalysis(
            status: AnalysisStatus.failed,
            error: 'stems_misaligned',
          ),
          canManage: false,
        ),
        AnalysisNotice.failed,
      );
    });
  });

  test('practice recordings: never', () {
    final practice = sampleRecording('p1', type: RecordingType.practice);
    expect(analysisNoticeFor(practice, createdAt), isNull);
  });
}
