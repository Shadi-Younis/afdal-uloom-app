import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/widgets/credentials_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  late AdminFixture school;
  setUp(() => school = AdminFixture());

  Finder field(String label) => find.widgetWithText(TextField, label);
  String textOf(WidgetTester tester, String label) =>
      tester.widget<TextField>(field(label)).controller!.text;
  final submit = find.widgetWithText(FilledButton, 'إضافة');

  Future<void> chooseHalaqa(WidgetTester tester, String name) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  testWidgets('prefills the next code, its username and a password', (
    tester,
  ) async {
    usePhoneSize(tester);
    await pumpAdminApp(tester, school, location: '/admin/students/new');

    // S001, S002, S003 and the disabled S012 exist.
    expect(textOf(tester, 'رقم الطالب'), 'S013');
    expect(textOf(tester, 'اسم المستخدم'), 's013');
    final password = textOf(tester, 'كلمة السر');
    expect(password, matches(RegExp(r'^[a-z2-9]{8}$')));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('توليد كلمة سر جديدة'));
    await tester.pump();
    expect(textOf(tester, 'كلمة السر'), isNot(password));
  });

  testWidgets('the username follows the code until it is edited', (
    tester,
  ) async {
    await pumpAdminApp(tester, school, location: '/admin/students/new');

    await tester.enterText(field('رقم الطالب'), 'S020');
    expect(textOf(tester, 'اسم المستخدم'), 's020');

    await tester.enterText(field('اسم المستخدم'), 'zaid.q');
    await tester.enterText(field('رقم الطالب'), 'S021');
    expect(textOf(tester, 'اسم المستخدم'), 'zaid.q');
  });

  testWidgets('Arabic validation errors, no call', (tester) async {
    usePhoneSize(tester);
    await pumpAdminApp(tester, school, location: '/admin/students/new');

    await tester.enterText(field('رقم الطالب'), 'X1');
    await tester.enterText(field('اسم المستخدم'), 'زيد');
    await tester.enterText(field('كلمة السر'), '123');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('أدخل الاسم الكامل'), findsOneWidget);
    expect(find.text('اختر الحلقة'), findsOneWidget);
    expect(
      find.text('رقم الطالب حرف S ثم 3 إلى 5 أرقام، مثل S013'),
      findsOneWidget,
    );
    expect(
      find.text('استخدم أحرفاً إنجليزية صغيرة وأرقاماً و . _ - فقط'),
      findsOneWidget,
    );
    expect(find.text('كلمة السر من 6 إلى 64 حرفاً'), findsOneWidget);
    expect(school.accounts.createUserCalls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('success: the credentials sheet, copy, then back', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    usePhoneSize(tester);
    await pumpAdminApp(tester, school, location: '/admin/students');
    await tester.tap(find.text('إضافة طالب'));
    await tester.pumpAndSettle();

    await tester.enterText(field('الاسم الكامل'), 'أحمد زيد');
    await chooseHalaqa(tester, 'حلقة العصر');
    await tester.enterText(field('كلمة السر'), 'k7m2xq4p');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(school.accounts.createUserCalls.single, {
      'username': 's013',
      'password': 'k7m2xq4p',
      'fullName': 'أحمد زيد',
      'role': UserRole.student,
      'halaqaId': 'halaqa-asr',
      'studentCode': 'S013',
    });
    expect(find.byType(CredentialsSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CredentialsSheet),
        matching: find.text('k7m2xq4p'),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'لن تظهر كلمة السر مرة أخرى. انسخها الآن وأرسلها لصاحب الحساب.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('نسخ'));
    await tester.pumpAndSettle();
    expect(
      copied,
      'السلام عليكم، بيانات دخول الطالب أحمد زيد إلى تطبيق دار أفضل العلوم:\n'
      'اسم المستخدم: s013\n'
      'كلمة السر: k7m2xq4p',
    );
    expect(find.text('تم النسخ'), findsOneWidget);

    // A tap outside does not close it; "تم" does, back to the list.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(CredentialsSheet), findsOneWidget);
    await tester.tap(find.text('تم'));
    await tester.pumpAndSettle();
    expect(find.byType(CredentialsSheet), findsNothing);
    expect(currentPath(tester), '/admin/students');
    expect(find.text('أحمد زيد'), findsOneWidget);
  });

  for (final (code, field, message) in [
    (AppErrorCode.usernameTaken, 'اسم المستخدم', 'اسم المستخدم مستخدم من قبل'),
    (AppErrorCode.studentCodeTaken, 'رقم الطالب', 'رقم الطالب مستخدم من قبل'),
  ]) {
    testWidgets('${code.name}: the error under $field', (tester) async {
      school.accounts.error = AppException(code);
      await pumpAdminApp(tester, school, location: '/admin/students/new');
      await tester.enterText(
        find.widgetWithText(TextField, 'الاسم الكامل'),
        'زيد',
      );
      await chooseHalaqa(tester, 'حلقة الفجر');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      final input = tester.widget<TextField>(
        find.widgetWithText(TextField, field),
      );
      expect(input.decoration?.errorText, message);
      expect(find.byType(CredentialsSheet), findsNothing);
    });
  }

  for (final (code, message) in [
    (AppErrorCode.network, 'لا يوجد اتصال بالإنترنت'),
    (AppErrorCode.invalidData, 'البيانات غير صحيحة.'),
  ]) {
    testWidgets('${code.name}: the Arabic error under the form', (
      tester,
    ) async {
      school.accounts.error = AppException(code);
      await pumpAdminApp(tester, school, location: '/admin/students/new');
      await tester.enterText(
        find.widgetWithText(TextField, 'الاسم الكامل'),
        'زيد',
      );
      await chooseHalaqa(tester, 'حلقة الفجر');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
    });
  }

  testWidgets('no halaqa yet: a message and create-halaqa button', (
    tester,
  ) async {
    school = AdminFixture.empty();
    await pumpAdminApp(tester, school, location: '/admin/students/new');
    expect(find.text('أنشئ حلقة أولاً لتضيف إليها الطلاب'), findsOneWidget);
    expect(find.text('إنشاء حلقة'), findsOneWidget);
  });
}
