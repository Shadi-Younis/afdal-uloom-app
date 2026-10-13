import 'package:afdal_uloom_tilawat/app/app.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/recording_source.dart';
import 'package:afdal_uloom_tilawat/core/models/stem_role.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/providers/clock_provider.dart';
import 'package:afdal_uloom_tilawat/core/providers/service_providers.dart';
import 'package:afdal_uloom_tilawat/features/recordings/presentation/widgets/stem_zone.dart';
import 'package:afdal_uloom_tilawat/features/recordings/presentation/widgets/upload_row_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/fake_audio_file_picker.dart';
import '../../../helpers/pump_app.dart';

/// The upload page's two-file mode («ملفين: الطالب + الشيخ», Task 11).
void main() {
  setUpAll(loadBundledFonts);

  late AdminFixture school;
  late FakeAudioFilePicker picker;

  setUp(() {
    school = AdminFixture();
    picker = FakeAudioFilePicker();
  });

  Future<void> pumpUpload(WidgetTester tester) async {
    school.auth.emit(const AuthSession(uid: 't01', role: UserRole.teacher));
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
    currentRouter(tester).go('/teacher/upload');
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, List<String> names) async {
    picker.next = [for (final name in names) pickedFile(name)];
    await tester.tap(find.text('اختيار ملفات'));
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder zone(StemRole role) =>
      find.byWidgetPredicate((w) => w is StemZone && w.role == role);

  Finder inZone(StemRole role, Finder finder) =>
      find.descendant(of: zone(role), matching: finder);

  Future<void> twoFiles(WidgetTester tester) =>
      tapVisible(tester, find.text('ملفين: الطالب + الشيخ'));

  Future<void> pickFor(WidgetTester tester, StemRole role, String name) async {
    picker.next = [pickedFile(name)];
    await tapVisible(tester, inZone(role, find.text('اختيار ملف')));
  }

  Finder uploadAll() => find.widgetWithText(FilledButton, 'رفع الكل');

  void useWideSize(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1280, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('one file by default; two files shows a zone for each', (
    tester,
  ) async {
    useWideSize(tester);
    await pumpUpload(tester);
    await pick(tester, ['S001_001_001-007 - Student.wav']);

    final choice = tester.widget<SegmentedButton<RecordingSource>>(
      find.byType(SegmentedButton<RecordingSource>),
    );
    expect(choice.selected, {RecordingSource.stereo});
    expect(find.text('ملف واحد (يسار/يمين)'), findsOneWidget);
    expect(find.byType(StemZone), findsNothing);

    await twoFiles(tester);
    expect(find.text('صوت الطالب'), findsOneWidget);
    expect(find.text('صوت الشيخ'), findsOneWidget);
    // Its name says student.
    expect(
      inZone(StemRole.student, find.text('S001_001_001-007 - Student.wav')),
      findsOneWidget,
    );
    expect(inZone(StemRole.sheikh, find.text('لم يُختر ملف بعد')), findsOne);
    expect(find.text('أضف صوت الطالب وصوت الشيخ'), findsOneWidget);
    expect(tester.widget<FilledButton>(uploadAll()).onPressed, isNull);
  });

  testWidgets('pick the sheikh file, see both lengths, «تبديل» swaps', (
    tester,
  ) async {
    useWideSize(tester);
    school.durations.byName
      ..['S001_001_001-007.wav'] = const Duration(seconds: 61)
      ..['sheikh.wav'] = const Duration(milliseconds: 61400);
    await pumpUpload(tester);
    await pick(tester, ['S001_001_001-007.wav']);
    await twoFiles(tester);
    await pickFor(tester, StemRole.sheikh, 'sheikh.wav');

    expect(inZone(StemRole.sheikh, find.text('sheikh.wav')), findsOneWidget);
    // Size · length, in Arabic digits.
    expect(
      inZone(StemRole.student, find.text('٠٫٠ ميغابايت · ٠١:٠١')),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(uploadAll()).onPressed, isNotNull);

    await tapVisible(tester, find.text('تبديل'));
    expect(inZone(StemRole.student, find.text('sheikh.wav')), findsOneWidget);
    expect(
      inZone(StemRole.sheikh, find.text('S001_001_001-007.wav')),
      findsOneWidget,
    );
  });

  testWidgets('lengths over a second apart: the message, no upload', (
    tester,
  ) async {
    useWideSize(tester);
    school.durations.byName
      ..['S001_001_001-007.wav'] = const Duration(seconds: 61)
      ..['other.wav'] = const Duration(seconds: 75);
    await pumpUpload(tester);
    await pick(tester, ['S001_001_001-007.wav']);
    await twoFiles(tester);
    await pickFor(tester, StemRole.sheikh, 'other.wav');

    expect(
      find.text('مدة الملفين غير متساوية، تأكد أنهما من نفس التسجيل'),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(uploadAll()).onPressed, isNull);
  });

  testWidgets('uploading two files shows the progress of each', (tester) async {
    useWideSize(tester);
    await pumpUpload(tester);
    await pick(tester, ['S001_001_001-007 - student.wav']);
    await twoFiles(tester);
    await pickFor(tester, StemRole.sheikh, 'S001_001_001-007 - sheikh.wav');

    await tester.tap(uploadAll());
    await tester.pump(const Duration(milliseconds: 500));
    final [student, sheikh] = school.storage.uploads;
    student.progress(0.5);
    sheikh.progress(0.25);
    await tester.pump(const Duration(milliseconds: 500));

    final card = find.byType(UploadRowCard);
    expect(
      find.descendant(of: card, matching: find.byType(LinearProgressIndicator)),
      findsNWidgets(2),
    );
    expect(find.text('صوت الطالب: ٥٠٪'), findsOneWidget);
    expect(find.text('صوت الشيخ: ٢٥٪'), findsOneWidget);
    // Nothing can change while it uploads.
    expect(
      tester
          .widget<TextButton>(
            find.descendant(
              of: zone(StemRole.sheikh),
              matching: find.byType(TextButton),
            ),
          )
          .onPressed,
      isNull,
    );

    student.complete();
    sheikh.complete();
    await tester.pumpAndSettle();
    expect(find.text('تم الرفع'), findsOneWidget);
  });

  testWidgets('fits a 360x640 phone in two-file mode', (tester) async {
    usePhoneSize(tester);
    school.durations.byName['S001_001_001-007 - Student.wav'] = const Duration(
      minutes: 14,
      seconds: 11,
    );
    await pumpUpload(tester);
    await pick(tester, ['S001_001_001-007 - Student.wav']);
    await twoFiles(tester);
    await pickFor(tester, StemRole.sheikh, 'S001_001_001-007 - Sheikh.wav');
    await tester.scrollUntilVisible(
      find.text('تبديل'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });
}
