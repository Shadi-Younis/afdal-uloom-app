import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/recording.dart';
import '../../../../core/widgets/common/recording_player.dart';
import '../../../../core/widgets/islamic/ornament_divider.dart';
import 'feedback_section.dart';
import 'recording_header.dart';

/// The content of the recording screen, at most
/// [AppSizes.contentMaxWidth] wide on the studio PC.
class RecordingDetailsView extends StatelessWidget {
  const RecordingDetailsView({super.key, required this.recording});

  final Recording recording;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pagePadding),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RecordingHeader(recording: recording),
              const SizedBox(height: AppSizes.spaceM),
              RecordingPlayer(storagePath: recording.storagePath),
              const OrnamentDivider(title: AppStrings.feedbackTitle),
              const SizedBox(height: AppSizes.spaceXS),
              FeedbackSection(recording: recording),
            ],
          ),
        ),
      ),
    );
  }
}
