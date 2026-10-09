import 'package:afdal_uloom_tilawat/app/app_colors.dart';
import 'package:afdal_uloom_tilawat/core/errors/app_exception.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/app_card.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/empty_state.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/error_state.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/islamic_star.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/loading_state.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/stat_card.dart';
import 'package:flutter/material.dart';
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

  group('AppCard', () {
    testWidgets('white, radius 16, gold hairline; taps', (tester) async {
      var taps = 0;
      await pump(
        tester,
        AppCard(onTap: () => taps++, child: const Text('بطاقة')),
      );
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(AppCard),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, AppColors.card);
      expect(decoration.borderRadius, BorderRadius.circular(16));
      expect((decoration.border! as Border).top.color, AppColors.goldLight);
      await tester.tap(find.text('بطاقة'));
      expect(taps, 1);
    });

    testWidgets('accent: a gold bar on the start side (right in RTL)', (
      tester,
    ) async {
      await pump(
        tester,
        const SizedBox(
          width: 300,
          child: AppCard(accent: true, child: Text('ملاحظة')),
        ),
      );
      final bar = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == AppColors.gold,
      );
      expect(bar, findsOneWidget);
      expect(
        tester.getRect(bar).right,
        closeTo(tester.getRect(find.byType(AppCard)).right, 1),
      );
    });
  });

  testWidgets('StatCard: star, number in Arabic-Indic digits, label; taps', (
    tester,
  ) async {
    var taps = 0;
    await pump(
      tester,
      SizedBox(
        width: 110,
        child: StatCard(number: 12, label: 'الطلاب', onTap: () => taps++),
      ),
    );
    expect(find.byType(IslamicStar), findsOneWidget);
    expect(find.text('١٢'), findsOneWidget);
    expect(find.text('الطلاب'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('١٢')).style!.fontFamily,
      contains('ReemKufi'),
    );
    await tester.tap(find.text('١٢'));
    expect(taps, 1);
    // Star, number and label centered in the card.
    final center = tester.getCenter(find.byType(StatCard)).dx;
    for (final part in [
      find.byType(IslamicStar),
      find.text('١٢'),
      find.text('الطلاب'),
    ]) {
      expect(tester.getCenter(part).dx, closeTo(center, 1));
    }
  });

  group('states', () {
    testWidgets('EmptyState: faded star, message, optional action', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        EmptyState(
          message: 'لا يوجد شيء',
          actionLabel: 'إضافة',
          onAction: () => taps++,
        ),
      );
      expect(find.byType(IslamicStar), findsOneWidget);
      expect(
        tester
            .widget<Opacity>(
              find.ancestor(
                of: find.byType(IslamicStar),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        lessThan(0.5),
      );
      expect(find.text('لا يوجد شيء'), findsOneWidget);
      await tester.tap(find.text('إضافة'));
      expect(taps, 1);
    });

    testWidgets('EmptyState without an action has no button', (tester) async {
      await pump(tester, const EmptyState(message: 'فارغ'));
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('ErrorState: the Arabic message, never raw text; retry', (
      tester,
    ) async {
      var retries = 0;
      await pump(
        tester,
        ErrorState(
          error: const AppException(AppErrorCode.network),
          onRetry: () => retries++,
        ),
      );
      expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
      await tester.tap(find.text('إعادة المحاولة'));
      expect(retries, 1);

      await pump(tester, ErrorState(error: StateError('secret details')));
      expect(find.textContaining('secret'), findsNothing);
      expect(find.text('حدث خطأ غير متوقع. حاول مرة أخرى.'), findsOneWidget);
    });

    testWidgets('LoadingState: a labelled progress indicator', (tester) async {
      await pump(tester, const LoadingState());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
