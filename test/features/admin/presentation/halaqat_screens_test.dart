import 'dart:async';

import 'package:afdal_uloom_tilawat/app/app.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/widgets/common/confirm_dialog.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/empty_state.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/loading_state.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/add_student_screen.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/halaqat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  late AdminFixture school;
  setUp(() => school = AdminFixture());

  group('halaqat list', () {
    testWidgets('data: name, teacher and active student count', (tester) async {
      usePhoneSize(tester);
      await pumpAdminApp(tester, school, location: '/admin/halaqat');

      expect(find.text('حلقة الفجر'), findsOneWidget);
      // s012 in الفجر is disabled: 2 active of 3.
      expect(find.text('المعلم: الشيخ محمود\nعدد الطلاب: ٢'), findsOneWidget);
      expect(
        find.text('المعلم: الشيخ عبد الرحمن\nعدد الطلاب: ١'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('حلقة الفجر'));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/admin/halaqat/halaqa-fajr');
    });

    testWidgets('empty: a message and a create button', (tester) async {
      school = AdminFixture.empty();
      await pumpAdminApp(tester, school, location: '/admin/halaqat');

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('لا توجد حلقات بعد'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.text('إنشاء حلقة'),
        ),
      );
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/admin/halaqat/new');
    });

    testWidgets('error: the Arabic message and a retry button', (tester) async {
      school.halaqat.watchError = const AppException(AppErrorCode.network);
      await pumpAdminApp(tester, school, location: '/admin/halaqat');

      expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);

      school.halaqat.watchError = null;
      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pumpAndSettle();
      expect(find.text('حلقة الفجر'), findsOneWidget);
    });

    testWidgets('loading: the shared spinner', (tester) async {
      school.halaqat.watchGate = Completer();
      await tester.pumpWidget(
        ProviderScope(
          overrides: school.overrides,
          child: const AfdalUloomApp(),
        ),
      );
      await tester.pump();
      currentRouter(tester).go('/admin/halaqat');
      await tester.pump();
      await tester.pump();
      expect(find.byType(HalaqatScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HalaqatScreen),
          matching: find.byType(LoadingState),
        ),
        findsOneWidget,
      );

      school.halaqat.watchGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('حلقة الفجر'), findsOneWidget);
    });

    testWidgets('a new halaqa from the repository appears live', (
      tester,
    ) async {
      await pumpAdminApp(tester, school, location: '/admin/halaqat');
      await school.halaqat.create(name: 'حلقة العشاء', teacherId: 't02');
      await tester.pumpAndSettle();
      expect(find.text('حلقة العشاء'), findsOneWidget);
    });
  });

  group('create halaqa', () {
    Finder nameField() => find.widgetWithText(TextField, 'اسم الحلقة');

    testWidgets('Arabic errors, only active teachers to choose', (
      tester,
    ) async {
      usePhoneSize(tester);
      await pumpAdminApp(tester, school, location: '/admin/halaqat/new');

      await tester.tap(find.widgetWithText(FilledButton, 'إنشاء'));
      await tester.pumpAndSettle();
      expect(find.text('أدخل اسم الحلقة'), findsOneWidget);
      expect(find.text('اختر المعلم'), findsOneWidget);
      expect(school.halaqat.createCalls, isEmpty);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('الشيخ محمود'), findsWidgets);
      expect(find.text('الشيخ سعيد'), findsNothing); // disabled
      expect(tester.takeException(), isNull);
    });

    testWidgets('success opens the new halaqa', (tester) async {
      await pumpAdminApp(tester, school, location: '/admin/halaqat/new');

      await tester.enterText(nameField(), 'حلقة الضحى');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الشيخ عبد الرحمن').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'إنشاء'));
      await tester.pumpAndSettle();

      expect(school.halaqat.createCalls.single, ('حلقة الضحى', 't02'));
      expect(find.text('تم إنشاء الحلقة'), findsOneWidget);
      expect(currentPath(tester), '/admin/halaqat/halaqa-new-1');
      expect(find.text('لا يوجد طلاب في هذه الحلقة بعد'), findsOneWidget);
    });

    testWidgets('no active teacher: a message and add-teacher button', (
      tester,
    ) async {
      school = AdminFixture.empty();
      await pumpAdminApp(tester, school, location: '/admin/halaqat/new');
      expect(
        find.text('لا يوجد معلم مفعّل. أضف معلماً أولاً.'),
        findsOneWidget,
      );
      expect(find.text('إضافة معلم'), findsOneWidget);
    });
  });

  group('halaqa details', () {
    testWidgets('name, teacher, students; tap opens the student', (
      tester,
    ) async {
      usePhoneSize(tester);
      await pumpAdminApp(
        tester,
        school,
        location: '/admin/halaqat/halaqa-fajr',
      );

      expect(find.text('الشيخ محمود'), findsOneWidget);
      expect(find.text('طلاب الحلقة (٣)'), findsOneWidget);
      expect(find.text('أحمد الخطيب'), findsOneWidget);
      expect(find.text('موقوف'), findsOneWidget); // s012
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('عمر الحسن'));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/admin/halaqat/halaqa-fajr/students/s002');
      expect(find.text('S002'), findsOneWidget);

      await tester.tap(find.byTooltip('رجوع'));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/admin/halaqat/halaqa-fajr');
    });

    testWidgets('change teacher: the confirmation explains recordings move', (
      tester,
    ) async {
      await pumpAdminApp(
        tester,
        school,
        location: '/admin/halaqat/halaqa-fajr',
      );

      await tester.tap(find.text('تغيير المعلم'));
      await tester.pumpAndSettle();
      expect(find.text('اختر المعلم الجديد'), findsOneWidget);
      expect(find.text('الشيخ سعيد'), findsNothing); // disabled
      await tester.tap(find.text('الشيخ عبد الرحمن'));
      await tester.pumpAndSettle();

      final dialog = tester.widget<ConfirmDialog>(find.byType(ConfirmDialog));
      expect(dialog.title, 'تغيير معلم الحلقة');
      expect(dialog.message, contains('كل تسجيلات الحلقة'));
      expect(dialog.message, contains('من الشيخ محمود إلى الشيخ عبد الرحمن'));

      await tester.tap(
        find.descendant(
          of: find.byType(ConfirmDialog),
          matching: find.widgetWithText(FilledButton, 'تغيير المعلم'),
        ),
      );
      await tester.pumpAndSettle();
      expect(school.accounts.changeTeacherCalls.single, ('halaqa-fajr', 't02'));
      expect(find.text('تم تغيير معلم الحلقة'), findsOneWidget);
      expect(find.text('الشيخ عبد الرحمن'), findsOneWidget);
    });

    testWidgets('cancelling the confirmation calls nothing', (tester) async {
      await pumpAdminApp(
        tester,
        school,
        location: '/admin/halaqat/halaqa-fajr',
      );
      await tester.tap(find.text('تغيير المعلم'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الشيخ عبد الرحمن'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(school.accounts.changeTeacherCalls, isEmpty);
    });

    testWidgets('a failed change shows the Arabic error', (tester) async {
      school.accounts.error = const AppException(AppErrorCode.network);
      await pumpAdminApp(
        tester,
        school,
        location: '/admin/halaqat/halaqa-fajr',
      );
      await tester.tap(find.text('تغيير المعلم'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الشيخ عبد الرحمن'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'تغيير المعلم'));
      await tester.pumpAndSettle();
      expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
    });

    testWidgets('rename through the dialog', (tester) async {
      await pumpAdminApp(
        tester,
        school,
        location: '/admin/halaqat/halaqa-fajr',
      );
      await tester.tap(find.text('تغيير الاسم'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'حلقة الشروق',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();
      expect(school.halaqat.renameCalls.single, ('halaqa-fajr', 'حلقة الشروق'));
      expect(find.text('تم تغيير اسم الحلقة'), findsOneWidget);
    });

    testWidgets('add student opens the form with this halaqa chosen', (
      tester,
    ) async {
      await pumpAdminApp(tester, school, location: '/admin/halaqat/halaqa-asr');
      await tester.tap(find.text('إضافة طالب'));
      await tester.pumpAndSettle();

      expect(find.byType(AddStudentScreen), findsOneWidget);
      expect(currentPath(tester), '/admin/halaqat/halaqa-asr/add-student');
      final picker = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(picker.initialValue, 'halaqa-asr');
    });

    testWidgets('an unknown halaqa id shows "not found"', (tester) async {
      await pumpAdminApp(tester, school, location: '/admin/halaqat/nope');
      expect(find.text('العنصر المطلوب غير موجود.'), findsOneWidget);
    });
  });
}
