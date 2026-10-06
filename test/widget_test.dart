import 'package:afdal_uloom_tilawat/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts on the Arabic login placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AfdalUloomApp()));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });
}
