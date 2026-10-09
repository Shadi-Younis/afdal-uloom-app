import 'dart:async';

import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/models/halaqa.dart';
import 'package:afdal_uloom_tilawat/features/admin/presentation/widgets/delete_student_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  late AdminFixture school;
  setUp(() => school = AdminFixture());

  /// Scrolls the details page down to [text] and taps it.
  Future<void> scrollAndTap(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  group('halaqa', () {
    testWidgets('with students: the explanation, then its students', (
      tester,
    ) async {
      usePhoneSize(tester);
      await pumpAdminApp(tester, school, location: '/admin/halaqat');
      await tester.tap(find.text('حلقة الفجر'));
      await tester.pumpAndSettle();
      await scrollAndTap(tester, 'حذف الحلقة');

      expect(find.text('لا يمكن حذف الحلقة'), findsOneWidget);
      // s001, s002 and the disabled s012.
      expect(find.textContaining('انقل طلاب الحلقة أولاً'), findsOneWidget);
      expect(find.textContaining('عدد طلابها الآن: ٣'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('عرض الطلاب'));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/admin/students');
      expect(find.text('أحمد الخطيب'), findsOneWidget);
      expect(find.text('أنس جابر'), findsOneWidget);
      expect(find.text('يوسف النجار'), findsNothing); // حلقة العصر
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'حلقة الفجر'))
            .selected,
        isTrue,
      );
      expect(school.accounts.deleteHalaqaCalls, isEmpty);
    });

    testWidgets('empty: confirmed, deleted, back to the list', (tester) async {
      usePhoneSize(tester);
      school.halaqat.put(
        const Halaqa(
          id: 'halaqa-maghrib',
          name: 'حلقة المغرب',
          teacherId: 't01',
        ),
      );
      await pumpAdminApp(tester, school, location: '/admin/halaqat');
      await tester.tap(find.text('حلقة المغرب'));
      await tester.pumpAndSettle();
      await scrollAndTap(tester, 'حذف الحلقة');

      expect(
        find.text('ستُحذف حلقة المغرب نهائياً. لا يمكن التراجع عن ذلك.'),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'حذف الحلقة'),
        ),
      );
      await tester.pumpAndSettle();

      expect(school.accounts.deleteHalaqaCalls, ['halaqa-maghrib']);
      expect(currentPath(tester), '/admin/halaqat');
      expect(find.text('تم حذف الحلقة'), findsOneWidget);
      expect(find.text('حلقة المغرب'), findsNothing);
    });

    testWidgets('refused by the server: the Arabic reason, nothing moves', (
      tester,
    ) async {
      school.halaqat.put(
        const Halaqa(
          id: 'halaqa-maghrib',
          name: 'حلقة المغرب',
          teacherId: 't01',
        ),
      );
      school.accounts.error = const AppException(
        AppErrorCode.halaqaHasRecordings,
      );
      await pumpAdminApp(
        tester,
        school,
        location: '/admin/halaqat/halaqa-maghrib',
      );
      await scrollAndTap(tester, 'حذف الحلقة');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'حذف الحلقة'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('ما زالت في الحلقة تسجيلات، انقل طلابها أولاً'),
        findsOneWidget,
      );
      expect(currentPath(tester), '/admin/halaqat/halaqa-maghrib');
    });
  });

  group('teacher', () {
    testWidgets('with halaqat: the explanation and a link to each', (
      tester,
    ) async {
      usePhoneSize(tester);
      await pumpAdminApp(tester, school, location: '/admin/teachers');
      await tester.tap(find.text('الشيخ محمود'));
      await tester.pumpAndSettle();
      await scrollAndTap(tester, 'حذف المعلم');

      expect(find.text('لا يمكن حذف المعلم'), findsOneWidget);
      expect(
        find.text(
          'انقل حلقات المعلم لمعلم آخر أولاً: افتح كل حلقة واضغط «تغيير المعلم».',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('حلقة الفجر'),
        ),
      );
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/admin/halaqat/halaqa-fajr');
      expect(school.accounts.deleteUserCalls, isEmpty);
    });

    testWidgets('without halaqat: confirmed, deleted, back to the list', (
      tester,
    ) async {
      usePhoneSize(tester);
      await pumpAdminApp(tester, school, location: '/admin/teachers');
      await tester.tap(find.text('الشيخ سعيد'));
      await tester.pumpAndSettle();
      await scrollAndTap(tester, 'حذف المعلم');

      expect(find.textContaining('«معلم سابق»'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'حذف المعلم'),
        ),
      );
      await tester.pumpAndSettle();

      expect(school.accounts.deleteUserCalls, ['t03']);
      expect(currentPath(tester), '/admin/teachers');
      expect(find.text('تم حذف المعلم'), findsOneWidget);
      expect(find.text('الشيخ سعيد'), findsNothing);
    });
  });

  group('student permanent delete', () {
    Finder deleteButton() => find.descendant(
      of: find.byType(DeleteStudentDialog),
      matching: find.widgetWithText(FilledButton, 'حذف نهائي'),
    );
    bool deleteEnabled(WidgetTester tester) =>
        tester.widget<FilledButton>(deleteButton()).onPressed != null;

    Future<void> openDialog(WidgetTester tester) async {
      await pumpAdminApp(tester, school, location: '/admin/students');
      await tester.tap(find.text('أحمد الخطيب'));
      await tester.pumpAndSettle();
      // Explained next to "إيقاف الحساب".
      expect(find.textContaining('الحذف النهائي يحذف الحساب'), findsOneWidget);
      await scrollAndTap(tester, 'حذف نهائي');
    }

    testWidgets('the button is enabled only by the exact code', (tester) async {
      usePhoneSize(tester);
      await openDialog(tester);

      expect(find.text('حذف أحمد الخطيب نهائياً'), findsOneWidget);
      expect(find.text('عدد التسجيلات التي ستُحذف: ٣'), findsOneWidget);
      expect(find.text('للتأكيد، اكتب رقم الطالب: S001'), findsOneWidget);
      expect(deleteEnabled(tester), isFalse);
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField), 's001');
      await tester.pump();
      expect(deleteEnabled(tester), isFalse);
      await tester.enterText(find.byType(TextField), 'S00');
      await tester.pump();
      expect(deleteEnabled(tester), isFalse);
      await tester.enterText(find.byType(TextField), 'S001');
      await tester.pump();
      expect(deleteEnabled(tester), isTrue);
      expect(school.accounts.deleteUserCalls, isEmpty);
    });

    testWidgets('running: cannot be dismissed; then the list and a SnackBar', (
      tester,
    ) async {
      usePhoneSize(tester);
      await openDialog(tester);
      await tester.enterText(find.byType(TextField), 'S001');
      await tester.pump();

      school.accounts.gate = Completer();
      await tester.tap(deleteButton());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Neither the barrier, back nor "إلغاء" closes it now.
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(DeleteStudentDialog), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'إلغاء'))
            .onPressed,
        isNull,
      );

      school.accounts.gate!.complete();
      await tester.pumpAndSettle();
      expect(school.accounts.deleteUserCalls, ['s001']);
      expect(find.byType(DeleteStudentDialog), findsNothing);
      expect(currentPath(tester), '/admin/students');
      expect(find.text('تم حذف الطالب نهائياً'), findsOneWidget);
      expect(find.text('أحمد الخطيب'), findsNothing);
    });

    testWidgets('opened from its halaqa: back to the halaqa', (tester) async {
      await pumpAdminApp(
        tester,
        school,
        location: '/admin/halaqat/halaqa-fajr',
      );
      await scrollAndTap(tester, 'أحمد الخطيب');
      await scrollAndTap(tester, 'حذف نهائي');
      await tester.enterText(find.byType(TextField), 'S001');
      await tester.pump();
      await tester.tap(deleteButton());
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/admin/halaqat/halaqa-fajr');
      expect(find.text('تم حذف الطالب نهائياً'), findsOneWidget);
    });

    testWidgets('a network error stays in the dialog', (tester) async {
      await openDialog(tester);
      await tester.enterText(find.byType(TextField), 'S001');
      await tester.pump();
      school.accounts.error = const AppException(AppErrorCode.network);
      await tester.tap(deleteButton());
      await tester.pumpAndSettle();

      expect(find.byType(DeleteStudentDialog), findsOneWidget);
      expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
      expect(school.users.users.containsKey('s001'), isTrue);

      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(find.byType(DeleteStudentDialog), findsNothing);
      expect(currentPath(tester), '/admin/students/s001');
    });
  });
}
