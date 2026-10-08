import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/halaqa.dart';
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
