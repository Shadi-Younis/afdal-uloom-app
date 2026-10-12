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

/// [text] with Arabic-Indic digits turned back into Western ones
/// (`١٢` -> `12`), for numbers people type on an Arabic keyboard.
String fromArabicDigits(String text) {
  final buffer = StringBuffer();
  for (final char in text.split('')) {
    final index = _arabicIndic.indexOf(char);
    buffer.write(index < 0 ? char : _western[index]);
  }
  return buffer.toString();
}

/// The whole number typed in [text] in either kind of digits, or null.
int? parseTypedInt(String text) => int.tryParse(fromArabicDigits(text.trim()));
