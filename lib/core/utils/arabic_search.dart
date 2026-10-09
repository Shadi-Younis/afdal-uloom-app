/// Search keys for Arabic names: what a user types should find a name
/// whatever its diacritics or hamza spelling.
library;

// Harakat, tanween, shadda, sukun and the Quranic marks around them.
const _harakatFirst = 0x064B;
const _harakatLast = 0x065F;
const _quranicMarksFirst = 0x0610;
const _quranicMarksLast = 0x061A;
const _annotationMarksFirst = 0x06D6;
const _annotationMarksLast = 0x06ED;
const _superscriptAlef = 0x0670;
const _tatweel = 0x0640;

const _alef = 0x0627;
const _heh = 0x0647;
const _yeh = 0x064A;

/// Letters searched as another: every alef form as bare alef, teh marbuta
/// as heh, alef maksura as yeh.
const _sameLetter = {
  0x0622: _alef, // آ
  0x0623: _alef, // أ
  0x0625: _alef, // إ
  0x0671: _alef, // ٱ (alef wasla)
  0x0629: _heh, // ة
  0x0649: _yeh, // ى
};

final _spaces = RegExp(r'\s+');

/// [text] as a search key: without diacritics and tatweel, with
/// أ/إ/آ/ٱ → ا, ة → ه, ى → ي, lower-cased (for codes such as `S013`), and
/// with runs of spaces collapsed. Compare keys with `contains`.
String normalizeForSearch(String text) {
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    if (_isIgnored(rune)) continue;
    buffer.writeCharCode(_sameLetter[rune] ?? rune);
  }
  return buffer.toString().replaceAll(_spaces, ' ').trim();
}

/// Whether [text] matches the search [query] (both normalized). An empty
/// query matches everything.
bool matchesSearch(String text, String query) =>
    normalizeForSearch(text).contains(normalizeForSearch(query));

bool _isIgnored(int rune) =>
    (rune >= _harakatFirst && rune <= _harakatLast) ||
    (rune >= _quranicMarksFirst && rune <= _quranicMarksLast) ||
    (rune >= _annotationMarksFirst && rune <= _annotationMarksLast) ||
    rune == _superscriptAlef ||
    rune == _tatweel;
