import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/password_generator.dart';

/// Generates the passwords suggested for new accounts and resets. Tests
/// override it with a seeded generator.
final passwordGeneratorProvider = Provider<PasswordGenerator>(
  (ref) => PasswordGenerator(),
);
