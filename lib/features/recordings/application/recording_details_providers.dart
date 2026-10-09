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

/// Who uploaded [recording]: their name when the viewer may read their
/// profile, otherwise "المعلم" / "الطالب". A student may not read a
/// teacher's profile (firestore.rules), so for them it is never asked.
final uploaderNameProvider = FutureProvider.autoDispose
    .family<String, Recording>((ref, recording) async {
      final uploaderId = recording.uploadedBy;
      final fallback = uploaderId == recording.studentId
          ? AppStrings.roleStudent
          : AppStrings.roleTeacher;
      final viewer = ref.watch(sessionProvider).value;
      if (viewer == null ||
          (viewer.role == UserRole.student && viewer.uid != uploaderId)) {
        return fallback;
      }
      try {
        final user = await ref
            .watch(userRepositoryProvider)
            .watchUser(uploaderId)
            .first;
        return user?.fullName ?? fallback;
      } on Object {
        // Only a label: the screen works without the name.
        return fallback;
      }
    }, retry: _noRetry);
