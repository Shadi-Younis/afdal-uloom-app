import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/firebase_setup.dart';
import '../data/firebase_audio_storage_service.dart';
import '../data/firebase_auth_service.dart';
import '../data/functions_accounts_service.dart';
import '../services/accounts_service.dart';
import '../services/audio_storage_service.dart';
import '../services/auth_service.dart';

/// The FirebaseAuth instance AuthService uses. Tests override it with a
/// MockFirebaseAuth, or override [authServiceProvider] directly.
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final authServiceProvider = Provider<AuthService>(
  (ref) => FirebaseAuthService(ref.watch(firebaseAuthProvider)),
);

/// Account management through the callables in me-west1.
final accountsServiceProvider = Provider<AccountsService>(
  (ref) => FunctionsAccountsService(regionalFunctions),
);

/// The FirebaseStorage instance AudioStorageService uses (the default
/// bucket, FirebaseConstants.storageBucket).
final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

/// Kept for the whole session: it caches playback URLs.
final audioStorageServiceProvider = Provider<AudioStorageService>(
  (ref) => FirebaseAudioStorageService(ref.watch(firebaseStorageProvider)),
);
