import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_digits.dart';
import '../../../../core/widgets/islamic/islamic_star.dart';
import '../../application/halaqa_summary.dart';

/// A halaqa in the list: name, teacher and number of active students.
class HalaqaTile extends StatelessWidget {
  const HalaqaTile({super.key, required this.summary, required this.onTap});

  static const starSize = 36.0;

  final HalaqaSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const IslamicStar(size: HalaqaTile.starSize),
      title: Text(summary.halaqa.name),
      subtitle: Text(
        '${AppStrings.halaqaTeacher(summary.teacher?.fullName ?? AppStrings.unknownTeacher)}\n'
        '${AppStrings.studentCount(toArabicDigits(summary.activeStudentCount))}',
      ),
      isThreeLine: true,
      // chevron_right mirrors in RTL: it points left, "forward" in Arabic.
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
