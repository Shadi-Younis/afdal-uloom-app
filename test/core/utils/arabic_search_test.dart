import 'package:afdal_uloom_tilawat/core/utils/arabic_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeForSearch', () {
    test('every alef form becomes a bare alef', () {
      expect(normalizeForSearch('أحمد'), 'احمد');
      expect(normalizeForSearch('إبراهيم'), 'ابراهيم');
      expect(normalizeForSearch('آمنة'), 'امنه');
      expect(normalizeForSearch('ٱلله'), 'الله');
    });

    test('teh marbuta is heh, alef maksura is yeh', () {
      expect(normalizeForSearch('حمزة'), 'حمزه');
      expect(normalizeForSearch('عيسى'), 'عيسي');
      expect(normalizeForSearch('مصطفى'), 'مصطفي');
    });

    test('diacritics, tatweel and superscript alef are dropped', () {
      expect(normalizeForSearch('مُحَمَّدٌ'), 'محمد');
      expect(normalizeForSearch('يُوسُفْ'), 'يوسف');
      expect(normalizeForSearch('عبـــد'), 'عبد');
      expect(normalizeForSearch('الرَّحْمٰن'), 'الرحمن');
    });

    test('Latin is lower-cased; spaces are collapsed and trimmed', () {
      expect(normalizeForSearch('S013'), 's013');
      expect(normalizeForSearch('  عبد   الله '), 'عبد الله');
    });

    test('plain text is unchanged', () {
      expect(normalizeForSearch('خالد منصور'), 'خالد منصور');
      expect(normalizeForSearch(''), '');
    });
  });

  group('matchesSearch', () {
    test('finds أحمد when typing احمد, and the other way round', () {
      expect(matchesSearch('أحمد الخطيب', 'احمد'), isTrue);
      expect(matchesSearch('احمد الخطيب', 'أحمد'), isTrue);
      expect(matchesSearch('إبراهيم السيد', 'ابراهيم'), isTrue);
      expect(matchesSearch('حمزة عيسى', 'حمزه عيسي'), isTrue);
      expect(matchesSearch('مُحَمَّد', 'محمد'), isTrue);
    });

    test('matches a part of the text, codes in any case', () {
      expect(matchesSearch('S013', 's01'), isTrue);
      expect(matchesSearch('أنس جابر', 'جابر'), isTrue);
    });

    test('an empty query matches; a different name does not', () {
      expect(matchesSearch('عمر الحسن', ''), isTrue);
      expect(matchesSearch('عمر الحسن', 'خالد'), isFalse);
    });
  });
}
