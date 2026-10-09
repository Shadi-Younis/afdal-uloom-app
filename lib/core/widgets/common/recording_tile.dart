import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../constants/surahs.dart';
import '../../models/recording.dart';
import '../../utils/date_format.dart';
import 'recording_type_chip.dart';

/// A recording in a list: title (surah and ayat), recorded date, type, and
/// a dot when it has feedback the student has not read.
class RecordingTile extends StatelessWidget {
  const RecordingTile({
    super.key,
    required this.recording,
    required this.onTap,
  });

  final Recording recording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = recording;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.graphic_eq)),
      title: Text(formatRecordingTitle(r.surahNumber, r.ayahFrom, r.ayahTo)),
      subtitle: Text(formatDay(r.recordedAt)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (r.unreadFeedback) ...[
            const _UnreadDot(),
            const SizedBox(width: AppSizes.spaceXS),
          ],
          RecordingTypeChip(type: r.type),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.unreadFeedback,
      child: Tooltip(
        message: AppStrings.unreadFeedback,
        child: Container(
          width: AppSizes.unreadDot,
          height: AppSizes.unreadDot,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
