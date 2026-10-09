import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/widgets/credentials_sheet.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/widgets/edit_profile_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/fake_user_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  late AdminFixture school;
  setUp(() => school = AdminFixture());

  Finder dialogField(String label) => find.descendant(
    of: find.byType(EditProfileDialog),
    matching: find.widgetWithText(TextField, label),
  );

  group('edit profile', () {
    testWidgets('a student: name, username and code; the page updates', (
      tester,
    ) async {
      usePhoneSize(tester);
      await pumpAdminApp(tester, school, location: '/admin/students/s001');
      await tester.tap(find.text('تعديل البيانات'));
      await tester.pumpAndSettle();

      expect(find.text('تعديل بيانات أحمد الخطيب'), findsOneWidget);
      expect(dialogField('رقم الطالب'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.enterText(dialogField('الاسم الكامل'), 'أحمد خالد الخطيب');
      await tester.enterText(dialogField('اسم المستخدم'), 'ahmed.k');
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();

      expect(school.accounts.updateProfileCalls.single, {
        'uid': 's001',
        'fullName': 'أحمد خالد الخطيب',
        'username': 'ahmed.k',
      });
      expect(find.byType(EditProfileDialog), findsNothing);
      expect(find.text('تم حفظ التعديلات'), findsOneWidget);
      expect(find.text('ahmed.k'), findsOneWidget);
    });

    testWidgets('a taken username stays in the dialog, under the field', (
      tester,
    ) async {
      await pumpAdminApp(tester, school, location: '/admin/teachers/t01');
      await tester.tap(find.text('تعديل البيانات'));
      await tester.pumpAndSettle();
      // A teacher has no code.
      expect(dialogField('رقم الطالب'), findsNothing);

      school.accounts.error = const AppException(AppErrorCode.usernameTaken);
      await tester.enterText(dialogField('اسم المستخدم'), 't02');
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileDialog), findsOneWidget);
      expect(find.text('اسم المستخدم مستخدم من قبل'), findsOneWidget);
    });

    testWidgets('invalid input is refused before the call', (tester) async {
      await pumpAdminApp(tester, school, location: '/admin/students/s002');
      await tester.tap(find.text('تعديل البيانات'));
      await tester.pumpAndSettle();
      await tester.enterText(dialogField('رقم الطالب'), 'X1');
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();

      expect(
        find.text('رقم الطالب حرف S ثم 3 إلى 5 أرقام، مثل S013'),
        findsOneWidget,
      );
      expect(school.accounts.updateProfileCalls, isEmpty);
    });
  });

  group('admins', () {
    testWidgets('listed under the teachers; own page has no disable', (
      tester,
    ) async {
      usePhoneSize(tester);
      await pumpAdminApp(tester, school, location: '/admin/teachers');
      await tester.scrollUntilVisible(
        find.text('شادي'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('المديرون'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('شادي'));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/admin/teachers/admin/shadi');
      expect(find.text('بيانات المدير'), findsOneWidget);
      expect(find.text('تعديل البيانات'), findsOneWidget);
      expect(find.text('إيقاف الحساب'), findsNothing);
      expect(find.textContaining('حذف'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('another admin can be disabled; the last-admin refusal is '
        'explained', (tester) async {
      school.users.put(seedUser('admin2', 'مدير ثان', UserRole.admin));
      school.accounts.error = const AppException(AppErrorCode.lastAdmin);
      await pumpAdminApp(
        tester,
        school,
        location: '/admin/teachers/admin/admin2',
      );
      await tester.tap(find.text('إيقاف الحساب'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'إيقاف الحساب'));
      await tester.pumpAndSettle();

      expect(school.accounts.setDisabledCalls.single, ('admin2', true));
      expect(
        find.text('لا يمكن إيقاف آخر مدير مفعّل. أضف مديراً آخر أولاً.'),
        findsOneWidget,
      );
    });

    testWidgets('"إضافة مدير" from the home: createUser as admin', (
      tester,
    ) async {
      usePhoneSize(tester);
      await pumpAdminApp(tester, school);
      await tester.scrollUntilVisible(
        find.text('إضافة مدير'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('إضافة مدير'));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/admin/teachers/new-admin');
      expect(find.text('مدير جديد'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'الاسم الكامل'),
        'مدير احتياطي',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'اسم المستخدم'),
        'backup',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'إضافة'));
      await tester.pumpAndSettle();

      final call = school.accounts.createUserCalls.single;
      expect(call['role'], UserRole.admin);
      expect(call['username'], 'backup');
      expect(
        CredentialsSheet.messageFor(
          tester
              .widget<CredentialsSheet>(find.byType(CredentialsSheet))
              .credentials,
        ),
        startsWith('السلام عليكم، بيانات دخول المدير مدير احتياطي'),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
