// Generates the web favicon and PWA icons. Run from the repo root after
// changing either source image:
//
//   dart run tool/generate_web_icons.dart
//
// flutter_launcher_icons cannot do this (its web output is turned off):
// it makes the maskable icons from the same image as the regular ones, so
// the launcher's mask crops the logo. app_icon_foreground.png is already
// padded to the maskable safe zone, on an opaque white background.
import 'dart:io';

import 'package:image/image.dart';

const _iconSource = 'assets/branding/app_icon.png';
const _maskableSource = 'assets/branding/app_icon_foreground.png';
const _faviconSize = 16;
const _iconSizes = [192, 512];

void main() {
  final icon = _decode(_iconSource);
  final maskable = _decode(_maskableSource);

  _writeResized(icon, _faviconSize, 'web/favicon.png');
  for (final size in _iconSizes) {
    _writeResized(icon, size, 'web/icons/Icon-$size.png');
    _writeResized(maskable, size, 'web/icons/Icon-maskable-$size.png');
  }
}

Image _decode(String path) {
  final image = decodePng(File(path).readAsBytesSync());
  if (image == null) throw FormatException('Not a PNG file', path);
  return image;
}

void _writeResized(Image source, int size, String path) {
  // Same resampling as flutter_launcher_icons, so the regular icons stay
  // byte-identical to the ones it generated before.
  final resized = copyResize(
    source,
    width: size,
    height: size,
    interpolation: Interpolation.average,
  );
  File(path).writeAsBytesSync(encodePng(resized));
  stdout.writeln('wrote $path (${size}x$size)');
}
