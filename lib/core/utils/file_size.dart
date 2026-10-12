import '../constants/app_strings.dart';
import 'arabic_digits.dart';

const _bytesPerMegabyte = 1024 * 1024;

/// "٣٫٢ ميغابايت": a file's size in megabytes, one decimal, Arabic digits.
String formatFileSize(int bytes) {
  final megabytes = (bytes / _bytesPerMegabyte).toStringAsFixed(1);
  return AppStrings.fileSize(toArabicDigits(megabytes).replaceAll('.', '٫'));
}
