import 'package:afdal_uloom_tilawat/app/app.dart';
import 'package:afdal_uloom_tilawat/core/models/analysis_status.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/recording.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_analysis.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_source.dart';
import 'package:afdal_uloom_tilawat/core/models/stem_paths.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_recording_repository.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/student_fixture.dart';

/// A two-file recording (Task 11) on the recording screen and the
/// student's home: its teacher sees the files being joined and why a join
/// failed; its student sees nothing until it is joined, then one recording
/// like any other.
void main() {
  setUpAll(loadBundledFonts);

  const teacher = AuthSession(uid: 't01', role: UserRole.teacher);
  const merging = 'جارٍ دمج الملفين…';
  const swappedChip = 'تم تبديل الطالب والشيخ تلقائياً';

  late StudentFixture fixture;
  setUp(() => fixture = StudentFixture());

  /// s001's al-Ikhlas sent as two files, with [analysis] so far.
  Recording stems(String id, [RecordingAnalysis? analysis]) {
    final recording = sampleRecording(id, surahNumber: 112, ayahTo: 4).copyWith(
      source: RecordingSource.stems,
      storagePath: 'recordings/s001/$id.mp3',
      stemPaths: StemPaths(
        student: 'recordings/s001/$id.student.wav',
        sheikh: 'recordings/s001/$id.sheikh.wav',
      ),
    );
    return analysis == null
        ? recording
        : recording.copyWith(analysis: analysis);
  }

  Future<void> pumpApp(WidgetTester tester, AuthSession session) async {
    usePhoneSize(tester);
    fixture.school.auth.emit(session);
    await tester.pumpWidget(
      ProviderScope(overrides: fixture.overrides, child: const AfdalUloomApp()),
    );
    await tester.pumpAndSettle();
  }

  /// [spinning]: the banner's spinner never lets pumpAndSettle end.
  Future<void> open(
    WidgetTester tester,
    String id,
    AuthSession session, {
    bool spinning = false,
  }) async {
    await pumpApp(tester, session);
    currentRouter(tester).push('/recording/$id');
    if (spinning) {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    } else {
      await tester.pumpAndSettle();
    }
  }

  Finder player() => find.byTooltip('تشغيل');

  /// The teacher's «تمت المراجعة» toggle.
  Finder reviewedToggle() => find.widgetWithText(FilterChip, 'تمت المراجعة');

  group('its teacher', () {
    testWidgets('while the files arrive or are joined: «$merging», no player, '
        'nothing to review', (tester) async {
      fixture.school.recordings
        ..put(stems('st-1'))
        ..put(stems('st-2', RecordingAnalysis(status: AnalysisStatus.merging)));
      await open(tester, 'st-1', teacher, spinning: true);
      expect(find.text(merging), findsOneWidget);
      expect(player(), findsNothing);
      expect(reviewedToggle(), findsNothing);
      expect(tester.takeException(), isNull);

      currentRouter(tester).push('/recording/st-2');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(merging), findsOneWidget);
      expect(player(), findsNothing);
      expect(reviewedToggle(), findsNothing);
    });

    testWidgets('a join that failed says why; nothing to review', (
      tester,
    ) async {
      RecordingAnalysis failed(String error) =>
          RecordingAnalysis(status: AnalysisStatus.failed, error: error);
      fixture.school.recordings
        ..put(stems('st-long', failed('stems_length_mismatch')))
        ..put(stems('st-late', failed('stems_misaligned')))
        ..put(stems('st-other', failed('stems_decode')));

      await open(tester, 'st-long', teacher);
      expect(find.textContaining('مدتهما غير متساوية'), findsOneWidget);
      expect(player(), findsNothing);
      expect(reviewedToggle(), findsNothing);

      currentRouter(tester).push('/recording/st-late');
      await tester.pumpAndSettle();
      expect(find.textContaining('لا يطابق صوت الطالب'), findsOneWidget);
      expect(reviewedToggle(), findsNothing);

      currentRouter(tester).push('/recording/st-other');
      await tester.pumpAndSettle();
      expect(
        find.text('تعذّر دمج الملفين، احذف هذا التسجيل وارفعهما من جديد'),
        findsOneWidget,
      );
      expect(reviewedToggle(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('joined and the channels were swapped: the chip, the player', (
      tester,
    ) async {
      fixture.school.recordings.put(
        stems(
          'st-done',
          RecordingAnalysis(
            status: AnalysisStatus.done,
            segmentCount: 2,
            swapped: true,
          ),
        ),
      );
      await open(tester, 'st-done', teacher);
      expect(find.text(swappedChip), findsOneWidget);
      expect(find.text(merging), findsNothing);
      expect(player(), findsOneWidget);
      expect(reviewedToggle(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('joined, then its own analysis failed: it plays and can be '
        'reviewed', (tester) async {
      fixture.school.recordings.put(
        stems(
          'st-analysis-failed',
          RecordingAnalysis(status: AnalysisStatus.failed, error: 'decode'),
        ),
      );
      await open(tester, 'st-analysis-failed', teacher);
      expect(
        find.text('تعذّر تحليل التسجيل، يمكن إضافة الملاحظات يدوياً'),
        findsOne,
      );
      expect(player(), findsOneWidget);
      expect(reviewedToggle(), findsOneWidget);
    });
  });

  group('its student', () {
    final joined = RecordingAnalysis(
      status: AnalysisStatus.done,
      segmentCount: 2,
      swapped: true,
    );

    testWidgets('sees it only once joined, then like any other recording', (
      tester,
    ) async {
      fixture.school.recordings.put(
        stems('st-waiting', RecordingAnalysis(status: AnalysisStatus.merging)),
      );
      await pumpApp(tester, studentSession);
      expect(find.text('سورة الإخلاص'), findsNothing);

      fixture.school.recordings.put(stems('st-waiting', joined));
      await tester.pumpAndSettle();
      expect(find.text('سورة الإخلاص'), findsOneWidget);
    });

    testWidgets('a failed join never shows', (tester) async {
      fixture.school.recordings.put(
        stems(
          'st-failed',
          RecordingAnalysis(
            status: AnalysisStatus.failed,
            error: 'stems_misaligned',
          ),
        ),
      );
      await pumpApp(tester, studentSession);
      expect(find.text('سورة الإخلاص'), findsNothing);
    });

    testWidgets('the joined recording: the player, no word of two files', (
      tester,
    ) async {
      fixture.school.recordings.put(stems('st-done', joined));
      await open(tester, 'st-done', studentSession);
      expect(player(), findsOneWidget);
      expect(find.text(swappedChip), findsNothing);
      expect(find.text(merging), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opened by a link before it is joined: only «being analysed»', (
      tester,
    ) async {
      fixture.school.recordings.put(stems('st-1'));
      await open(tester, 'st-1', studentSession, spinning: true);
      expect(find.text('جاري تحليل التسجيل…'), findsOneWidget);
      expect(find.text(merging), findsNothing);
      expect(player(), findsNothing);
    });
  });
}
