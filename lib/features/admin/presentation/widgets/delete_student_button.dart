import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/widgets/common/app_snack_bar.dart';
import 'delete_student_dialog.dart';

/// "حذف نهائي" for [student]: the typed-confirmation dialog, then the
/// students list the page was opened from (all students, or the halaqa's).
class DeleteStudentButton extends StatelessWidget {
  const DeleteStudentButton({super.key, required this.student});

  final AppUser student;

  Future<void> _delete(BuildContext context) async {
    // Looked up now: once deleted, this page shows "not found".
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final list =
        AppRoutes.parentOf(GoRouterState.of(context).matchedLocation) ??
        AppRoutes.adminStudents;
    final deleted = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteStudentDialog(student: student),
    );
    if (deleted == null) return;
    router.go(list);
    showAppSnackBarOn(messenger, AppStrings.studentDeleted);
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return OutlinedButton.icon(
      onPressed: () => _delete(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: error,
        side: BorderSide(color: error),
      ),
      icon: const Icon(Icons.delete_forever_outlined),
      label: const Text(AppStrings.deleteStudent),
    );
  }
}
