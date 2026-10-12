import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';

/// One line of the practice page that needs attention: an [icon] and
/// [text] in [color] (a warning, a refusal, a failure).
class PracticeNotice extends StatelessWidget {
  const PracticeNotice({
    super.key,
    required this.text,
    required this.color,
    required this.icon,
  });

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: AppSizes.spaceXS),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
