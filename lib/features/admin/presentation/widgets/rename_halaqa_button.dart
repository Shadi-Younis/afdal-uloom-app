import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/halaqa.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import 'rename_halaqa_dialog.dart';

/// "تغيير الاسم" of [halaqa], through [RenameHalaqaDialog].
class RenameHalaqaButton extends StatelessWidget {
  const RenameHalaqaButton({super.key, required this.halaqa});

  final Halaqa halaqa;

  Future<void> _rename(BuildContext context) async {
    final renamed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RenameHalaqaDialog(halaqa: halaqa),
    );
    if ((renamed ?? false) && context.mounted) {
      showAppSnackBar(context, AppStrings.halaqaRenamed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _rename(context),
      icon: const Icon(Icons.edit_outlined),
      label: const Text(AppStrings.renameHalaqa),
    );
  }
}
