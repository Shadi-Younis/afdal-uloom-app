import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/application/recording_player_controller.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/player_marker.dart';
import '../../application/note_order.dart';

/// Under the player: «السابق» / «التالي» jump between the [markers] and
/// play from there; for the recording's teacher and admins, «إضافة ملاحظة
/// هنا» ([onAddNote]) as well.
class MarkerNavigation extends ConsumerWidget {
  const MarkerNavigation({
    super.key,
    required this.storagePath,
    required this.markers,
    this.onAddNote,
  });

  /// The player's audio (RecordingPlayer.storagePath).
  final String storagePath;
  final List<PlayerMarker> markers;
  final VoidCallback? onAddNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = recordingPlayerControllerProvider(storagePath);
    final position = ref.watch(provider.select((s) => s.position));
    final previous = previousMarkerBefore(position, markers);
    final next = nextMarkerAfter(position, markers);
    Future<void> jump(Duration to) async {
      final player = ref.read(provider.notifier);
      await player.seek(to);
      await player.play();
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSizes.spaceS,
      runSpacing: AppSizes.spaceXS,
      children: [
        if (markers.isNotEmpty) ...[
          // In RTL "previous" sits at the start (right), like "back 5 s".
          OutlinedButton.icon(
            onPressed: previous == null ? null : () => jump(previous),
            icon: const Icon(Icons.skip_previous),
            label: const Text(AppStrings.previousMarker),
          ),
          OutlinedButton.icon(
            onPressed: next == null ? null : () => jump(next),
            icon: const Icon(Icons.skip_next),
            label: const Text(AppStrings.nextMarker),
          ),
        ],
        if (onAddNote case final add?)
          FilledButton.icon(
            onPressed: add,
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text(AppStrings.addNoteHere),
          ),
      ],
    );
  }
}
