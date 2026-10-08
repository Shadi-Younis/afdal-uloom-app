import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/app.dart';
import 'app/firebase_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cairo is bundled in assets/google_fonts/; never fetch fonts at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Firebase is set up here, not in AfdalUloomApp, so widget tests can pump
  // the app without it.
  await initFirebase();
  runApp(const ProviderScope(child: AfdalUloomApp()));
}
