import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/application/recording_player_controller.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/recording.dart';
import '../../../../core/providers/clock_provider.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import '../../../../core/widgets/common/recording_player.dart';
import '../../../../core/widgets/islamic/ornament_divider.dart';
import '../../application/analysis_notice.dart';
import '../../application/note_order.dart';
import '../../application/recording_details_providers.dart';
import 'analysis_banner.dart';
import 'feedback_section.dart';
import 'marker_navigation.dart';
import 'note_dialog.dart';
import 'recording_header.dart';
import 'reviewed_toggle.dart';

/// The content of the recording screen, at most
/// [AppSizes.contentMaxWidth] wide on the studio PC: the header, the
/// analysis state, the player (the centred copy when there is one) with the
/// sheikh's markers, and the notes. Its teacher and admins also add notes
/// at the current second and mark it reviewed; a student only reads.
class RecordingDetailsView extends ConsumerWidget {
  const RecordingDetailsView({super.key, required this.recording});

  final Recording recording;

  Future<void> _addNoteHere(BuildContext context, WidgetRef ref) async {
    final player = ref.read(
      recordingPlayerControllerProvider(recording.playablePath).notifier,
    );
    await player.pause();
    if (!context.mounted) return;
    final saved = await showNoteDialog(
      context,
      recordingId: recording.id,
      atSecond: player.position.inSeconds,
    );
    if (saved && context.mounted) {
      showAppSnackBar(context, AppStrings.noteSaved);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(
      canManageRecordingProvider(recording.teacherId),
    );
    final notes = ref.watch(recordingFeedbackProvider(recording.id)).value;
    final markers = markersOf(notes ?? const []);
    final notice = analysisNoticeFor(recording, ref.watch(clockProvider)());
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
              if (notice != null) AnalysisBanner(notice: notice),
              RecordingPlayer(
                storagePath: recording.playablePath,
                markers: markers,
                footer: MarkerNavigation(
                  storagePath: recording.playablePath,
                  markers: markers,
                  onAddNote: canManage
                      ? () => _addNoteHere(context, ref)
                      : null,
                ),
              ),
              if (canManage) ReviewedToggle(recording: recording),
              const OrnamentDivider(title: AppStrings.feedbackTitle),
              const SizedBox(height: AppSizes.spaceXS),
              FeedbackSection(recording: recording, canManage: canManage),
            ],
          ),
        ),
      ),
    );
  }
}
