import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/application/recording_note_counts.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/models/recording.dart';
import '../../../../core/widgets/common/recording_tile.dart';

/// A recording in the teacher's list: title, date, its markers count and
/// whether it was reviewed, and [studentName] in the review queue; a tap
/// opens it (push: back returns here).
class TeacherRecordingTile extends ConsumerWidget {
  const TeacherRecordingTile({
    super.key,
    required this.recording,
    this.studentName,
  });

  final Recording recording;
  final String? studentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RecordingTile(
      recording: recording,
      markerCount: ref.watch(recordingMarkerCountProvider(recording.id)).value,
      showReviewed: true,
      studentName: studentName,
      onTap: () => context.push(AppRoutes.recording(recording.id)),
    );
  }
}
