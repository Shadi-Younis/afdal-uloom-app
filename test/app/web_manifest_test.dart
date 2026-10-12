import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:afdal_uloom_tilawat/app/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';

/// The web app installed as a Windows app from Edge / Chrome takes its
/// window title, icon and colors from web/manifest.json.
void main() {
  final manifest = jsonDecode(
    File('web/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  String hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  test('our name, Arabic and right-to-left, as a standalone app', () {
    expect(manifest['name'], 'أفضل العلوم');
    expect(manifest['short_name'], 'أفضل العلوم');
    expect(manifest['lang'], 'ar');
    expect(manifest['dir'], 'rtl');
    expect(manifest['display'], 'standalone');
  });

  test('the colors of AppColors: green bar, ivory background', () {
    expect(manifest['theme_color'], hex(AppColors.green));
    expect(manifest['background_color'], hex(AppColors.ivory));
    final html = File('web/index.html').readAsStringSync();
    expect(html, contains('<meta name="theme-color" content="#0B4019">'));
  });

  test('icons 192, 512 and a maskable 512, and every file exists', () {
    final icons = (manifest['icons'] as List).cast<Map<String, dynamic>>();
    String? find(String sizes, {bool maskable = false}) => icons
        .where(
          (i) =>
              i['sizes'] == sizes && (i['purpose'] == 'maskable') == maskable,
        )
        .map((i) => i['src'] as String)
        .firstOrNull;
    expect(find('192x192'), isNotNull);
    expect(find('512x512'), isNotNull);
    expect(find('512x512', maskable: true), isNotNull);
    for (final icon in icons) {
      expect(File('web/${icon['src']}').existsSync(), isTrue, reason: '$icon');
    }
  });
}
