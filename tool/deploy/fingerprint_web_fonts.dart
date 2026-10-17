// Gives the web build's icon fonts a file name that changes with their
// content, so no browser keeps an old one. Run by deploy_web.ps1 right
// after `flutter build web --release`:
//
//   dart run tool/deploy/fingerprint_web_fonts.dart build/web
//
// Why: the release build tree-shakes MaterialIcons-Regular.otf (and
// CupertinoIcons.ttf) down to the icons the app uses, so the file changes
// with every deploy that uses a new icon, under the same URL. Hosting
// lets browsers cache fonts for a week (firebase.json), so a browser that
// cached an older subset showed the new icons as empty: the record
// button's microphone (Task 12). assets/FontManifest.json, which tells the
// app where each font is, is never cached, so renaming the files there is
// enough.
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/deploy/fingerprint_web_fonts.dart <build/web>',
    );
    exit(64);
  }
  final renamed = fingerprintWebFonts(Directory(args.single));
  renamed.forEach((from, to) => stdout.writeln('$from -> $to'));
}

/// Renames every font listed in [buildDir]/assets/FontManifest.json to
/// `<name>.<hash>.<ext>` (hash of its bytes) and points the manifest at the
/// new names. Returns the old asset paths with their new ones. A font
/// already renamed is left alone, so running it twice changes nothing.
/// Throws [FileSystemException] when the manifest or a font is missing.
Map<String, String> fingerprintWebFonts(Directory buildDir) {
  final assets = Directory('${buildDir.path}/assets');
  final manifestFile = File('${assets.path}/FontManifest.json');
  final manifest = jsonDecode(manifestFile.readAsStringSync()) as List;
  final renamed = <String, String>{};
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    for (final font in (family['fonts'] as List).cast<Map<String, dynamic>>()) {
      final asset = font['asset'] as String;
      if (_fingerprinted.hasMatch(asset)) continue;
      final file = File('${assets.path}/$asset');
      final hash = contentHash(file.readAsBytesSync());
      final dot = asset.lastIndexOf('.');
      final newAsset =
          '${asset.substring(0, dot)}.$hash${asset.substring(dot)}';
      file.renameSync('${assets.path}/$newAsset');
      font['asset'] = newAsset;
      renamed[asset] = newAsset;
    }
  }
  manifestFile.writeAsStringSync(jsonEncode(manifest));
  return renamed;
}

final _fingerprinted = RegExp(r'\.[0-9a-f]{8}\.[a-z0-9]+$');

/// 8 hex digits of the 32-bit FNV-1a hash of [bytes]: enough to tell two
/// builds of one font apart, without a package.
String contentHash(List<int> bytes) {
  var hash = 0x811c9dc5;
  for (final byte in bytes) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
