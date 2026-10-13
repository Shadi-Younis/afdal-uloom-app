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
///
/// A part of [child] that takes files itself (a two-file row,
/// StemsDropTarget) claims its area ([claimsOf]): files dropped there are
/// left to it.
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

  /// The keys of the widgets under the UploadDropArea above [context] that
  /// take dropped files themselves: add a widget's key to claim its area,
  /// remove it to give the area back. Null without such an area.
  static Set<GlobalKey>? claimsOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_Claims>()?.keys;

  @override
  State<UploadDropArea> createState() => _UploadDropAreaState();
}

/// The files of a drop, read only when their upload starts.
Future<List<PickedAudioFile>> pickedFilesOf(DropDoneDetails details) async => [
  for (final item in details.files)
    PickedAudioFile(
      name: item.name,
      sizeBytes: await item.length(),
      open: () async => BytesAudioSource(await item.readAsBytes()),
    ),
];

/// Whether [globalPosition] falls on the widget of [key].
bool isOver(GlobalKey key, Offset globalPosition) {
  final box = key.currentContext?.findRenderObject();
  if (box is! RenderBox || !box.attached || !box.hasSize) return false;
  return (box.localToGlobal(Offset.zero) & box.size).contains(globalPosition);
}

class _UploadDropAreaState extends State<UploadDropArea> {
  // Purely visual: whether files hover the page (not a claimed part).
  var _hovering = false;
  final _claimed = <GlobalKey>{};

  bool _isClaimed(Offset globalPosition) =>
      _claimed.any((key) => isOver(key, globalPosition));

  void _hover(Offset globalPosition) {
    final hovering = !_isClaimed(globalPosition);
    if (hovering != _hovering) setState(() => _hovering = hovering);
  }

  Future<void> _dropped(DropDoneDetails details) async {
    setState(() => _hovering = false);
    if (_isClaimed(details.globalPosition)) return;
    final files = await pickedFilesOf(details);
    if (files.isNotEmpty) widget.onFiles(files);
  }

  @override
  Widget build(BuildContext context) {
    if (!UploadDropArea.supported) return widget.child;
    return _Claims(
      keys: _claimed,
      child: DropTarget(
        enable: widget.enabled,
        onDragEntered: (details) => _hover(details.globalPosition),
        onDragUpdated: (details) => _hover(details.globalPosition),
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
      ),
    );
  }
}

/// The parts of the page that take dropped files themselves.
class _Claims extends InheritedWidget {
  const _Claims({required this.keys, required super.child});

  final Set<GlobalKey> keys;

  // The set changes without a rebuild: nobody depends on it.
  @override
  bool updateShouldNotify(_Claims oldWidget) => false;
}
