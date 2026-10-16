import 'package:afdal_uloom_tilawat/app/app_colors.dart';
import 'package:afdal_uloom_tilawat/core/constants/daily_hadiths.dart';
import 'package:afdal_uloom_tilawat/core/models/daily_hadith.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/daily_hadith_card.dart';
import 'package:afdal_uloom_tilawat/core/widgets/islamic/islamic_star.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/pump_app.dart';

void main() {
  setUpAll(loadBundledFonts);

  Future<void> pump(WidgetTester tester, DailyHadith hadith) => pumpScreen(
    tester,
    Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DailyHadithCard(hadith: hadith),
      ),
    ),
    auth: FakeAuthService(),
  );

  RichText hadithText(WidgetTester tester) => tester.widget<RichText>(
    find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().startsWith('«'),
    ),
  );

  testWidgets('title, «قال رسول الله ﷺ:», the hadith between gold « »', (
    tester,
  ) async {
    usePhoneSize(tester);
    final hadith = DailyHadiths.all.single;
    await pump(tester, hadith);

    expect(find.text('حديث اليوم'), findsOneWidget);
    expect(find.byType(IslamicStar), findsNWidgets(2));
    expect(find.text('قال رسول الله ﷺ:'), findsOneWidget);
    final text = hadithText(tester);
    expect(text.text.toPlainText(), '«${hadith.text}»');
    expect(text.textAlign, TextAlign.center);
    // Never the Quranic brackets.
    expect(find.textContaining('﴿'), findsNothing);
    expect(find.textContaining('﴾'), findsNothing);

    // Text.rich: the style on the outer span, the « » and the words inside.
    final outer = text.text as TextSpan;
    final spans = outer.children!.single as TextSpan;
    final [open, words, close] = spans.children!.cast<TextSpan>();
    expect(open.style!.color, AppColors.goldDark);
    expect(close.style!.color, AppColors.goldDark);
    expect(words.style, isNull);
    // Amiri, larger than body text (16).
    expect(outer.style!.fontFamily, contains('Amiri'));
    expect(outer.style!.fontSize, greaterThan(16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a source shows small under it; none: no line', (tester) async {
    await pump(tester, const DailyHadith('نص تجريبي', 'مصدر تجريبي'));
    expect(find.text('مصدر تجريبي'), findsOneWidget);

    await pump(tester, const DailyHadith('نص تجريبي'));
    expect(find.text('مصدر تجريبي'), findsNothing);
  });

  testWidgets('a long text (test only) wraps on a 360x640 phone and wide', (
    tester,
  ) async {
    final long = DailyHadith(
      List.filled(40, 'كلمةٌ طويلةٌ').join(' '),
      List.filled(10, 'مصدرٌ').join(' '),
    );
    usePhoneSize(tester);
    await pump(tester, long);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(DailyHadithCard)).width, 360 - 32);

    useWideSize(tester);
    await pump(tester, long);
    expect(tester.takeException(), isNull);
  });
}
