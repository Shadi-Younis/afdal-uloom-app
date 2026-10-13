import 'package:flutter/material.dart';

import '../../constants/app_strings.dart';
import '../../constants/surahs.dart';
import '../../utils/arabic_digits.dart';
import '../../utils/arabic_search.dart';

/// The surah of a recording (an uploaded file, a practice): type its name
/// or number (in either kind of digits) and pick it from the list.
class SurahField extends StatelessWidget {
  const SurahField({
    super.key,
    required this.surahNumber,
    required this.onChanged,
    this.enabled = true,
  });

  final int? surahNumber;
  final ValueChanged<int?> onChanged;
  final bool enabled;

  /// "٢. البقرة".
  static String label(Surah surah) =>
      '${toArabicDigits(surah.number)}. ${surah.nameAr}';

  @override
  Widget build(BuildContext context) {
    final selected = surahNumber == null ? null : surahByNumber(surahNumber!);
    return Autocomplete<Surah>(
      initialValue: TextEditingValue(
        text: selected == null ? '' : label(selected),
      ),
      displayStringForOption: label,
      optionsBuilder: (value) {
        final typed = value.text.trim();
        if (typed.isEmpty) return surahs;
        final number = parseTypedInt(typed);
        if (number != null) {
          return surahs.where((s) => s.number.toString().startsWith('$number'));
        }
        final query = normalizeForSearch(typed);
        return surahs.where(
          (s) => normalizeForSearch(s.nameAr).contains(query),
        );
      },
      onSelected: (surah) => onChanged(surah.number),
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            onChanged: (_) {
              if (surahNumber != null) onChanged(null);
            },
            onSubmitted: (_) => onSubmitted(),
            decoration: const InputDecoration(
              labelText: AppStrings.surahLabel,
              hintText: AppStrings.searchSurah,
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
          ),
    );
  }
}
