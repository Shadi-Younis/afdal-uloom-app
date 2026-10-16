import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/stem_role.dart';
import '../../application/upload_row.dart';
import 'stem_zone.dart';

/// The two files of a row in two-file mode: «صوت الطالب» and «صوت الشيخ»
/// side by side on a wide card (stacked on a phone), with «تبديل» between
/// them. [zoneKeys] mark the zones for dropped files (StemsDropTarget).
class StemDropZones extends StatelessWidget {
  const StemDropZones({
    super.key,
    required this.row,
    required this.zoneKeys,
    required this.hovering,
    required this.onPick,
    required this.onSwap,
  });

  final UploadRow row;
  final Map<StemRole, GlobalKey> zoneKeys;
  final StemRole? hovering;

  /// Null while the row cannot be edited.
  final ValueChanged<StemRole>? onPick;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final onPick = this.onPick;
    Widget zone(StemRole role) => StemZone(
      key: zoneKeys[role],
      role: role,
      file: row.stemFile(role),
      duration: row.stemDuration(role),
      hovering: hovering == role,
      onPick: onPick == null ? null : () => onPick(role),
    );
    final swap = OutlinedButton.icon(
      onPressed: onSwap,
      icon: const Icon(Icons.swap_horiz),
      label: const Text(AppStrings.swapStems),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppSizes.uploadTwoColumnsMinWidth) {
          // Both zones as tall as the taller one.
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: zone(StemRole.student)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spaceS,
                  ),
                  child: Center(child: swap),
                ),
                Expanded(child: zone(StemRole.sheikh)),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            zone(StemRole.student),
            Center(child: swap),
            zone(StemRole.sheikh),
          ],
        );
      },
    );
  }
}
