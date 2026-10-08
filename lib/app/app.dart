import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_strings.dart';
import 'firebase_setup.dart';
import 'router.dart';
import 'theme.dart';

/// The root widget: Arabic-only, RTL, themed, routed by [routerProvider].
///
/// Does not touch Firebase, so widget tests can pump it without
/// initializing Firebase.
class AfdalUloomApp extends ConsumerWidget {
  const AfdalUloomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale(AppStrings.languageCode),
      supportedLocales: const [Locale(AppStrings.languageCode)],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => showProdBanner
          ? Banner(
              message: AppStrings.prodBanner,
              location: BannerLocation.topStart,
              color: Colors.red,
              child: child!,
            )
          : child!,
    );
  }
}
