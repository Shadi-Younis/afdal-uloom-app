import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/deploy/fingerprint_web_fonts.dart';

void main() {
  late Directory build;

  setUp(() {
    build = Directory.systemTemp.createTempSync('web_build');
    File('${build.path}/assets/fonts/MaterialIcons-Regular.otf')
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);
    File(
        '${build.path}/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
      )
      ..createSync(recursive: true)
      ..writeAsBytesSync([4, 5]);
    File('${build.path}/assets/FontManifest.json').writeAsStringSync(
      jsonEncode([
        {
          'family': 'MaterialIcons',
          'fonts': [
            {'asset': 'fonts/MaterialIcons-Regular.otf'},
          ],
        },
        {
          'family': 'packages/cupertino_icons/CupertinoIcons',
          'fonts': [
            {'asset': 'packages/cupertino_icons/assets/CupertinoIcons.ttf'},
          ],
        },
      ]),
    );
  });
  tearDown(() => build.deleteSync(recursive: true));

  List<String> manifestAssets() => [
    for (final family in jsonDecode(
      File('${build.path}/assets/FontManifest.json').readAsStringSync(),
    ) as List)
      for (final font in family['fonts'] as List) font['asset'] as String,
  ];

  test('renames each font by its content and updates the manifest', () {
    final renamed = fingerprintWebFonts(build);
    final material =
        'fonts/MaterialIcons-Regular.${contentHash([1, 2, 3])}.otf';
    expect(renamed['fonts/MaterialIcons-Regular.otf'], material);
    expect(manifestAssets(), [
      material,
      'packages/cupertino_icons/assets/'
          'CupertinoIcons.${contentHash([4, 5])}.ttf',
    ]);
    expect(File('${build.path}/assets/$material').readAsBytesSync(), [1, 2, 3]);
    expect(
      File('${build.path}/assets/fonts/MaterialIcons-Regular.otf').existsSync(),
      isFalse,
    );
  });

  test('another subset of the icons gets another name', () {
    expect(contentHash([1, 2, 3]), hasLength(8));
    expect(contentHash([1, 2, 3]), isNot(contentHash([1, 2, 4])));
    expect(contentHash([1, 2, 3]), contentHash([1, 2, 3]));
  });

  test('running it twice changes nothing', () {
    fingerprintWebFonts(build);
    final once = manifestAssets();
    expect(fingerprintWebFonts(build), isEmpty);
    expect(manifestAssets(), once);
  });

  test('a missing font fails loudly', () {
    File('${build.path}/assets/fonts/MaterialIcons-Regular.otf').deleteSync();
    expect(
      () => fingerprintWebFonts(build),
      throwsA(isA<FileSystemException>()),
    );
  });
}
