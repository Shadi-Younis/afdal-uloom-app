import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/recording.dart';
import '../../application/recording_manage_controller.dart';

/// «تمت المراجعة» for the recording's teacher and admins: toggles
/// `reviewed` both ways. A failure shows on the page (RecordingDetailsView).
class ReviewedToggle extends ConsumerWidget {
  const ReviewedToggle({super.key, required this.recording});

  final Recording recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = recordingManageControllerProvider(recording.id);
    final busy = ref.watch(provider).isLoading;
    return Center(
      child: FilterChip(
        label: const Text(AppStrings.reviewedToggle),
        selected: recording.reviewed,
        onSelected: busy
            ? null
            : (reviewed) =>
                  ref.read(provider.notifier).setReviewed(reviewed: reviewed),
      ),
    );
  }
}
