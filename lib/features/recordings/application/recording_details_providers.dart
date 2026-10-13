import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/session_providers.dart';
import '../../../core/application/student_halaqa_provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/feedback_note.dart';
import '../../../core/models/recording.dart';
import '../../../core/models/recording_type.dart';
import '../../../core/models/user_role.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/sheikh_name.dart';

// No automatic retry: a refused or missing recording will not change by
// itself, and Riverpod's default retry would hide the error behind a
// spinner. The screen has a retry button.
Duration? _noRetry(int retryCount, Object error) => null;

/// The recording [id], live, or null when it does not exist. Fails with
/// permissionDenied when the rules refuse it (another student's recording).
final recordingDetailsProvider = StreamProvider.autoDispose
    .family<Recording?, String>(
      (ref, id) => ref.watch(recordingRepositoryProvider).watch(id),
      retry: _noRetry,
    );

/// The teacher's notes on recording [id], oldest first.
final recordingFeedbackProvider = StreamProvider.autoDispose
    .family<List<FeedbackNote>, String>(
      (ref, id) => ref.watch(feedbackRepositoryProvider).watch(id),
      retry: _noRetry,
    );

/// Whether the viewer may add, edit and delete notes on a recording of
/// [teacherId] and mark it reviewed: its teacher (with the teacher role)
/// and admins. firestore.rules decide; this only hides the buttons.
final canManageRecordingProvider = Provider.autoDispose.family<bool, String>((
  ref,
  teacherId,
) {
  final viewer = ref.watch(sessionProvider).value;
  return switch (viewer?.role) {
    UserRole.admin => true,
    UserRole.teacher => viewer?.uid == teacherId,
    _ => false,
  };
});

/// Whether the viewer may delete [recording] with «حذف التدريب»: its
/// student, while it is a practice the sheikh has not reviewed yet.
/// firestore.rules decide; this only shows the button.
final canDeletePracticeProvider = Provider.autoDispose.family<bool, Recording>((
  ref,
  recording,
) {
  final viewer = ref.watch(sessionProvider).value;
  return viewer?.role == UserRole.student &&
      viewer?.uid == recording.studentId &&
      recording.type == RecordingType.practice &&
      !recording.reviewed;
});

/// While its student has recording [id] open, its «ملاحظات جديدة» is
/// cleared (`unreadFeedback` false), also when a new note arrives
/// meanwhile. Nothing for teachers and admins: the flag is the student's.
final feedbackReadMarkerProvider = Provider.autoDispose.family<void, String>((
  ref,
  id,
) {
  final viewer = ref.watch(sessionProvider).value;
  if (viewer == null || viewer.role != UserRole.student) return;
  ref.listen(recordingDetailsProvider(id), (_, next) {
    final recording = next.value;
    if (recording == null ||
        !recording.unreadFeedback ||
        recording.studentId != viewer.uid) {
      return;
    }
    // Only a flag: offline or refused, it is cleared on the next visit.
    ref
        .read(recordingRepositoryProvider)
        .markFeedbackRead(id)
        .catchError((Object _) {});
  }, fireImmediately: true);
});

/// A person on the recording screen: [uid], the label to show when the
/// viewer may not read their profile ([fallback]), the one when the
/// profile no longer exists ([missing]; null: the fallback), e.g. "معلم
/// سابق" for a deleted teacher, and the one a student sees when it is
/// neither himself nor his sheikh ([forStudent]; empty: not shown).
typedef PersonName = ({
  String uid,
  String fallback,
  String? missing,
  String forStudent,
});

/// The name of [PersonName.uid] (the uploader, a note's teacher, the
/// student). A student may read only his own profile (firestore.rules):
/// his sheikh is named from his halaqa («الشيخ محمود»), anyone else gets
/// [PersonName.forStudent], so no read is ever denied. Only an admin can
/// tell a deleted profile from one they may not read: teachers see the
/// fallback.
final personNameProvider = FutureProvider.autoDispose
    .family<String, PersonName>((ref, person) async {
      final viewer = ref.watch(sessionProvider).value;
      if (viewer == null) return person.fallback;
      if (viewer.role == UserRole.student && viewer.uid != person.uid) {
        final halaqa = await ref
            .watch(studentHalaqaProvider.future)
            .catchError((Object _) => null);
        return halaqa != null && halaqa.teacherId == person.uid
            ? sheikhName(halaqa.teacherName)
            : person.forStudent;
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
/// "معلم سابق" when it was a teacher whose account was deleted. A student
/// sees his sheikh's name, and nothing for anyone else (an admin, or the
/// teacher the halaqa had before).
PersonName uploaderOf(Recording recording) {
  final byStudent = recording.uploadedBy == recording.studentId;
  return (
    uid: recording.uploadedBy,
    fallback: byStudent ? AppStrings.roleStudent : AppStrings.roleTeacher,
    missing: byStudent ? null : AppStrings.formerTeacher,
    forStudent: '',
  );
}

/// The teacher who wrote a note: "المعلم" when unreadable, "معلم سابق"
/// when their account was deleted. A student sees his sheikh as «الشيخ
/// محمود», and anyone else as "معلم سابق".
PersonName noteAuthor(String teacherId) => (
  uid: teacherId,
  fallback: AppStrings.roleTeacher,
  missing: AppStrings.formerTeacher,
  forStudent: AppStrings.formerTeacher,
);
