import 'dart:async';

import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/providers/repository_providers.dart';
import 'package:afdal_uloom_tilawat/core/providers/service_providers.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/app_card.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/surah_cartouche.dart';
import 'package:afdal_uloom_tilawat/features/recordings/presentation/recording_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  late AdminFixture school;
  setUp(() => school = AdminFixture());

  /// RecordingScreen for [id] alone, signed in as [session].
  Future<void> pumpRecording(
    WidgetTester tester,
    String id, {
    AuthSession session = adminSession,
    bool settle = true,
  }) async {
    await pumpScreen(
      tester,
      RecordingScreen(recordingId: id),
      auth: FakeAuthService(initial: session),
      overrides: [
        userRepositoryProvider.overrideWithValue(school.users),
        recordingRepositoryProvider.overrideWithValue(school.recordings),
        feedbackRepositoryProvider.overrideWithValue(school.feedback),
        audioStorageServiceProvider.overrideWithValue(school.storage),
        audioPlayerServiceProvider.overrideWith((ref) => school.player),
      ],
    );
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets('loading: the shared spinner', (tester) async {
    school.recordings.getGate = Completer<void>();
    await pumpRecording(tester, 'rec-02', settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('التسجيل'), findsOneWidget);
    school.recordings.getGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('سورة البقرة'), findsOneWidget);
  });

  testWidgets('everything about the recording, on a phone', (tester) async {
    final semantics = tester.ensureSemantics();
    usePhoneSize(tester);
    await pumpRecording(tester, 'rec-02');

    expect(find.text('تسجيل أحمد الخطيب'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SurahCartouche),
        matching: find.text('سورة البقرة'),
      ),
      findsOneWidget,
    );
    expect(find.text('الآيات ١–٢٠'), findsOneWidget);
    expect(find.text('رسمي'), findsOneWidget);
    expect(find.text('تاريخ التسجيل: ٨ سبتمبر ٢٠٢٦'), findsOneWidget);
    expect(find.text('رُفع بواسطة: الشيخ محمود'), findsOneWidget);
    expect(find.byTooltip('تشغيل'), findsOneWidget);
    expect(find.text('٠٠:٣٠'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('راجع الآية الخامسة'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ملاحظات المعلم'), findsOneWidget);
    expect(find.text('أحسنت، انتبه لمدّ الألف'), findsOneWidget);
    // Notes are cards with the gold bar, signed by the teacher.
    expect(
      find.byWidgetPredicate((w) => w is AppCard && w.accent),
      findsNWidgets(2),
    );
    expect(find.text('الشيخ محمود · ٩ سبتمبر ٢٠٢٦'), findsOneWidget);
    expect(find.text('عند ٠٠:١٢'), findsOneWidget);
    expect(find.bySemanticsLabel('التقييم: ٤ من ٥'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(4));
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('a note\'s "عند ٠٠:١٢" moves the player there', (tester) async {
    await pumpRecording(tester, 'rec-02');
    await tester.scrollUntilVisible(
      find.text('عند ٠٠:١٢'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('عند ٠٠:١٢'));
    await tester.pump();
    expect(school.player.seeks, [const Duration(seconds: 12)]);
    expect(find.text('٠٠:١٢'), findsOneWidget);
  });

  testWidgets('no notes: a message', (tester) async {
    await pumpRecording(tester, 'rec-01');
    expect(find.text('لا توجد ملاحظات بعد'), findsOneWidget);
    expect(find.text('سورة الفاتحة'), findsOneWidget);
    expect(find.text('الآيات ١–٧'), findsOneWidget);
  });

  testWidgets('notes fail to load: Arabic error, the rest still works', (
    tester,
  ) async {
    school.feedback.watchError = const AppException(AppErrorCode.network);
    await pumpRecording(tester, 'rec-02');
    expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
    expect(find.byTooltip('تشغيل'), findsOneWidget);
  });

  testWidgets('another student\'s recording: the permission message', (
    tester,
  ) async {
    school.recordings.getError = const AppException(
      AppErrorCode.permissionDenied,
    );
    await pumpRecording(
      tester,
      'rec-02',
      session: const AuthSession(uid: 's002', role: UserRole.student),
    );
    expect(find.text('ليست لديك صلاحية لهذا الإجراء.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(school.storage.urlRequests, isEmpty);
  });

  testWidgets('an unknown id: not found', (tester) async {
    await pumpRecording(tester, 'nope');
    expect(find.text('العنصر المطلوب غير موجود.'), findsOneWidget);
  });

  testWidgets('the student sees "المعلم" as uploader, their own name for '
      'practice', (tester) async {
    const student = AuthSession(uid: 's001', role: UserRole.student);
    await pumpRecording(tester, 'rec-02', session: student);
    expect(find.text('رُفع بواسطة: المعلم'), findsOneWidget);
    // Their own name in the title; never a teacher's profile.
    expect(find.text('تسجيل أحمد الخطيب'), findsOneWidget);
    expect(find.text('المعلم · ٩ سبتمبر ٢٠٢٦'), findsOneWidget);

    await pumpRecording(tester, 'rec-20', session: student);
    expect(find.text('تدريب'), findsOneWidget);
    expect(find.text('رُفع بواسطة: أحمد الخطيب'), findsOneWidget);
  });

  testWidgets('pumped alone (no router, no parent known): no back button', (
    tester,
  ) async {
    await pumpRecording(tester, 'rec-02');
    expect(find.byTooltip('رجوع'), findsNothing);
  });
}
