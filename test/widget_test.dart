import 'package:afdal_uloom_tilawat/app/theme.dart';
import 'package:afdal_uloom_tilawat/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() async {
    // Same as main(): fonts must come from assets/google_fonts/.
    GoogleFonts.config.allowRuntimeFetching = false;
    // Building the theme requests every Cairo weight it uses; this throws if
    // one of them is missing from the bundled assets.
    buildAppTheme();
    await GoogleFonts.pendingFonts();
  });

  testWidgets('app starts on the Arabic login placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AfdalUloomApp()));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });

  const roles = {
    'دخول كمدير': 'لوحة المدير',
    'دخول كمعلم': 'لوحة المعلم',
    'دخول كطالب': 'لوحة الطالب',
  };

  for (final MapEntry(key: button, value: title) in roles.entries) {
    testWidgets('$button opens $title and logout returns to login', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: AfdalUloomApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(button));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text(title)),
        findsOneWidget,
      );
      // context.go replaces the stack, so there is no back arrow to login.
      expect(find.byType(BackButton), findsNothing);

      await tester.tap(find.byTooltip('تسجيل الخروج'));
      await tester.pumpAndSettle();

      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(find.text(title), findsNothing);
    });
  }
}
