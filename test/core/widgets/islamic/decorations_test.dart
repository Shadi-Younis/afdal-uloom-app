import 'package:afdal_uloom_tilawat/app/app_colors.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/islamic_pattern_background.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/islamic_star.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/ornament_divider.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/ornate_header.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/surah_cartouche.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  Future<void> pump(WidgetTester tester, Widget child) => pumpScreen(
    tester,
    Scaffold(body: Center(child: child)),
    auth: FakeAuthService(),
  );

  group('IslamicStar', () {
    testWidgets('paints the star at the given size, green and gold', (
      tester,
    ) async {
      await pump(tester, const IslamicStar(size: 40));
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(IslamicStar),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = paint.painter! as IslamicStarPainter;
      expect(painter.color, AppColors.green);
      expect(painter.gold, AppColors.gold);
      expect(tester.getSize(find.byType(IslamicStar)), const Size(40, 40));
    });

    testWidgets('decorative by default, labelled when asked', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, const IslamicStar(semanticLabel: 'نجمة'));
      expect(find.bySemanticsLabel('نجمة'), findsOneWidget);
      semantics.dispose();
    });

    test('repaints only when its colors change', () {
      const a = IslamicStarPainter(
        color: AppColors.green,
        gold: AppColors.gold,
      );
      expect(a.shouldRepaint(a), isFalse);
      expect(
        a.shouldRepaint(
          const IslamicStarPainter(color: AppColors.ink, gold: AppColors.gold),
        ),
        isTrue,
      );
    });
  });

  testWidgets('OrnamentDivider: star, title in Reem Kufi green, star', (
    tester,
  ) async {
    await pump(tester, const OrnamentDivider(title: 'اختصارات'));
    expect(find.text('اختصارات'), findsOneWidget);
    expect(find.byType(IslamicStar), findsNWidgets(2));
    final style = tester.widget<Text>(find.text('اختصارات')).style!;
    expect(style.fontFamily, contains('ReemKufi'));
    expect(style.color, AppColors.green);
    // RTL: one star on each side of the title.
    final title = tester.getCenter(find.text('اختصارات')).dx;
    final stars = tester
        .widgetList<IslamicStar>(find.byType(IslamicStar))
        .map((s) => tester.getCenter(find.byWidget(s)).dx)
        .toList();
    expect(stars.where((x) => x > title), hasLength(1));
    expect(stars.where((x) => x < title), hasLength(1));
  });

  group('IslamicPatternBackground', () {
    testWidgets('painted once in its own layer, behind the child', (
      tester,
    ) async {
      await pump(
        tester,
        const SizedBox.square(
          dimension: 200,
          child: IslamicPatternBackground(child: Text('محتوى')),
        ),
      );
      expect(find.text('محتوى'), findsOneWidget);
      final paint = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(RepaintBoundary),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      expect(paint.isComplex, isTrue);
      expect(paint.willChange, isFalse);
      final painter = paint.painter! as IslamicPatternPainter;
      expect(painter.color.a, closeTo(IslamicPatternBackground.onIvory, 0.01));
    });

    test('9% on ivory, 18% on green', () {
      expect(IslamicPatternBackground.onIvory, 0.09);
      expect(IslamicPatternBackground.onGreen, 0.18);
    });
  });

  testWidgets('OrnateHeader: green, the top row above the content', (
    tester,
  ) async {
    await pump(
      tester,
      const OrnateHeader(top: Text('التاريخ'), child: Text('الاسم')),
    );
    expect(
      tester.getCenter(find.text('التاريخ')).dy,
      lessThan(tester.getCenter(find.text('الاسم')).dy),
    );
    // Light status bar icons over the green.
    expect(
      tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find
                .descendant(
                  of: find.byType(OrnateHeader),
                  matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
                )
                .first,
          )
          .value,
      SystemUiOverlayStyle.light,
    );
    expect(
      find.descendant(
        of: find.byType(OrnateHeader),
        matching: find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == AppColors.green,
        ),
      ),
      findsOneWidget,
    );
  });

  group('SurahCartouche', () {
    testWidgets('the title in Amiri white', (tester) async {
      await pump(tester, const SurahCartouche(title: 'سورة الكهف'));
      final style = tester.widget<Text>(find.text('سورة الكهف')).style!;
      expect(style.fontFamily, contains('Amiri'));
      expect(style.color, AppColors.onGreen);
      expect(tester.getSize(find.byType(SurahCartouche)).height, 74);
    });

    testWidgets('a long title shrinks to fit a phone, no overflow', (
      tester,
    ) async {
      usePhoneSize(tester);
      await pumpScreen(
        tester,
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: SurahCartouche(title: 'سورة الشعراء: الآيات ٢٠٠–٢٢٧ كاملة'),
          ),
        ),
        auth: FakeAuthService(),
      );
      expect(tester.takeException(), isNull);
      final text = tester.getRect(find.byType(FittedBox));
      final frame = tester.getRect(find.byType(SurahCartouche));
      expect(frame.contains(text.topLeft), isTrue);
      expect(frame.contains(text.bottomRight), isTrue);
    });
  });
}
