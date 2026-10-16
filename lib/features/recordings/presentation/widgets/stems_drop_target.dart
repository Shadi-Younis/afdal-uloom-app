import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/picked_audio_file.dart';
import '../../../../core/models/stem_role.dart';
import 'upload_drop_area.dart';

/// Builds a row in two-file mode with [zoneKeys] for its two drop zones
/// and the zone files hover over (null: none, or not the web).
typedef StemsDropBuilder = Widget Function(
  BuildContext context,
  Map<StemRole, GlobalKey> zoneKeys,
  StemRole? hovering,
);

/// On the web, files dropped anywhere on a two-file row go to that row
/// ([onFiles]), not to the page: two fill both zones, one goes to the zone
/// it was dropped on ([onFiles]'s `into`; null elsewhere on the row). The
/// zone under the files is highlighted. Elsewhere, or when not [enabled],
/// only the builder.
class StemsDropTarget extends StatefulWidget {
  const StemsDropTarget({
    super.key,
    required this.enabled,
    required this.onFiles,
    required this.builder,
  });

  final bool enabled;
  final void Function(List<PickedAudioFile> files, StemRole? into) onFiles;
  final StemsDropBuilder builder;

  @override
  State<StemsDropTarget> createState() => _StemsDropTargetState();
}

class _StemsDropTargetState extends State<StemsDropTarget> {
  final _area = GlobalKey();
  final _zones = {for (final role in StemRole.values) role: GlobalKey()};

  // Purely visual: the zone the dragged files are over.
  StemRole? _hovering;

  /// The page's claimed areas (UploadDropArea.claimsOf), kept for dispose.
  Set<GlobalKey>? _claims;

  bool get _active => widget.enabled && UploadDropArea.supported;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _claims?.remove(_area);
    _claims = UploadDropArea.claimsOf(context);
    _updateClaim();
  }

  @override
  void didUpdateWidget(StemsDropTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateClaim();
  }

  @override
  void dispose() {
    _claims?.remove(_area);
    super.dispose();
  }

  void _updateClaim() {
    if (_active) {
      _claims?.add(_area);
    } else {
      _claims?.remove(_area);
    }
  }

  StemRole? _zoneAt(Offset globalPosition) {
    for (final MapEntry(key: role, value: key) in _zones.entries) {
      if (isOver(key, globalPosition)) return role;
    }
    return null;
  }

  void _hover(Offset? globalPosition) {
    final zone = globalPosition == null ? null : _zoneAt(globalPosition);
    if (zone != _hovering) setState(() => _hovering = zone);
  }

  Future<void> _dropped(DropDoneDetails details) async {
    final zone = _zoneAt(details.globalPosition);
    _hover(null);
    final files = await pickedFilesOf(details);
    if (files.isEmpty || !mounted) return;
    widget.onFiles(files, files.length == 1 ? zone : null);
  }

  @override
  Widget build(BuildContext context) {
    final child = KeyedSubtree(
      key: _area,
      child: widget.builder(context, _zones, _active ? _hovering : null),
    );
    if (!_active) return child;
    return DropTarget(
      onDragEntered: (details) => _hover(details.globalPosition),
      onDragUpdated: (details) => _hover(details.globalPosition),
      onDragExited: (_) => _hover(null),
      onDragDone: _dropped,
      child: child,
    );
  }
}
