const _western = '0123456789';
const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';

/// [value] as text with Western digits replaced by Arabic-Indic ones
/// (`12` -> `١٢`). Every number shown inside Arabic text goes through this
/// (see CLAUDE.md); identifiers such as usernames and student codes stay
/// as typed.
String toArabicDigits(Object value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (final char in text.split('')) {
    final index = _western.indexOf(char);
    buffer.write(index < 0 ? char : _arabicIndic[index]);
  }
  return buffer.toString();
}
