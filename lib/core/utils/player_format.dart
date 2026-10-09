/// Text for the recording player: clock times and speeds, with
/// Arabic-Indic digits.
library;

import 'arabic_digits.dart';

/// `٠١:٢٣` (mm:ss), or `١:٠٢:٠٣` from one hour on.
String formatClock(Duration duration) {
  final seconds = duration.inSeconds;
  final mmss =
      '${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';
  final hours = seconds ~/ 3600;
  return toArabicDigits(hours > 0 ? '$hours:$mmss' : mmss);
}

/// `٠٫٧٥×`, `١×`, `١٫٢٥×`: whole speeds without decimals, the Arabic
/// decimal separator otherwise.
String formatSpeed(double speed) {
  final text = speed == speed.roundToDouble()
      ? speed.toInt().toString()
      : speed.toString();
  return '${toArabicDigits(text).replaceAll('.', '٫')}×';
}
