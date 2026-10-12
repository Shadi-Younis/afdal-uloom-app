import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/repository_providers.dart';

/// How many notes about a moment of recording [recordingId] there are (the
/// markers on its seek bar): the teacher's lists.
final recordingMarkerCountProvider = StreamProvider.autoDispose
    .family<int, String>(
      (ref, recordingId) => ref
          .watch(feedbackRepositoryProvider)
          .watch(recordingId)
          .map((notes) => notes.where((n) => n.atSecond != null).length),
    );

/// How many notes recording [recordingId] has, the sheikh's voice markers
/// and written notes alike: the student's list.
final recordingNoteCountProvider = StreamProvider.autoDispose
    .family<int, String>(
      (ref, recordingId) => ref
          .watch(feedbackRepositoryProvider)
          .watch(recordingId)
          .map((notes) => notes.length),
    );
