import 'package:afdal_uloom_tilawat/core/models/analysis_status.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/feedback_kind.dart';
import 'package:afdal_uloom_tilawat/core/models/feedback_note.dart';
import 'package:afdal_uloom_tilawat/core/models/recording.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_analysis.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_type.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/providers/clock_provider.dart';
import 'package:afdal_uloom_tilawat/core/providers/repository_providers.dart';
import 'package:afdal_uloom_tilawat/core/providers/service_providers.dart';
import 'package:afdal_uloom_tilawat/core/widgets/common/player_marker_bands.dart';
import 'package:afdal_uloom_tilawat/core/widgets/common/player_marker_lane.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/islamic_star.dart';
import 'package:afdal_uloom_tilawat/features/recordings/presentation/recording_screen.dart';
import 'package:afdal_uloom_tilawat/features/recordings/presentation/widgets/feedback_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/fake_recording_repository.dart';
import '../../../helpers/pump_app.dart';

/// The recording screen of Task 09: the centred copy, the sheikh's voice
/// markers on the seek bar and in the notes, and what the recording's
/// teacher can do with them.
void main() {
  setUpAll(loadBundledFonts);

  const teacher = AuthSession(uid: 't01', role: UserRole.teacher);
  const student = AuthSession(uid: 's001', role: UserRole.student);
  final now = DateTime(2026, 10, 11, 12);

  late AdminFixture school;

  FeedbackNote voice(String id, int at, int end, {String note = ''}) =>
      FeedbackNote(
        id: id,
        teacherId: 't01',
        note: note,
        kind: FeedbackKind.voice,
        atSecond: at,
        endSecond: end,
        createdAt: DateTime(2026, 9, 8, 19),
      );

  setUp(() {
    school = AdminFixture();
    school.recordings.put(
      sampleRecording('rec-02', unreadFeedback: true).copyWith(
        reviewed: false,
        analysis: RecordingAnalysis(
          status: AnalysisStatus.done,
          segmentCount: 2,
        ),
        playbackPath: 'recordings/s001/rec-02.play.mp3',
      ),
    );
    // rec-02 already has a note at 00:12 (fb-01) and one without a moment
    // (fb-02); the sheikh spoke at 00:05–00:09 and 00:20–00:24.
    school.feedback.notes['rec-02']!.addAll([
      voice('v2', 20, 24, note: 'المدّ هنا ست حركات'),
      voice('v1', 5, 9),
    ]);
  });

  Future<void> pumpRecording(
    WidgetTester tester, {
    String id = 'rec-02',
    AuthSession session = teacher,
    bool settle = true,
  }) async {
    await pumpScreen(
      tester,
      RecordingScreen(recordingId: id),
      auth: FakeAuthService(initial: session),
      overrides: [
        userRepositoryProvider.overrideWithValue(school.users),
        halaqaRepositoryProvider.overrideWithValue(school.halaqat),
        recordingRepositoryProvider.overrideWithValue(school.recordings),
        feedbackRepositoryProvider.overrideWithValue(school.feedback),
        audioStorageServiceProvider.overrideWithValue(school.storage),
        audioPlayerServiceProvider.overrideWith((ref) => school.player),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    // The pending analysis shows a never-ending spinner.
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Finder lane() => find.byType(PlayerMarkerLane);
  Finder laneStars() =>
      find.descendant(of: lane(), matching: find.byType(IslamicStar));

  testWidgets('plays the centred copy, not the stereo original', (
    tester,
  ) async {
    await pumpRecording(tester);
    expect(school.storage.urlRequests.map((r) => r.$1), [
      'recordings/s001/rec-02.play.mp3',
    ]);
  });

  testWidgets('a star per moment on the seek bar, a band per voice span', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpRecording(tester);
    expect(laneStars(), findsNWidgets(3));
    expect(
      find.descendant(
        of: find.byType(PlayerMarkerBands),
        matching: find.byType(DecoratedBox),
      ),
      findsNWidgets(2),
    );
    // RTL: the first star (00:05 of 00:30) is nearest the right edge.
    final xs = [
      for (var i = 0; i < 3; i++) tester.getCenter(laneStars().at(i)).dx,
    ];
    expect(xs.first, greaterThan(xs.last));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a star jumps there and plays', (tester) async {
    await pumpRecording(tester);
    await tester.tap(laneStars().first);
    await tester.pump();
    expect(school.player.seeks.last, const Duration(seconds: 5));
    expect(school.player.playCalls, 1);
  });

  testWidgets('«التالي» and «السابق» go from marker to marker', (tester) async {
    await pumpRecording(tester);
    final next = find.widgetWithText(OutlinedButton, 'التالي');
    final previous = find.widgetWithText(OutlinedButton, 'السابق');
    expect(tester.widget<OutlinedButton>(previous).onPressed, isNull);

    await tester.tap(next);
    await tester.pump();
    expect(school.player.seeks.last, const Duration(seconds: 5));
    await tester.tap(next);
    await tester.pump();
    expect(school.player.seeks.last, const Duration(seconds: 12));
    await tester.tap(next);
    await tester.pump();
    expect(school.player.seeks.last, const Duration(seconds: 20));
    expect(tester.widget<OutlinedButton>(next).onPressed, isNull);

    await tester.tap(previous);
    await tester.pump();
    expect(school.player.seeks.last, const Duration(seconds: 12));
    expect(school.player.playCalls, 4);
  });

  testWidgets('the notes in the order of the recitation', (tester) async {
    usePhoneSize(tester);
    await pumpRecording(tester);
    await scrollTo(tester, find.text('راجع الآية الخامسة'));

    final tiles = find.byType(FeedbackTile).evaluate().toList();
    expect(tiles, hasLength(4));
    final order = [
      for (final tile in tiles) (tile.widget as FeedbackTile).note.id,
    ];
    expect(order, ['v1', 'fb-01', 'v2', 'fb-02']);
    expect(find.text('ملاحظة صوتية من الشيخ'), findsNWidgets(2));
    expect(find.text(' · ٠٠:٠٥–٠٠:٠٩'), findsOneWidget);
    expect(find.text(' · ٠٠:٢٠–٠٠:٢٤'), findsOneWidget);
    expect(find.text('المدّ هنا ست حركات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a voice note plays from its start', (tester) async {
    await pumpRecording(tester);
    await scrollTo(tester, find.text('المدّ هنا ست حركات'));
    await tester.tap(find.text('المدّ هنا ست حركات'));
    await tester.pump();
    expect(school.player.seeks.last, const Duration(seconds: 20));
    expect(school.player.playCalls, 1);
  });

  group('the analysis', () {
    Future<void> withAnalysis(
      WidgetTester tester,
      RecordingAnalysis? analysis, {
      DateTime? createdAt,
      RecordingType type = RecordingType.official,
      bool settle = true,
    }) async {
      final base = sampleRecording('rec-new', type: type);
      school.recordings.recordings['rec-new'] = base.copyWithAnalysis(
        analysis,
        createdAt: createdAt ?? now.subtract(const Duration(minutes: 2)),
      );
      await pumpRecording(tester, id: 'rec-new', settle: settle);
    }

    testWidgets('pending: «جاري تحليل التسجيل…», then the markers', (
      tester,
    ) async {
      await withAnalysis(
        tester,
        RecordingAnalysis(status: AnalysisStatus.pending),
        settle: false,
      );
      expect(find.text('جاري تحليل التسجيل…'), findsOneWidget);
      expect(lane(), findsNothing);

      school.feedback.put('rec-new', [voice('m1', 3, 6)]);
      school.recordings.put(
        school.recordings.recordings['rec-new']!.copyWith(
          analysis: RecordingAnalysis(
            status: AnalysisStatus.done,
            segmentCount: 1,
          ),
          playbackPath: 'recordings/s001/rec-new.play.mp3',
        ),
      );
      // The screen follows the document: no reload needed.
      await tester.pumpAndSettle();
      expect(find.text('جاري تحليل التسجيل…'), findsNothing);
      expect(laneStars(), findsOneWidget);
    });

    testWidgets('just uploaded, no analysis yet: pending too', (tester) async {
      await withAnalysis(tester, null, settle: false);
      expect(find.text('جاري تحليل التسجيل…'), findsOneWidget);
    });

    testWidgets('uploaded before Task 09 (old, no analysis): nothing', (
      tester,
    ) async {
      await withAnalysis(tester, null, createdAt: DateTime(2026, 9, 1));
      expect(find.text('جاري تحليل التسجيل…'), findsNothing);
    });

    testWidgets('mono: the message', (tester) async {
      await withAnalysis(
        tester,
        RecordingAnalysis(status: AnalysisStatus.mono),
      );
      expect(
        find.text(
          'لم نجد قناة الشيخ منفصلة في هذا الملف (صُدِّر بدون يسار/يمين)، '
          'يمكن إضافة الملاحظات يدوياً',
        ),
        findsOneWidget,
      );
    });

    testWidgets('failed: the message, the original still plays', (
      tester,
    ) async {
      await withAnalysis(
        tester,
        RecordingAnalysis(status: AnalysisStatus.failed, error: 'decode'),
      );
      expect(
        find.text('تعذّر تحليل التسجيل، يمكن إضافة الملاحظات يدوياً'),
        findsOneWidget,
      );
      expect(find.textContaining('decode'), findsNothing);
      expect(
        school.storage.urlRequests.single.$1,
        'recordings/s001/rec-new.wav',
      );
    });

    testWidgets('practice recordings say nothing about it', (tester) async {
      await withAnalysis(tester, null, type: RecordingType.practice);
      expect(find.text('جاري تحليل التسجيل…'), findsNothing);
    });
  });

  group('the recording\'s teacher', () {
    testWidgets('adds a note at the current second', (tester) async {
      await pumpRecording(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, 'التالي'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'إضافة ملاحظة هنا'));
      await tester.pumpAndSettle();

      expect(school.player.pauseCalls, greaterThanOrEqualTo(1));
      expect(find.text('ملاحظة جديدة'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('عند ٠٠:٠٥'),
        ),
        findsOneWidget,
      );
      // The dialog asks for the note only: no stars any more.
      expect(find.text('التقييم (اختياري)'), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
      await tester.enterText(find.byType(TextField), '  أطل الغنّة هنا  ');
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();

      final (recordingId, note) = school.feedback.added.single;
      expect(recordingId, 'rec-02');
      expect(note.teacherId, 't01');
      expect(note.kind, FeedbackKind.text);
      expect(note.atSecond, 5);
      expect(note.note, 'أطل الغنّة هنا');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('تم حفظ الملاحظة'), findsOneWidget);
    });

    testWidgets('a note needs text', (tester) async {
      await pumpRecording(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'إضافة ملاحظة هنا'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();
      expect(find.text('اكتب الملاحظة'), findsOneWidget);
      expect(school.feedback.added, isEmpty);

      await tester.enterText(find.byType(TextField), 'أحسنت');
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();
      expect(school.feedback.added.single.$2.atSecond, 0);
    });

    testWidgets('adds text to a voice marker', (tester) async {
      await pumpRecording(tester);
      await scrollTo(tester, find.byTooltip('إضافة نص'));
      await tester.tap(find.byTooltip('إضافة نص'));
      await tester.pumpAndSettle();
      expect(find.text('تعديل الملاحظة'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'انتبه للقلقلة');
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();

      expect(school.feedback.updated.single, ('rec-02', 'v1', 'انتبه للقلقلة'));
      expect(find.text('انتبه للقلقلة'), findsOneWidget);
    });

    testWidgets('deletes a note after confirming', (tester) async {
      await pumpRecording(tester);
      await scrollTo(tester, find.text('راجع الآية الخامسة'));
      final tile = find.ancestor(
        of: find.text('راجع الآية الخامسة'),
        matching: find.byType(FeedbackTile),
      );
      await tester.tap(
        find.descendant(of: tile, matching: find.byTooltip('حذف الملاحظة')),
      );
      await tester.pumpAndSettle();
      expect(find.text('ستُحذف هذه الملاحظة نهائياً.'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'حذف الملاحظة'));
      await tester.pumpAndSettle();

      expect(school.feedback.deleted.single, ('rec-02', 'fb-02'));
      expect(find.text('راجع الآية الخامسة'), findsNothing);
      expect(find.text('تم حذف الملاحظة'), findsOneWidget);
    });

    testWidgets('«تمت المراجعة» toggles reviewed', (tester) async {
      await pumpRecording(tester);
      final chip = find.widgetWithText(FilterChip, 'تمت المراجعة');
      await scrollTo(tester, chip);
      expect(tester.widget<FilterChip>(chip).selected, isFalse);

      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(school.recordings.reviewedCalls, [('rec-02', true)]);
      expect(tester.widget<FilterChip>(chip).selected, isTrue);

      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(school.recordings.reviewedCalls.last, ('rec-02', false));
    });

    testWidgets('fits a 360x640 phone', (tester) async {
      usePhoneSize(tester);
      await pumpRecording(tester);
      await scrollTo(tester, find.text('راجع الآية الخامسة'));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('an admin manages notes too', (tester) async {
    await pumpRecording(tester, session: adminSession);
    expect(
      find.widgetWithText(FilledButton, 'إضافة ملاحظة هنا'),
      findsOneWidget,
    );
    expect(find.byTooltip('حذف الملاحظة'), findsWidgets);
  });

  testWidgets('the student: markers and the centred copy, read-only', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpRecording(tester, session: student);

    expect(
      school.storage.urlRequests.single.$1,
      'recordings/s001/rec-02.play.mp3',
    );
    expect(laneStars(), findsNWidgets(3));
    expect(find.widgetWithText(OutlinedButton, 'التالي'), findsOneWidget);
    expect(find.text('إضافة ملاحظة هنا'), findsNothing);
    expect(find.text('تمت المراجعة'), findsNothing);
    await scrollTo(tester, find.text('راجع الآية الخامسة'));
    expect(find.byTooltip('حذف الملاحظة'), findsNothing);
    expect(find.byTooltip('إضافة نص'), findsNothing);
    expect(find.byTooltip('تعديل'), findsNothing);
    expect(find.text(' · ٠٠:٠٥–٠٠:٠٩'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

extension on Recording {
  /// A copy with [analysis] (null allowed) and [createdAt]: copyWith cannot
  /// clear a field.
  Recording copyWithAnalysis(
    RecordingAnalysis? analysis, {
    required DateTime createdAt,
  }) => Recording(
    id: id,
    studentId: studentId,
    halaqaId: halaqaId,
    teacherId: teacherId,
    uploadedBy: uploadedBy,
    type: type,
    surahNumber: surahNumber,
    ayahFrom: ayahFrom,
    ayahTo: ayahTo,
    storagePath: storagePath,
    durationSec: durationSec,
    recordedAt: recordedAt,
    createdAt: createdAt,
    unreadFeedback: unreadFeedback,
    reviewed: reviewed,
    analysis: analysis,
  );
}
