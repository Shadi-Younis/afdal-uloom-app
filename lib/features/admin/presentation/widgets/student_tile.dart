import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/app_user.dart';
import 'disabled_chip.dart';

/// A student in a list: name, code and (unless [halaqaName] is null) the
/// halaqa, and "موقوف" when disabled.
class StudentTile extends StatelessWidget {
  const StudentTile({
    super.key,
    required this.student,
    required this.onTap,
    this.halaqaName,
  });

  final AppUser student;
  final VoidCallback onTap;

  /// Left out where the halaqa is obvious (its own details page).
  final String? halaqaName;

  @override
  Widget build(BuildContext context) {
    final code = student.studentCode ?? '';
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.menu_book_outlined)),
      title: Text(student.fullName),
      subtitle: Text(
        halaqaName == null
            ? code
            : '$code${AppStrings.detailSeparator}$halaqaName',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: student.disabled ? const DisabledChip() : null,
      onTap: onTap,
    );
  }
}
