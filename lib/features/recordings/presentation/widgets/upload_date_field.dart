import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_format.dart';

/// The day a file was recorded: the date, tapping it opens the calendar
/// (no day after [today]).
class UploadDateField extends StatelessWidget {
  const UploadDateField({
    super.key,
    required this.day,
    required this.today,
    required this.onChanged,
    this.enabled = true,
  });

  final DateTime day;
  final DateTime today;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: day.isAfter(today) ? today : day,
      firstDate: DateTime(today.year - 5),
      lastDate: today,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _pick(context) : null,
      child: InputDecorator(
        isEmpty: false,
        decoration: InputDecoration(
          labelText: AppStrings.recordedAtLabel,
          prefixIcon: const Icon(Icons.event_outlined),
          enabled: enabled,
        ),
        child: Text(formatDay(day)),
      ),
    );
  }
}
