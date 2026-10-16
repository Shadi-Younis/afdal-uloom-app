/// One hadith of «حديث اليوم» (DailyHadiths.all).
class DailyHadith {
  const DailyHadith(this.text, [this.source]);

  /// The words of the Prophet ﷺ, with their tashkeel, without quotation
  /// marks (the card adds « »).
  final String text;

  /// Where it is narrated, shown small under it; null when not given.
  final String? source;

  @override
  bool operator ==(Object other) =>
      other is DailyHadith && other.text == text && other.source == source;

  @override
  int get hashCode => Object.hash(text, source);

  @override
  String toString() => 'DailyHadith($text, source: $source)';
}
