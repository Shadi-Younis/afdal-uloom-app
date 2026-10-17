import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/recording.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import 'ayat_dialog.dart';

/// «تعديل السورة والآيات» under the recording's header, for its teacher
/// and admins: the upload may have left them out.
class EditAyatButton extends StatelessWidget {
  const EditAyatButton({super.key, required this.recording});

  final Recording recording;

  Future<void> _edit(BuildContext context) async {
    final saved = await showAyatDialog(context, recording);
    if (saved && context.mounted) {
      showAppSnackBar(context, AppStrings.ayatSaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.edit_outlined),
        label: const Text(AppStrings.editAyat),
      ),
    );
  }
}
