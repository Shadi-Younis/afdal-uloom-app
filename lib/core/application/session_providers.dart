import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/auth_session.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';

/// Who is signed in: loading until AuthService reports, then the session or
/// null. Drives the router's redirects.
final sessionProvider = StreamProvider<AuthSession?>(
  (ref) => ref.watch(authServiceProvider).sessionChanges(),
);

/// The signed-in user's profile (`users/{uid}`), or null when signed out.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(sessionProvider.select((s) => s.value?.uid));
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(uid);
});
