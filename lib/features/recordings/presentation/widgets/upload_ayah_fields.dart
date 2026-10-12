import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_digits.dart';

/// «من آية» and «إلى آية» side by side, in either kind of digits;
/// «الآيات ليست في هذه السورة» under them when [invalid].
class UploadAyahFields extends StatelessWidget {
  const UploadAyahFields({
    super.key,
    required this.from,
    required this.to,
    required this.onFromChanged,
    required this.onToChanged,
    this.invalid = false,
    this.enabled = true,
  });

  final int? from;
  final int? to;
  final ValueChanged<int?> onFromChanged;
  final ValueChanged<int?> onToChanged;
  final bool invalid;
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
            error: invalid ? AppStrings.ayatNotInSurah : null,
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
