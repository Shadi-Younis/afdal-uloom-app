import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/widgets/common/confirm_dialog.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/widgets/credentials_sheet.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/widgets/student_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  late AdminFixture school;
  setUp(() => school = AdminFixture());

  List<String> listedNames(WidgetTester tester) => [
    for (final tile in tester.widgetList<StudentTile>(find.byType(StudentTile)))
      tile.student.fullName,
  ];

  group('students list', () {
    testWidgets('sorted by code, with halaqa and the disabled chip', (
      tester,
    ) async {
      usePhoneSize(tester);
      await pumpAdminApp(tester, school, location: '/admin/students');

      expect(listedNames(tester), [
        'أحمد الخطيب',
        'عمر الحسن',
        'يوسف النجار',
        'أنس جابر',
      ]);
      expect(find.text('S003 · حلقة العصر'), findsOneWidget);
      expect(
        find.descendant(
          of: find.widgetWithText(StudentTile, 'أنس جابر'),
          matching: find.text('موقوف'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('searching احمد finds أحمد; codes too; no results', (
      tester,
    ) async {
      await pumpAdminApp(tester, school, location: '/admin/students');
      final search = find.widgetWithText(
        TextField,
        'ابحث بالاسم أو رقم الطالب',
      );

      await tester.enterText(search, 'احمد');
      await tester.pump();
      expect(listedNames(tester), ['أحمد الخطيب']);

      await tester.enterText(search, 's003');
      await tester.pump();
      expect(listedNames(tester), ['يوسف النجار']);

      await tester.enterText(search, 'زكريا');
      await tester.pump();
      expect(find.text('لا توجد نتائج'), findsOneWidget);
    });

    testWidgets('halaqa chips filter the list', (tester) async {
      await pumpAdminApp(tester, school, location: '/admin/students');
      await tester.tap(find.widgetWithText(ChoiceChip, 'حلقة العصر'));
      await tester.pump();
      expect(listedNames(tester), ['يوسف النجار']);
      await tester.tap(find.widgetWithText(ChoiceChip, 'الكل'));
      await tester.pump();
      expect(listedNames(tester), hasLength(4));
    });

    testWidgets('empty school: a message and an add button', (tester) async {
      school = AdminFixture.empty();
      await pumpAdminApp(tester, school, location: '/admin/students');
      expect(find.text('لا يوجد طلاب بعد'), findsOneWidget);
    });

    testWidgets('error: the Arabic message', (tester) async {
      school.users.watchError = const AppException(
        AppErrorCode.permissionDenied,
      );
      await pumpAdminApp(tester, school, location: '/admin/students');
      expect(find.text('ليست لديك صلاحية لهذا الإجراء.'), findsWidgets);
    });
  });

  group('student details', () {
    testWidgets('account info, actions and the recordings placeholder', (
      tester,
    ) async {
      usePhoneSize(tester);
      await pumpAdminApp(tester, school, location: '/admin/students/s001');

      expect(find.text('S001'), findsOneWidget);
      expect(find.text('s001'), findsOneWidget);
      expect(find.text('حلقة الفجر'), findsOneWidget);
      expect(find.text('مفعّل'), findsOneWidget);
      expect(find.text('تغيير كلمة السر'), findsOneWidget);
      expect(find.text('نقل إلى حلقة أخرى'), findsOneWidget);
      expect(find.text('إيقاف الحساب'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('التسجيلات'), 100);
      expect(
        find.text('ستظهر هنا تسجيلات الطالب في تحديث قادم.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('move: pick a halaqa, the confirmation mentions recordings', (
      tester,
    ) async {
      await pumpAdminApp(tester, school, location: '/admin/students/s001');
      await tester.tap(find.text('نقل إلى حلقة أخرى'));
      await tester.pumpAndSettle();
      expect(find.text('اختر الحلقة الجديدة'), findsOneWidget);
      await tester.tap(find.text('حلقة العصر'));
      await tester.pumpAndSettle();

      final dialog = tester.widget<ConfirmDialog>(find.byType(ConfirmDialog));
      expect(dialog.title, 'نقل الطالب');
      expect(dialog.message, contains('من حلقة الفجر إلى حلقة العصر'));
      expect(dialog.message, contains('كل تسجيلاته ستنتقل معه'));

      await tester.tap(find.widgetWithText(FilledButton, 'نقل الطالب'));
      await tester.pumpAndSettle();
      expect(school.accounts.moveStudentCalls.single, ('s001', 'halaqa-asr'));
      expect(find.text('تم نقل الطالب'), findsOneWidget);
      expect(find.text('حلقة العصر'), findsOneWidget);
    });

    testWidgets('disable after confirming: the chip appears; enable again', (
      tester,
    ) async {
      await pumpAdminApp(tester, school, location: '/admin/students/s002');
      await tester.tap(find.text('إيقاف الحساب'));
      await tester.pumpAndSettle();
      final dialog = tester.widget<ConfirmDialog>(find.byType(ConfirmDialog));
      expect(dialog.message, contains('لن يستطيع عمر الحسن تسجيل الدخول'));
      expect(dialog.message, contains('لن تُحذف أي بيانات'));

      await tester.tap(find.widgetWithText(FilledButton, 'إيقاف الحساب'));
      await tester.pumpAndSettle();
      expect(school.accounts.setDisabledCalls.single, ('s002', true));
      expect(find.text('تم إيقاف الحساب'), findsOneWidget);
      expect(find.text('موقوف'), findsWidgets);
      expect(find.text('إعادة تفعيل الحساب'), findsOneWidget);

      await tester.tap(find.text('إعادة تفعيل الحساب'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'إعادة تفعيل الحساب'));
      await tester.pumpAndSettle();
      expect(school.accounts.setDisabledCalls.last, ('s002', false));
      expect(find.text('مفعّل'), findsOneWidget);
    });

    testWidgets('reset password: generated, editable, then the sheet', (
      tester,
    ) async {
      await pumpAdminApp(tester, school, location: '/admin/students/s003');
      await tester.tap(find.text('تغيير كلمة السر'));
      await tester.pumpAndSettle();

      final input = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      expect(
        tester.widget<TextField>(input).controller!.text,
        matches(RegExp(r'^[a-z2-9]{8}$')),
      );
      await tester.enterText(input, '123');
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();
      expect(find.text('كلمة السر من 6 إلى 64 حرفاً'), findsOneWidget);

      await tester.enterText(input, 'n3wpass22');
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();
      expect(school.accounts.resetPasswordCalls.single, ('s003', 'n3wpass22'));
      expect(find.byType(CredentialsSheet), findsOneWidget);
      expect(find.text('n3wpass22'), findsOneWidget);
    });

    testWidgets('a failed move shows the Arabic error', (tester) async {
      school.accounts.error = const AppException(AppErrorCode.network);
      await pumpAdminApp(tester, school, location: '/admin/students/s001');
      await tester.tap(find.text('نقل إلى حلقة أخرى'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حلقة العصر'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'نقل الطالب'));
      await tester.pumpAndSettle();
      expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
      expect(find.text('حلقة الفجر'), findsOneWidget);
    });
  });
}
