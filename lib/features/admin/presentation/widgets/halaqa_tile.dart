import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../application/halaqa_summary.dart';

/// A halaqa in the list: name, teacher and number of active students.
class HalaqaTile extends StatelessWidget {
  const HalaqaTile({super.key, required this.summary, required this.onTap});

  final HalaqaSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.groups_outlined)),
      title: Text(summary.halaqa.name),
      subtitle: Text(
        '${AppStrings.halaqaTeacher(summary.teacher?.fullName ?? AppStrings.unknownTeacher)}\n'
        '${AppStrings.studentCount(summary.activeStudentCount)}',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_left),
      onTap: onTap,
    );
  }
}
