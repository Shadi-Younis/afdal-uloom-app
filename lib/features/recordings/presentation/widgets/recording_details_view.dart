import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/application/recording_player_controller.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/playback_source.dart';
import '../../../../core/models/recording.dart';
import '../../../../core/models/recording_type.dart';
import '../../../../core/providers/clock_provider.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import '../../../../core/widgets/common/recording_player.dart';
import '../../../../core/widgets/islamic/ornament_divider.dart';
import '../../application/analysis_notice.dart';
import '../../application/note_order.dart';
import '../../application/recording_details_providers.dart';
import '../../application/recording_manage_controller.dart';
import 'analysis_banner.dart';
import 'delete_recording_button.dart';
import 'edit_ayat_button.dart';
import 'feedback_section.dart';
import 'marker_navigation.dart';
import 'note_dialog.dart';
import 'recording_header.dart';
import 'reviewed_toggle.dart';
import 'swapped_chip.dart';

/// The content of the recording screen, at most
/// [AppSizes.contentMaxWidth] wide on the studio PC: the header (with
/// «تعديل السورة والآيات» for an official recording's teacher and admins),
/// the analysis state, the player (the centred copy when there is one) with the
/// sheikh's markers, and the notes. A two-file recording has no player
/// and no «تمت المراجعة» until the server joined its files (the banner
/// says why); its teacher also sees when the server swapped the student's
/// and sheikh's channels. Its teacher and admins also add notes
/// at the current second, mark it reviewed and delete it («حذف التسجيل»).
/// Its student only reads; opening it clears his «ملاحظات جديدة», and he
/// may delete his own practice («حذف التدريب»). Errors of these actions
/// show here, once, as a snack bar.
class RecordingDetailsView extends ConsumerWidget {
  const RecordingDetailsView({super.key, required this.recording});

  final Recording recording;

  Future<void> _addNoteHere(BuildContext context, WidgetRef ref) async {
    final player = ref.read(
      recordingPlayerControllerProvider(StoredPlayback(recording.playablePath))
          .notifier,
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
    ref.watch(feedbackReadMarkerProvider(recording.id));
    final canManage = ref.watch(
      canManageRecordingProvider(recording.teacherId),
    );
    final canDelete = ref.watch(canDeleteRecordingProvider(recording));
    ref.listen(recordingManageControllerProvider(recording.id), (_, next) {
      if (next case AsyncError(:final error)) showErrorSnackBar(context, error);
    });
    final source = StoredPlayback(recording.playablePath);
    final notes = ref.watch(recordingFeedbackProvider(recording.id)).value;
    final markers = markersOf(notes ?? const []);
    final notice = analysisNoticeFor(
      recording,
      ref.watch(clockProvider)(),
      canManage: canManage,
    );
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
              if (canManage && recording.type == RecordingType.official)
                EditAyatButton(recording: recording),
              const SizedBox(height: AppSizes.spaceM),
              if (canManage && recording.analysis?.swapped == true)
                const SwappedChip(),
              if (notice != null) AnalysisBanner(notice: notice),
              if (recording.hasAudio)
                RecordingPlayer(
                  source: source,
                  markers: markers,
                  footer: MarkerNavigation(
                    source: source,
                    markers: markers,
                    onAddNote: canManage
                        ? () => _addNoteHere(context, ref)
                        : null,
                  ),
                ),
              // Nothing to review before a two-file recording is joined
              // (or when joining it failed).
              if (canManage && recording.hasAudio)
                ReviewedToggle(recording: recording),
              const OrnamentDivider(title: AppStrings.feedbackTitle),
              const SizedBox(height: AppSizes.spaceXS),
              FeedbackSection(recording: recording, canManage: canManage),
              if (canDelete) ...[
                const SizedBox(height: AppSizes.spaceL),
                DeleteRecordingButton(recording: recording),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
