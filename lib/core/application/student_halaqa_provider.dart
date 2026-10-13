import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/halaqa.dart';
import '../providers/repository_providers.dart';
import 'session_providers.dart';

/// The signed-in student's own halaqa (`users/{uid}.halaqaId`), live: its
/// teacher, and the teacher's name the students see (teacherName). Null
/// while signed out, for a profile without a halaqa, or when the halaqa
/// does not exist.
final studentHalaqaProvider = StreamProvider.autoDispose<Halaqa?>((ref) {
  final halaqaId = ref.watch(
    currentUserProvider.select((user) => user.value?.halaqaId),
  );
  if (halaqaId == null) return Stream.value(null);
  return ref.watch(halaqaRepositoryProvider).watch(halaqaId);
});
