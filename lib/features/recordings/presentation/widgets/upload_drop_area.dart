import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../app/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/audio_source.dart';
import '../../../../core/models/picked_audio_file.dart';

/// On the web (the studio PC), files dragged from Studio One's export
/// folder can be dropped anywhere on [child]; while they hover a gold
/// frame says «أفلت الملفات هنا». Elsewhere [child] alone: phones pick
/// files with the button.
class UploadDropArea extends StatefulWidget {
  const UploadDropArea({
    super.key,
    required this.onFiles,
    required this.child,
    this.enabled = true,
  });

  final ValueChanged<List<PickedAudioFile>> onFiles;
  final Widget child;
  final bool enabled;

  /// Whether this platform takes dropped files (desktop_drop's web
  /// support; the iOS plugin does not exist).
  static bool get supported => kIsWeb;

  @override
  State<UploadDropArea> createState() => _UploadDropAreaState();
}

class _UploadDropAreaState extends State<UploadDropArea> {
  // Purely visual: whether files hover the page.
  var _hovering = false;

  Future<void> _dropped(DropDoneDetails details) async {
    setState(() => _hovering = false);
    final files = [
      for (final item in details.files)
        PickedAudioFile(
          name: item.name,
          sizeBytes: await item.length(),
          // Read only when its upload starts.
          open: () async => BytesAudioSource(await item.readAsBytes()),
        ),
    ];
    if (files.isNotEmpty) widget.onFiles(files);
  }

  @override
  Widget build(BuildContext context) {
    if (!UploadDropArea.supported) return widget.child;
    return DropTarget(
      enable: widget.enabled,
      onDragEntered: (_) => setState(() => _hovering = true),
      onDragExited: (_) => setState(() => _hovering = false),
      onDragDone: _dropped,
      child: Stack(
        children: [
          widget.child,
          if (_hovering)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.all(AppSizes.spaceS),
                  decoration: BoxDecoration(
                    color: AppColors.goldTint,
                    border: Border.all(
                      color: AppColors.gold,
                      width: AppSizes.focusBorder,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    AppStrings.dropNow,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: AppColors.goldDark),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
