import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_feedback_repository.dart';
import '../data/firestore_halaqa_repository.dart';
import '../data/firestore_recording_repository.dart';
import '../data/firestore_user_repository.dart';
import '../repositories/feedback_repository.dart';
import '../repositories/halaqa_repository.dart';
import '../repositories/recording_repository.dart';
import '../repositories/user_repository.dart';

/// The Firestore instance every repository uses. Tests override it with a
/// FakeFirebaseFirestore, or override the repository providers directly.
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => FirestoreUserRepository(ref.watch(firestoreProvider)),
);

final halaqaRepositoryProvider = Provider<HalaqaRepository>(
  (ref) => FirestoreHalaqaRepository(ref.watch(firestoreProvider)),
);

final recordingRepositoryProvider = Provider<RecordingRepository>(
  (ref) => FirestoreRecordingRepository(ref.watch(firestoreProvider)),
);

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (ref) => FirestoreFeedbackRepository(ref.watch(firestoreProvider)),
);
