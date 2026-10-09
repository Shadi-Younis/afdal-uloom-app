import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../application/teacher_summary.dart';
import 'disabled_chip.dart';

/// A teacher in the list: name, username, their halaqat, and "موقوف" when
/// disabled.
class TeacherTile extends StatelessWidget {
  const TeacherTile({super.key, required this.summary, required this.onTap});

  final TeacherSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final teacher = summary.teacher;
    final halaqat = summary.halaqat.isEmpty
        ? AppStrings.withoutHalaqa
        : summary.halaqat.map((h) => h.name).join(AppStrings.listSeparator);
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(teacher.fullName),
      subtitle: Text('${teacher.username}\n$halaqat'),
      isThreeLine: true,
      trailing: teacher.disabled ? const DisabledChip() : null,
      onTap: onTap,
    );
  }
}
