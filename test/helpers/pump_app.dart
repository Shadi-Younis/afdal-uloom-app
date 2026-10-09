import 'package:afdal_uloom_tilawat/app/app.dart';
import 'package:afdal_uloom_tilawat/app/theme.dart';
import 'package:afdal_uloom_tilawat/core/constants/app_strings.dart';
import 'package:afdal_uloom_tilawat/core/providers/repository_providers.dart';
import 'package:afdal_uloom_tilawat/core/providers/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_fixture.dart';
import 'fake_accounts_service.dart';
import 'fake_auth_service.dart';
import 'fake_halaqa_repository.dart';
import 'fake_user_repository.dart';

/// Same as main(): fonts come from assets/google_fonts/. Call in setUpAll.
Future<void> loadBundledFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  // Building the theme requests every Cairo weight it uses; this throws if
  // one of them is missing from the bundled assets.
  buildAppTheme();
  await GoogleFonts.pendingFonts();
}

/// Makes the test view a 360x640 phone (3x pixel ratio).
void usePhoneSize(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1080, 1920)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Makes the test view a wide screen (the studio PC), 1280x800.
void useWideSize(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1280, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Pumps the whole app (router included) on fake services. [settle] false
/// pumps a few frames instead, for screens with a never-ending spinner.
Future<void> pumpApp(
  WidgetTester tester, {
  required FakeAuthService auth,
  FakeUserRepository? users,
  FakeHalaqaRepository? halaqat,
  FakeAccountsService? accounts,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        userRepositoryProvider.overrideWithValue(users ?? FakeUserRepository()),
        halaqaRepositoryProvider.overrideWithValue(
          halaqat ?? FakeHalaqaRepository(),
        ),
        accountsServiceProvider.overrideWithValue(
          accounts ?? FakeAccountsService(),
        ),
      ],
      child: const AfdalUloomApp(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// Pumps a single screen with the app's theme, Arabic locale and RTL.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  required FakeAuthService auth,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(auth), ...overrides],
      child: MaterialApp(
        theme: buildAppTheme(),
        locale: const Locale(AppStrings.languageCode),
        supportedLocales: const [Locale(AppStrings.languageCode)],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: screen,
      ),
    ),
  );
  await tester.pump();
}

/// Pumps the whole app signed in as the fixture's admin, then opens
/// [location] (an /admin path).
Future<void> pumpAdminApp(
  WidgetTester tester,
  AdminFixture school, {
  String? location,
}) async {
  await tester.pumpWidget(
    ProviderScope(overrides: school.overrides, child: const AfdalUloomApp()),
  );
  await tester.pumpAndSettle();
  if (location != null) {
    currentRouter(tester).go(location);
    await tester.pumpAndSettle();
  }
}

/// The app's router.
GoRouter currentRouter(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

/// The path the router shows now.
String currentPath(WidgetTester tester) =>
    currentRouter(tester).routerDelegate.currentConfiguration.uri.path;
