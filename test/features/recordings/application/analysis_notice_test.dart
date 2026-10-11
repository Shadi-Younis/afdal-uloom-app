import 'package:afdal_uloom_tilawat/core/models/analysis_status.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_analysis.dart';
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

  test('practice recordings: never', () {
    final practice = sampleRecording('p1', type: RecordingType.practice);
    expect(analysisNoticeFor(practice, createdAt), isNull);
  });
}
