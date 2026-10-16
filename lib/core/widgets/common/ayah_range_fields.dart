import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../utils/arabic_digits.dart';

/// «من آية» and «إلى آية» side by side, in either kind of digits; [error]
/// (e.g. «الآيات ليست في هذه السورة») under them.
class AyahRangeFields extends StatelessWidget {
  const AyahRangeFields({
    super.key,
    required this.from,
    required this.to,
    required this.onFromChanged,
    required this.onToChanged,
    this.error,
    this.enabled = true,
  });

  final int? from;
  final int? to;
  final ValueChanged<int?> onFromChanged;
  final ValueChanged<int?> onToChanged;

  /// Null: no error.
  final String? error;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _AyahField(
            label: AppStrings.ayahFromLabel,
            value: from,
            enabled: enabled,
            onChanged: onFromChanged,
            error: error,
          ),
        ),
        const SizedBox(width: AppSizes.spaceS),
        Expanded(
          child: _AyahField(
            label: AppStrings.ayahToLabel,
            value: to,
            enabled: enabled,
            onChanged: onToChanged,
          ),
        ),
      ],
    );
  }
}

class _AyahField extends StatelessWidget {
  const _AyahField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.error,
  });

  final String label;
  final int? value;
  final bool enabled;
  final ValueChanged<int?> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value == null ? '' : toArabicDigits(value!),
      enabled: enabled,
      keyboardType: TextInputType.number,
      onChanged: (text) => onChanged(parseTypedInt(text)),
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        errorMaxLines: 2,
      ),
    );
  }
}
