import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/session_providers.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/halaqa.dart';
import '../../../core/models/recording.dart';
import '../../../core/models/user_role.dart';
import '../../../core/providers/repository_providers.dart';

// The admin panel's live data. The school is small (~50 students), so every
// admin screen derives what it shows from these three streams. autoDispose:
// they close when the admin signs out, before the rules start refusing them.
//
// No automatic retry: Firestore listeners reconnect by themselves, so an
// error that reaches here (permission, malformed data) is final. Riverpod's
// default retry would show a spinner for half a minute instead of the
// error; the error view has a retry button.
Duration? _noRetry(int retryCount, Object error) => null;

/// Every halaqa, sorted by name.
final adminHalaqatProvider = StreamProvider.autoDispose<List<Halaqa>>(
  (ref) => ref.watch(halaqaRepositoryProvider).watchAll(),
  retry: _noRetry,
);

/// Every teacher, disabled ones included, sorted by name.
final adminTeachersProvider = StreamProvider.autoDispose<List<AppUser>>(
  (ref) => ref.watch(userRepositoryProvider).watchUsersByRole(UserRole.teacher),
  retry: _noRetry,
);

/// Every student, disabled ones included, sorted by name.
final adminStudentsProvider = StreamProvider.autoDispose<List<AppUser>>(
  (ref) => ref.watch(userRepositoryProvider).watchUsersByRole(UserRole.student),
  retry: _noRetry,
);

/// Teachers who can be given a halaqa: the active ones, by name.
final activeTeachersProvider = Provider.autoDispose<AsyncValue<List<AppUser>>>(
  (ref) => ref
      .watch(adminTeachersProvider)
      .whenData((teachers) => [...teachers.where((t) => !t.disabled)]),
);

/// The active teachers a halaqa can move to: all but [currentTeacherId].
final otherActiveTeachersProvider = Provider.autoDispose
    .family<AsyncValue<List<AppUser>>, String>(
      (ref, currentTeacherId) => ref
          .watch(activeTeachersProvider)
          .whenData(
            (teachers) => [...teachers.where((t) => t.id != currentTeacherId)],
          ),
    );

/// The halaqat a student can move to: all but [currentHalaqaId].
final otherHalaqatProvider = Provider.autoDispose
    .family<AsyncValue<List<Halaqa>>, String?>(
      (ref, currentHalaqaId) => ref
          .watch(adminHalaqatProvider)
          .whenData(
            (halaqat) => [...halaqat.where((h) => h.id != currentHalaqaId)],
          ),
    );

/// Whether the signed-in admin may disable [uid]: never their own account
/// (setUserDisabled refuses it too).
final canDisableProvider = Provider.autoDispose.family<bool, String>(
  (ref, uid) => ref.watch(sessionProvider.select((s) => s.value?.uid)) != uid,
);

/// The recordings of [studentId], newest recorded first.
final studentRecordingsProvider = StreamProvider.autoDispose
    .family<List<Recording>, String>(
      (ref, studentId) =>
          ref.watch(recordingRepositoryProvider).watchForStudent(studentId),
      retry: _noRetry,
    );
