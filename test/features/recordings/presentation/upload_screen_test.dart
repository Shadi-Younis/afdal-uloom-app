import 'package:afdal_uloom_tilawat/app/app.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/providers/clock_provider.dart';
import 'package:afdal_uloom_tilawat/core/providers/service_providers.dart';
import 'package:afdal_uloom_tilawat/features/recordings/presentation/widgets/upload_row_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/fake_audio_file_picker.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  const teacher = AuthSession(uid: 't01', role: UserRole.teacher);

  late AdminFixture school;
  late FakeAudioFilePicker picker;

  setUp(() {
    school = AdminFixture();
    picker = FakeAudioFilePicker();
  });

  Future<void> pumpUpload(
    WidgetTester tester, {
    AuthSession session = teacher,
    String location = '/teacher/upload',
  }) async {
    school.auth.emit(session);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...school.overrides,
          audioFilePickerProvider.overrideWithValue(picker),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 11, 12)),
        ],
        child: const AfdalUloomApp(),
      ),
    );
    await tester.pumpAndSettle();
    currentRouter(tester).go(location);
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, List<String> names) async {
    picker.next = [for (final name in names) pickedFile(name)];
    await tester.tap(find.text('اختيار ملفات'));
    await tester.pumpAndSettle();
  }

  Finder card(String fileName) => find.ancestor(
    of: find.text(fileName),
    matching: find.byType(UploadRowCard),
  );

  Finder fieldIn(String fileName, String label) => find.descendant(
    of: card(fileName),
    matching: find.widgetWithText(TextField, label),
  );

  String textOf(WidgetTester tester, Finder field) =>
      tester.widget<TextField>(field).controller!.text;

  Future<void> choose(
    WidgetTester tester,
    Finder field,
    String typed,
    String option,
  ) async {
    await tester.ensureVisible(field);
    await tester.enterText(field, typed);
    await tester.pumpAndSettle();
    // The option in the list, not the same text in another file's field.
    await tester.tap(find.widgetWithText(InkWell, option).last);
    await tester.pumpAndSettle();
  }

  Finder uploadAll() => find.widgetWithText(FilledButton, 'رفع الكل');

  /// The studio PC with room for three files without scrolling.
  void useTallWideSize(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1280, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// While files upload, «رفع الكل» spins: pumpAndSettle would never end.
  Future<void> settleWhileUploading(WidgetTester tester) =>
      tester.pump(const Duration(milliseconds: 500));

  testWidgets('three files: names fill in, one by hand, upload all', (
    tester,
  ) async {
    useTallWideSize(tester);
    await pumpUpload(tester);
    await pick(tester, [
      'S001_001_001-007.mp3',
      'Mixdown.mp3',
      'S002_112_1-4.mp3',
    ]);

    expect(find.byType(UploadRowCard), findsNWidgets(3));
    expect(
      textOf(tester, fieldIn('S001_001_001-007.mp3', 'الطالب')),
      'أحمد الخطيب · S001 · حلقة الفجر',
    );
    expect(
      textOf(tester, fieldIn('S001_001_001-007.mp3', 'السورة')),
      '١. الفاتحة',
    );
    expect(textOf(tester, fieldIn('Mixdown.mp3', 'الطالب')), isEmpty);
    expect(find.text('أكمل بيانات هذا الملف'), findsOneWidget);

    await choose(
      tester,
      fieldIn('Mixdown.mp3', 'الطالب'),
      'عمر',
      'عمر الحسن · S002 · حلقة الفجر',
    );
    await choose(tester, fieldIn('Mixdown.mp3', 'السورة'), '67', '٦٧. الملك');
    await tester.enterText(fieldIn('Mixdown.mp3', 'من آية'), '١');
    await tester.enterText(fieldIn('Mixdown.mp3', 'إلى آية'), '2');
    await tester.pumpAndSettle();
    expect(find.text('أكمل بيانات هذا الملف'), findsNothing);

    await tester.tap(uploadAll());
    await tester.pump();
    expect(find.text('جارٍ الرفع… ٠٪'), findsOneWidget);
    expect(find.text('في الانتظار'), findsNWidgets(2));

    school.storage.lastUpload.progress(0.45);
    await tester.pump();
    expect(find.text('جارٍ الرفع… ٤٥٪'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      school.storage.lastUpload.complete();
      await settleWhileUploading(tester);
    }
    await tester.pumpAndSettle();
    expect(find.text('تم الرفع'), findsNWidgets(3));
    expect(find.text('تم رفع ٣ من ٣'), findsOneWidget);
    expect(tester.widget<FilledButton>(uploadAll()).onPressed, isNull);

    final created = school.recordings.created;
    expect(created.map((r) => r.studentId), ['s001', 's002', 's002']);
    expect(created.map((r) => r.surahNumber), [1, 67, 112]);
    expect((created[1].ayahFrom, created[1].ayahTo), (1, 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('wrong ayat for the surah: an error, cannot start', (
    tester,
  ) async {
    useWideSize(tester);
    await pumpUpload(tester);
    await pick(tester, ['S001_001_1-7.mp3']);
    await tester.enterText(fieldIn('S001_001_1-7.mp3', 'إلى آية'), '9');
    await tester.pumpAndSettle();
    expect(find.text('الآيات ليست في هذه السورة'), findsOneWidget);
    expect(tester.widget<FilledButton>(uploadAll()).onPressed, isNull);
  });

  testWidgets('a failure shows why; retry uploads it', (tester) async {
    useWideSize(tester);
    await pumpUpload(tester);
    await pick(tester, ['S001_001_1-7.mp3']);
    await tester.tap(uploadAll());
    await tester.pump();
    school.storage.lastUpload.fail(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.text('حدث خطأ غير متوقع. حاول مرة أخرى.'), findsOneWidget);

    await tester.tap(find.byTooltip('إعادة المحاولة'));
    await tester.pump();
    school.storage.lastUpload.complete();
    await tester.pumpAndSettle();
    expect(find.text('تم الرفع'), findsOneWidget);
    expect(find.byTooltip('فتح التسجيل'), findsOneWidget);
  });

  testWidgets('leaving while uploading asks first', (tester) async {
    useWideSize(tester);
    await pumpUpload(tester);
    await pick(tester, ['S001_001_1-7.mp3']);
    await tester.tap(uploadAll());
    await tester.pump();

    await tester.tap(find.byTooltip('رجوع'));
    await settleWhileUploading(tester);
    expect(find.text('الرفع لم ينتهِ'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await settleWhileUploading(tester);
    expect(find.text('الرفع لم ينتهِ'), findsNothing);
    expect(currentPath(tester), '/teacher/upload');

    await tester.tap(find.byTooltip('رجوع'));
    await settleWhileUploading(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'خروج'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/teacher');
  });

  testWidgets('not uploading: back leaves at once', (tester) async {
    await pumpUpload(tester);
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(find.text('الرفع لم ينتهِ'), findsNothing);
    expect(currentPath(tester), '/teacher');
  });

  testWidgets('opened for a student: files without a code are theirs', (
    tester,
  ) async {
    useWideSize(tester);
    await pumpUpload(tester, location: '/teacher/upload?student=s002');
    await pick(tester, ['Mixdown.mp3']);
    expect(
      textOf(tester, fieldIn('Mixdown.mp3', 'الطالب')),
      'عمر الحسن · S002 · حلقة الفجر',
    );
  });

  testWidgets('the admin uploads for any halaqa\'s student', (tester) async {
    useWideSize(tester);
    await pumpUpload(
      tester,
      session: adminSession,
      location: '/admin/upload?student=s003',
    );
    await pick(tester, ['Mixdown.mp3', 'S003_1_1-7.mp3']);
    expect(
      textOf(tester, fieldIn('Mixdown.mp3', 'الطالب')),
      'يوسف النجار · S003 · حلقة العصر',
    );
    expect(
      textOf(tester, fieldIn('S003_1_1-7.mp3', 'الطالب')),
      'يوسف النجار · S003 · حلقة العصر',
    );
  });

  testWidgets('a teacher\'s list has only his students', (tester) async {
    useWideSize(tester);
    await pumpUpload(tester);
    await pick(tester, ['S003_1_1-7.mp3']);
    expect(textOf(tester, fieldIn('S003_1_1-7.mp3', 'الطالب')), isEmpty);
    await tester.enterText(fieldIn('S003_1_1-7.mp3', 'الطالب'), 'يوسف');
    await tester.pumpAndSettle();
    expect(find.textContaining('يوسف النجار'), findsNothing);
  });

  testWidgets('files that cannot upload say why', (tester) async {
    await pumpUpload(tester);
    picker.next = [
      pickedFile('notes.txt'),
      pickedFile('long.mp3', sizeBytes: 200 * 1024 * 1024),
    ];
    await tester.tap(find.text('اختيار ملفات'));
    await tester.pumpAndSettle();
    expect(
      find.text('نوع الملف غير مدعوم. اختر ملفاً صوتياً.'),
      findsOneWidget,
    );
    expect(find.text('الملف أكبر من ١٠٠ ميغابايت.'), findsOneWidget);
  });

  testWidgets('fits a 360x640 phone with files', (tester) async {
    usePhoneSize(tester);
    await pumpUpload(tester);
    await pick(tester, ['S001_001_001-007.mp3', 'Mixdown.mp3']);
    await tester.scrollUntilVisible(
      find.text('Mixdown.mp3'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });
}
