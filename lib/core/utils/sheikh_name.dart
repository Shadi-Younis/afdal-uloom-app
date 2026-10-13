import '../constants/app_strings.dart';

/// How a student sees his teacher: «الشيخ محمود», or «الشيخ» while the
/// name is unknown (a halaqa created before teacherName existed). A name
/// that already starts with «الشيخ» is not given the title twice.
String sheikhName(String? teacherName) {
  final name = teacherName?.trim() ?? '';
  if (name.isEmpty) return AppStrings.sheikh;
  if (name.startsWith(AppStrings.sheikh)) return name;
  return AppStrings.sheikhNamed(name);
}
