import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/firebase_setup.dart';
import 'app/router.dart';
import 'app/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cairo is bundled in assets/google_fonts/; never fetch fonts at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Firebase is set up here, not in AfdalUloomApp, so widget tests can pump
  // the app without it.
  await initFirebase();
  runApp(const ProviderScope(child: AfdalUloomApp()));
}

class AfdalUloomApp extends ConsumerWidget {
  const AfdalUloomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'أفضل العلوم',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
