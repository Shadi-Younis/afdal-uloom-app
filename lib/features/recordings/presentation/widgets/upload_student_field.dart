import 'package:flutter/material.dart';

import '../../../../core/application/my_students_providers.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/arabic_search.dart';

/// The student of an uploaded file: type a name or a code (S014) and pick
/// one of [students], the only ones the uploader may upload for.
class UploadStudentField extends StatelessWidget {
  const UploadStudentField({
    super.key,
    required this.students,
    required this.studentId,
    required this.onChanged,
    this.enabled = true,
    this.showError = false,
  });

  final List<StudentInHalaqa> students;
  final String? studentId;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  /// «اختر طالباً من القائمة» under an empty field.
  final bool showError;

  static String label(StudentInHalaqa s) =>
      '${s.student.fullName}${AppStrings.detailSeparator}'
      '${s.student.studentCode ?? ''}${AppStrings.detailSeparator}'
      '${s.halaqa.name}';

  @override
  Widget build(BuildContext context) {
    final selected = students
        .where((s) => s.student.id == studentId)
        .firstOrNull;
    return Autocomplete<StudentInHalaqa>(
      initialValue: TextEditingValue(
        text: selected == null ? '' : label(selected),
      ),
      displayStringForOption: label,
      optionsBuilder: (value) {
        final query = normalizeForSearch(value.text);
        if (query.isEmpty) return students;
        return students.where(
          (s) => normalizeForSearch(
            '${s.student.fullName} ${s.student.studentCode ?? ''}',
          ).contains(query),
        );
      },
      onSelected: (s) => onChanged(s.student.id),
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            onChanged: (text) {
              // Typing again unselects; picking from the list selects.
              if (studentId != null) onChanged(null);
            },
            onSubmitted: (_) => onSubmitted(),
            decoration: InputDecoration(
              labelText: AppStrings.studentFieldLabel,
              hintText: AppStrings.searchStudents,
              prefixIcon: const Icon(Icons.person_search_outlined),
              errorText: showError && selected == null
                  ? AppStrings.studentNotYours
                  : null,
            ),
          ),
    );
  }
}
