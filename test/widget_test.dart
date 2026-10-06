import 'package:afdal_uloom_tilawat/app/theme.dart';
import 'package:afdal_uloom_tilawat/main.dart';
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
}
