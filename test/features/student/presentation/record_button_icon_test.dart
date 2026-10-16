import 'dart:math' as math;

import 'package:afdal_uloom_tilawat/app/app.dart';
import 'package:afdal_uloom_tilawat/core/constants/app_durations.dart';
import 'package:afdal_uloom_tilawat/features/student/presentation/widgets/record_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/student_fixture.dart';

/// Task 12: the big record button showed as an empty green circle. On the
/// web that was a cached older icon font (fixed in the deploy,
/// tool/deploy/fingerprint_web_fonts.dart); here the button itself: in
/// every state it draws its icon, light on the green.
void main() {
  setUpAll(loadBundledFonts);

  late StudentFixture fixture;
  setUp(() => fixture = StudentFixture());

  /// WCAG contrast ratio of two opaque colors.
  double contrast(Color a, Color b) {
    double luminance(Color c) {
      double channel(double v) => v <= 0.03928
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
      return 0.2126 * channel(c.r) +
          0.7152 * channel(c.g) +
          0.0722 * channel(c.b);
    }

    final (l1, l2) = (luminance(a), luminance(b));
    return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
  }

  /// The record button shows [icon], drawn big and light on its green.
  void expectIcon(WidgetTester tester, IconData icon) {
    final button = find.byType(RecordButton);
    final iconFinder = find.descendant(of: button, matching: find.byIcon(icon));
    expect(iconFinder, findsOneWidget);
    // What the icon is actually painted with: the button's foreground.
    final glyph = tester.widget<RichText>(
      find.descendant(of: iconFinder, matching: find.byType(RichText)),
    );
    final style = glyph.text.style!;
    expect(style.fontFamily, icon.fontFamily);
    expect(glyph.text.toPlainText(), String.fromCharCode(icon.codePoint));
    expect(style.fontSize, greaterThan(30));
    final background = tester
        .widget<Material>(
          find.descendant(of: button, matching: find.byType(Material)).first,
        )
        .color!;
    expect(
      contrast(style.color!, background),
      greaterThanOrEqualTo(4.5),
      reason: 'icon ${style.color} on $background',
    );
  }

  testWidgets('ready, recording and paused: the icon is there, with '
      'contrast', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(overrides: fixture.overrides, child: const AfdalUloomApp()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('سجّل تدريباً'));
    await tester.pumpAndSettle();

    // Ready: the microphone.
    expectIcon(tester, Icons.mic);

    await tester.tap(find.byTooltip('ابدأ التسجيل'));
    await tester.pump();
    await tester.pump(AppDurations.recorderTick);
    expect(find.text('جارٍ التسجيل'), findsOneWidget);
    expectIcon(tester, Icons.pause);

    await tester.tap(find.byTooltip('إيقاف مؤقت'));
    await tester.pump();
    expect(find.text('التسجيل متوقف مؤقتاً'), findsOneWidget);
    expectIcon(tester, Icons.mic);
    expect(tester.takeException(), isNull);
  });
}
