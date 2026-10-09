import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/session_providers.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/feedback_note.dart';
import '../../../core/models/recording.dart';
import '../../../core/models/user_role.dart';
import '../../../core/providers/repository_providers.dart';

// No automatic retry: a refused or missing recording will not change by
// itself, and Riverpod's default retry would hide the error behind a
// spinner. The screen has a retry button.
Duration? _noRetry(int retryCount, Object error) => null;

/// The recording [id], or null when it does not exist. Fails with
/// permissionDenied when the rules refuse it (another student's recording).
final recordingDetailsProvider = FutureProvider.autoDispose
    .family<Recording?, String>(
      (ref, id) => ref.watch(recordingRepositoryProvider).get(id),
      retry: _noRetry,
    );

/// The teacher's notes on recording [id], oldest first.
final recordingFeedbackProvider = StreamProvider.autoDispose
    .family<List<FeedbackNote>, String>(
      (ref, id) => ref.watch(feedbackRepositoryProvider).watch(id),
      retry: _noRetry,
    );

/// A person on the recording screen: [uid], the label to show when the
/// viewer may not read their profile ([fallback]), and the one when the
/// profile no longer exists ([missing]; null: the fallback), e.g. "معلم
/// سابق" for a deleted teacher.
typedef PersonName = ({String uid, String fallback, String? missing});

/// The name of [PersonName.uid] (the uploader, a note's teacher, the
/// student), or its fallback when the viewer may not read that profile. A
/// student may only read their own (firestore.rules), so for anyone else
/// it is never asked: no denied reads. Only an admin can tell a deleted
/// profile from one they may not read: teachers see the fallback.
final personNameProvider = FutureProvider.autoDispose
    .family<String, PersonName>((ref, person) async {
      final viewer = ref.watch(sessionProvider).value;
      if (viewer == null ||
          (viewer.role == UserRole.student && viewer.uid != person.uid)) {
        return person.fallback;
      }
      try {
        final user = await ref
            .watch(userRepositoryProvider)
            .watchUser(person.uid)
            .first;
        return user?.fullName ?? person.missing ?? person.fallback;
      } on Object {
        // Only a label: the screen works without the name.
        return person.fallback;
      }
    }, retry: _noRetry);

/// The uploader of [recording]: "الطالب" or "المعلم" when unreadable,
/// "معلم سابق" when it was a teacher whose account was deleted.
PersonName uploaderOf(Recording recording) {
  final byStudent = recording.uploadedBy == recording.studentId;
  return (
    uid: recording.uploadedBy,
    fallback: byStudent ? AppStrings.roleStudent : AppStrings.roleTeacher,
    missing: byStudent ? null : AppStrings.formerTeacher,
  );
}

/// The teacher who wrote a note: "المعلم" when unreadable, "معلم سابق"
/// when their account was deleted.
PersonName noteAuthor(String teacherId) => (
  uid: teacherId,
  fallback: AppStrings.roleTeacher,
  missing: AppStrings.formerTeacher,
);
