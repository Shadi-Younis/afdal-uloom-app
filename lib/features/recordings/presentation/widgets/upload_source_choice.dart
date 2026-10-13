import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/recording_source.dart';

/// «ملف واحد (يسار/يمين)» or «ملفين: الطالب + الشيخ» for one recording of
/// the upload page.
class UploadSourceChoice extends StatelessWidget {
  const UploadSourceChoice({
    super.key,
    required this.source,
    required this.onChanged,
  });

  final RecordingSource source;

  /// Null while the row cannot be edited.
  final ValueChanged<RecordingSource>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return SegmentedButton<RecordingSource>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: RecordingSource.stereo,
          icon: Icon(Icons.audio_file_outlined),
          label: Text(AppStrings.sourceOneFile),
        ),
        ButtonSegment(
          value: RecordingSource.stems,
          icon: Icon(Icons.library_music_outlined),
          label: Text(AppStrings.sourceTwoFiles),
        ),
      ],
      selected: {source},
      onSelectionChanged: onChanged == null
          ? null
          : (selected) => onChanged(selected.single),
    );
  }
}
