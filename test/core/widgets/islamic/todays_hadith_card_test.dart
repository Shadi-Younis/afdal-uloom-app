import 'package:afdal_uloom_tilawat/app/app.dart';
import 'package:afdal_uloom_tilawat/core/constants/daily_hadiths.dart';
import 'package:afdal_uloom_tilawat/core/models/auth_session.dart';
import 'package:afdal_uloom_tilawat/core/models/user_role.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/daily_hadith_card.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/stat_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/admin_fixture.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/student_fixture.dart';

/// «حديث اليوم» on the three homes (Task 12): under the green header,
/// above the counts, on a 360x640 phone.
void main() {
  setUpAll(loadBundledFonts);

  late StudentFixture fixture;
  setUp(() => fixture = StudentFixture());

  for (final (name, session, path) in [
    ('student', studentSession, '/student'),
    (
      'teacher',
      const AuthSession(uid: 't01', role: UserRole.teacher),
      '/teacher',
    ),
    ('admin', adminSession, '/admin'),
  ]) {
    testWidgets('the $name home: today\'s hadith above the counts', (
      tester,
    ) async {
      usePhoneSize(tester);
      fixture.school.auth.emit(session);
      await tester.pumpWidget(
        ProviderScope(
          overrides: fixture.overrides,
          child: const AfdalUloomApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(currentPath(tester), path);

      final card = find.byType(DailyHadithCard);
      expect(card, findsOneWidget);
      expect(find.text('حديث اليوم'), findsOneWidget);
      expect(
        find.text('«${DailyHadiths.all.single.text}»', findRichText: true),
        findsOneWidget,
      );
      expect(
        tester.getRect(card).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(StatCard).first).top),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
