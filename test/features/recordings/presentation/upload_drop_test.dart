import 'dart:io';

import 'package:afdal_uloom_tilawat/app/app.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/stem_role.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/providers/clock_provider.dart';
import 'package:afdal_uloom_tilawat/core/providers/service_providers.dart';
import 'package:afdal_uloom_tilawat/features/recordings/presentation/widgets/stem_zone.dart';
import 'package:afdal_uloom_tilawat/features/recordings/presentation/widgets/upload_drop_area.dart';
import 'package:afdal_uloom_tilawat/features/recordings/presentation/widgets/upload_row_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/fake_audio_file_picker.dart';
import '../../../helpers/pump_app.dart';

/// Dropping files on the upload page, as the studio PC's browser does,
/// through desktop_drop's channel: on the page they become new rows; on a
/// row in two-file mode they fill its zones instead.
void main() {
  setUpAll(loadBundledFonts);

  late AdminFixture school;
  late FakeAudioFilePicker picker;
  late Directory folder;

  setUp(() {
    school = AdminFixture();
    picker = FakeAudioFilePicker();
    folder = Directory.systemTemp.createTempSync('upload_drop_test');
    UploadDropArea.debugSupported = true;
  });

  tearDown(() {
    UploadDropArea.debugSupported = null;
    folder.deleteSync(recursive: true);
  });

  Future<void> pumpUpload(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1280, 1400)
      // desktop_drop scales its points by the pixel ratio on Windows.
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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

  /// What the browser reports while files are dragged to [at] and dropped.
  Future<void> drop(WidgetTester tester, Offset at, List<String> names) async {
    final paths = [
      for (final name in names)
        (File(
          '${folder.path}${Platform.pathSeparator}$name',
        )..writeAsBytesSync([1, 2, 3, 4])).path,
    ];
    Future<void> send(String method, Object arguments) =>
        tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'desktop_drop',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall(method, arguments),
          ),
          (_) {},
        );
    await send('entered', [at.dx, at.dy]);
    await send('updated', [at.dx, at.dy]);
    await tester.pump();
    // The dropped files are read from disk: real time, not the test's.
    await tester.runAsync(() async {
      await send('performOperation', paths);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
  }

  Finder zone(StemRole role) =>
      find.byWidgetPredicate((w) => w is StemZone && w.role == role);

  testWidgets('on the page: a row per file', (tester) async {
    await pumpUpload(tester);
    await drop(tester, tester.getCenter(find.text('اختيار ملفات')), [
      'S001_001_1-7.mp3',
      'S002_001_1-7.mp3',
    ]);
    expect(find.byType(UploadRowCard), findsNWidgets(2));
  });

  testWidgets('on a two-file row: both zones, no new row', (tester) async {
    await pumpUpload(tester);
    picker.next = [pickedFile('Mixdown.wav')];
    await tester.tap(find.text('اختيار ملفات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ملفين: الطالب + الشيخ'));
    await tester.pumpAndSettle();

    await drop(tester, tester.getCenter(find.byType(UploadRowCard)), [
      'S001_001_1-7 - Sheikh.wav',
      'S001_001_1-7 - Student.wav',
    ]);
    expect(find.byType(UploadRowCard), findsOneWidget);
    expect(
      find.descendant(
        of: zone(StemRole.student),
        matching: find.text('S001_001_1-7 - Student.wav'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: zone(StemRole.sheikh),
        matching: find.text('S001_001_1-7 - Sheikh.wav'),
      ),
      findsOneWidget,
    );
    // Their names filled in the student.
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'الطالب'))
          .controller!
          .text,
      'أحمد الخطيب · S001 · حلقة الفجر',
    );
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'السورة'))
          .controller!
          .text,
      '١. الفاتحة',
    );

    // One file on a zone goes into that zone, whatever its name.
    await drop(tester, tester.getCenter(zone(StemRole.sheikh)), [
      'take - student.wav',
    ]);
    expect(
      find.descendant(
        of: zone(StemRole.sheikh),
        matching: find.text('take - student.wav'),
      ),
      findsOneWidget,
    );
    expect(find.byType(UploadRowCard), findsOneWidget);

    // Outside the row it is the page's again.
    await drop(tester, tester.getCenter(find.text('اختيار ملفات')), [
      'S002_001_1-7.mp3',
    ]);
    expect(find.byType(UploadRowCard), findsNWidgets(2));
  });
}
