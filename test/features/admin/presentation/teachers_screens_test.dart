import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/widgets/common/confirm_dialog.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/widgets/credentials_sheet.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/widgets/teacher_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/fake_user_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  late AdminFixture school;
  setUp(() => school = AdminFixture());

  testWidgets('list: name, username, halaqat and the disabled chip', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpAdminApp(tester, school, location: '/admin/teachers');

    expect(find.text('t01\nحلقة الفجر'), findsOneWidget);
    expect(find.text('t03\nبلا حلقة'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(TeacherTile, 'الشيخ سعيد'),
        matching: find.text('موقوف'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long list ends clearly above the add button', (tester) async {
    usePhoneSize(tester);
    for (var i = 10; i < 22; i++) {
      school.users.put(seedUser('t$i', 'معلم رقم $i', UserRole.teacher));
    }
    await pumpAdminApp(tester, school, location: '/admin/teachers');

    final scrollable = find.descendant(
      of: find.byType(ListView).hitTestable().first,
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable.first).position;
    // The extent is an estimate until the end has been laid out once.
    for (var i = 0; i < 5; i++) {
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
    }

    final fab = tester.getRect(find.byType(FloatingActionButton));
    final lastItem = tester.getRect(
      find.widgetWithText(OutlinedButton, 'إضافة مدير'),
    );
    expect(fab.top - lastItem.bottom, greaterThanOrEqualTo(24));
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty: a message and an add button', (tester) async {
    school = AdminFixture.empty();
    await pumpAdminApp(tester, school, location: '/admin/teachers');
    expect(find.text('لا يوجد معلمون بعد'), findsOneWidget);
  });

  testWidgets('add teacher: createUser as teacher, then the sheet', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpAdminApp(tester, school, location: '/admin/teachers/new');
    await tester.enterText(
      find.widgetWithText(TextField, 'الاسم الكامل'),
      'الشيخ أحمد',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'اسم المستخدم'),
      'T04',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'إضافة'));
    await tester.pumpAndSettle();

    final call = school.accounts.createUserCalls.single;
    expect(call['username'], 't04');
    expect(call['role'], UserRole.teacher);
    expect(call['password'], matches(RegExp(r'^[a-z2-9]{8}$')));
    expect(find.byType(CredentialsSheet), findsOneWidget);
    expect(
      CredentialsSheet.messageFor(
        tester
            .widget<CredentialsSheet>(find.byType(CredentialsSheet))
            .credentials,
      ),
      startsWith('السلام عليكم، بيانات دخول المعلم الشيخ أحمد'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('details: halaqat, reset password and disable', (tester) async {
    await pumpAdminApp(tester, school, location: '/admin/teachers/t01');
    expect(find.text('الشيخ محمود'), findsOneWidget);
    expect(find.text('بيانات المعلم'), findsOneWidget);
    expect(find.text('حلقة الفجر'), findsOneWidget);
    expect(find.text('تغيير كلمة السر'), findsOneWidget);

    await tester.tap(find.text('إيقاف الحساب'));
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'إيقاف الحساب'));
    await tester.pumpAndSettle();
    expect(school.accounts.setDisabledCalls.single, ('t01', true));

    // A halaqa opens in the halaqat section.
    await tester.ensureVisible(find.text('حلقة الفجر'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حلقة الفجر'));
    await tester.pumpAndSettle();
    expect(currentPath(tester), '/admin/halaqat/halaqa-fajr');
  });

  testWidgets('no disable action on the admin\'s own account', (tester) async {
    // The session uid is shadi's; an account with that uid in the teachers
    // list must not offer "إيقاف الحساب".
    school.users.put(seedUser('shadi', 'شادي', UserRole.teacher));
    await pumpAdminApp(tester, school, location: '/admin/teachers/shadi');
    expect(find.text('تغيير كلمة السر'), findsOneWidget);
    expect(find.text('إيقاف الحساب'), findsNothing);
  });
}
