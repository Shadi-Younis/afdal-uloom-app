import 'package:afdal_uloom_tilawat/app/app.dart';
import 'package:afdal_uloom_tilawat/core/constants/app_durations.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_type.dart';
import 'package:afdal_uloom_tilawat/core/widgets/common/recording_player.dart';
import 'package:afdal_uloom_tilawat/features/student/presentation/widgets/level_meter.dart';
import 'package:afdal_uloom_tilawat/features/student/presentation/widgets/student_recording_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_audio_file_picker.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/student_fixture.dart';

void main() {
  setUpAll(loadBundledFonts);

  late StudentFixture fixture;
  setUp(() => fixture = StudentFixture());

  /// The student's home, then «سجّل تدريباً» (push: back returns home).
  Future<void> openPractice(WidgetTester tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(overrides: fixture.overrides, child: const AfdalUloomApp()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('سجّل تدريباً'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/student/practice');
  }

  /// Moves the clock on and lets the recorder's timer run once.
  Future<void> wait(WidgetTester tester, Duration duration) async {
    fixture.now = fixture.now.add(duration);
    await tester.pump(AppDurations.recorderTick);
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> chooseFatiha(WidgetTester tester) async {
    await tester.enterText(field('السورة'), '1');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, '١. الفاتحة').last);
    await tester.pumpAndSettle();
    await tester.enterText(field('من آية'), '١');
    await tester.enterText(field('إلى آية'), '7');
    await tester.pumpAndSettle();
  }

  Future<void> tapButton(WidgetTester tester, String text) async {
    final button = find.text(text);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
  }

  Future<void> recordFor(WidgetTester tester, Duration length) async {
    await tester.tap(find.byTooltip('ابدأ التسجيل'));
    await tester.pump();
    await wait(tester, length);
    await tester.tap(find.byTooltip('إنهاء التسجيل'));
    await tester.pumpAndSettle();
  }

  testWidgets('ready: what to recite, the big button, the timer at zero, '
      '«اختيار ملف»', (tester) async {
    await openPractice(tester);
    expect(find.text('تسجيل تدريب'), findsOneWidget);
    expect(find.text('ماذا ستتلو؟'), findsOneWidget);
    expect(field('السورة'), findsOneWidget);
    expect(field('من آية'), findsOneWidget);
    expect(find.text('اضغط الزر وابدأ التلاوة'), findsOneWidget);
    expect(find.text('٠٠:٠٠'), findsOneWidget);
    expect(find.byTooltip('ابدأ التسجيل'), findsOneWidget);
    expect(find.byTooltip('إنهاء التسجيل'), findsNothing);
    expect(find.text('اختيار ملف'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recording: the timer runs, the meter moves, pause and resume, '
      'stop', (tester) async {
    await openPractice(tester);
    await tester.tap(find.byTooltip('ابدأ التسجيل'));
    await tester.pump();
    expect(fixture.recorder.calls, ['permission', 'start']);
    expect(find.text('جارٍ التسجيل'), findsOneWidget);
    expect(find.text('اختيار ملف'), findsNothing);

    await wait(tester, const Duration(seconds: 83));
    expect(find.text('٠١:٢٣'), findsOneWidget);
    fixture.recorder.emitLevel(0.5);
    await tester.pump(AppDurations.recorderTick);
    expect(tester.widget<LevelMeter>(find.byType(LevelMeter)).level, 0.5);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('إيقاف مؤقت'));
    await tester.pump();
    expect(find.text('التسجيل متوقف مؤقتاً'), findsOneWidget);
    await wait(tester, const Duration(minutes: 3));
    expect(find.text('٠١:٢٣'), findsOneWidget);

    await tester.tap(find.byTooltip('متابعة التسجيل'));
    await tester.pump();
    await wait(tester, const Duration(seconds: 2));
    expect(find.text('٠١:٢٥'), findsOneWidget);

    await tester.tap(find.byTooltip('إنهاء التسجيل'));
    await tester.pumpAndSettle();
    expect(find.text('تسجيلك · ٠١:٢٥'), findsOneWidget);
    expect(find.byType(RecordingPlayer), findsOneWidget);
    expect(fixture.school.player.loads.single.$1.scheme, 'file');
    expect(find.text('إعادة التسجيل'), findsOneWidget);
    expect(find.text('حفظ'), findsOneWidget);
    // A practice is the student's own (Task 12).
    expect(find.text('يُحفظ التدريب عندك فقط'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('near 30 minutes: a warning; at 30 it stops by itself', (
    tester,
  ) async {
    await openPractice(tester);
    await tester.tap(find.byTooltip('ابدأ التسجيل'));
    await tester.pump();
    await wait(tester, const Duration(minutes: 25));
    expect(
      find.text('اقترب التسجيل من حدّه (٣٠ دقيقة)، وسيتوقف تلقائياً عنده.'),
      findsOneWidget,
    );
    await wait(tester, const Duration(minutes: 5));
    await tester.pumpAndSettle();
    expect(
      find.text('وصل التسجيل إلى حدّه (٣٠ دقيقة) فتوقف. استمع إليه ثم احفظه.'),
      findsOneWidget,
    );
    expect(find.text('تسجيلك · ٣٠:٠٠'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('microphone refused: the Arabic explanation, «فتح الإعدادات» '
      'and retry', (tester) async {
    fixture.recorder.allowed = false;
    await openPractice(tester);
    await tester.tap(find.byTooltip('ابدأ التسجيل'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('لا يستطيع التطبيق استخدام الميكروفون'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('فتح الإعدادات'));
    await tester.pump();
    expect(fixture.recorder.calls, contains('settings'));

    fixture.recorder.allowed = true;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
    expect(find.text('جارٍ التسجيل'), findsOneWidget);
  });

  testWidgets('«إعادة التسجيل» asks, then throws the take away', (
    tester,
  ) async {
    await openPractice(tester);
    await recordFor(tester, const Duration(seconds: 10));
    await tapButton(tester, 'إعادة التسجيل');
    await tester.pumpAndSettle();
    expect(find.text('سيُحذف هذا التسجيل ولن يُحفظ.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'إعادة التسجيل'));
    await tester.pumpAndSettle();
    expect(fixture.recorder.released, hasLength(1));
    expect(find.text('اضغط الزر وابدأ التلاوة'), findsOneWidget);
  });

  testWidgets('send without the ayat: the page says what is missing', (
    tester,
  ) async {
    await openPractice(tester);
    await recordFor(tester, const Duration(seconds: 10));
    await tapButton(tester, 'حفظ');
    await tester.pumpAndSettle();
    expect(find.text('اختر السورة والآيات أولاً'), findsOneWidget);
    expect(fixture.school.recordings.created, isEmpty);
  });

  testWidgets('send: progress, then home with the practice in the list', (
    tester,
  ) async {
    await openPractice(tester);
    await chooseFatiha(tester);
    await recordFor(tester, const Duration(seconds: 40));
    await tapButton(tester, 'حفظ');
    await tester.pump();
    await tester.pump();
    expect(find.text('جارٍ الحفظ'), findsOneWidget);
    final upload = fixture.school.storage.lastUpload;
    upload.progress(0.5);
    await tester.pump();
    expect(find.text('جارٍ الرفع… ٥٠٪'), findsOneWidget);
    expect(tester.takeException(), isNull);

    upload.complete();
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/student');
    expect(find.text('تم حفظ التدريب'), findsOneWidget);
    final sent = fixture.school.recordings.created.single;
    expect(sent.type, RecordingType.practice);
    expect(sent.durationSec, 40);
    expect(
      find.byWidgetPredicate(
        (w) => w is StudentRecordingCard && w.recording.id == sent.id,
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });

  testWidgets('send fails: the Arabic reason; sending again works', (
    tester,
  ) async {
    await openPractice(tester);
    await chooseFatiha(tester);
    await recordFor(tester, const Duration(seconds: 5));
    await tapButton(tester, 'حفظ');
    await tester.pump();
    await tester.pump();
    fixture.school.storage.lastUpload.fail(
      const AppException(AppErrorCode.network),
    );
    await tester.pumpAndSettle();
    expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
    expect(find.text('تسجيلك · ٠٠:٠٥'), findsOneWidget);

    await tapButton(tester, 'حفظ');
    await tester.pump();
    await tester.pump();
    fixture.school.storage.lastUpload.complete();
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/student');
  });

  testWidgets('cancel while sending: «أُلغي الرفع», the take stays', (
    tester,
  ) async {
    await openPractice(tester);
    await chooseFatiha(tester);
    await recordFor(tester, const Duration(seconds: 5));
    await tapButton(tester, 'حفظ');
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.text('أُلغي الرفع'), findsOneWidget);
    expect(find.text('حفظ'), findsOneWidget);
    expect(
      fixture.school.recordings.recordings.values.where(
        (r) => r.type == RecordingType.practice && r.studentId == 's001',
      ),
      hasLength(1),
    ); // rec-20 only: the cancelled one was deleted
  });

  testWidgets('leaving while recording asks; «إلغاء» stays, «خروج» leaves '
      'and stops the microphone', (tester) async {
    await openPractice(tester);
    await tester.tap(find.byTooltip('ابدأ التسجيل'));
    await tester.pump();
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(find.text('التدريب لم يُحفظ'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/student/practice');

    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'خروج'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/student');
    expect(fixture.recorder.calls.last, 'cancel');
    expect(fixture.school.recordings.created, isEmpty);
  });

  testWidgets('leaving with nothing recorded does not ask', (tester) async {
    await openPractice(tester);
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/student');
  });

  testWidgets('«اختيار ملف»: the file, then «حفظ»', (tester) async {
    await openPractice(tester);
    await chooseFatiha(tester);
    fixture.picker.next = [
      pickedFile('fatiha.m4a', sizeBytes: 3 * 1024 * 1024),
    ];
    await tapButton(tester, 'اختيار ملف');
    await tester.pumpAndSettle();
    expect(find.text('fatiha.m4a'), findsOneWidget);
    expect(find.text('٣٫٠ ميغابايت'), findsOneWidget);
    expect(find.byTooltip('ابدأ التسجيل'), findsNothing);
    expect(tester.takeException(), isNull);

    await tapButton(tester, 'حفظ');
    await tester.pump();
    await tester.pump();
    fixture.school.storage.lastUpload.complete();
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/student');
    expect(fixture.school.recordings.created.single.durationSec, isNull);
  });

  testWidgets('a picked file of another type cannot be sent', (tester) async {
    await openPractice(tester);
    fixture.picker.next = [pickedFile('notes.pdf')];
    await tapButton(tester, 'اختيار ملف');
    await tester.pumpAndSettle();
    expect(
      find.text('نوع الملف غير مدعوم. اختر ملفاً صوتياً.'),
      findsOneWidget,
    );
    final send = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('حفظ'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(send.onPressed, isNull);

    await tapButton(tester, 'إلغاء اختيار الملف');
    await tester.pumpAndSettle();
    expect(find.byTooltip('ابدأ التسجيل'), findsOneWidget);
  });
}
