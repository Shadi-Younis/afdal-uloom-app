import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';

/// The surah's name in a green frame with pointed ends, a double gold
/// border and gold end dots, like a surah heading in a mushaf. Takes the
/// full width; the title shrinks to fit and never overflows.
class SurahCartouche extends StatelessWidget {
  const SurahCartouche({super.key, required this.title});

  final String title;

  static const height = 74.0;

  /// Keeps the title inside the frame's pointed ends.
  static const _titleInset = 56.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: const SurahCartouchePainter(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _titleInset),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 1,
                  style: AppTextStyles.of(context).surahTitle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The frame of [SurahCartouche]: the mockup's SVG (324 x 74), stretched to
/// the available width like `preserveAspectRatio="none"`.
class SurahCartouchePainter extends CustomPainter {
  const SurahCartouchePainter();

  static const _w = 324.0;
  static const _h = 74.0;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _w;
    final sy = size.height / _h;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    Path frame(List<Offset> points) => Path()..addPolygon(points, true);

    final outer = frame([
      p(18, 37),
      p(40, 6),
      p(284, 6),
      p(306, 37),
      p(284, 68),
      p(40, 68),
    ]);
    final inner = frame([
      p(26, 37),
      p(45, 11),
      p(279, 11),
      p(298, 37),
      p(279, 63),
      p(45, 63),
    ]);
    canvas
      ..drawPath(outer, Paint()..color = AppColors.green)
      ..drawPath(
        outer,
        Paint()
          ..color = AppColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      )
      ..drawPath(
        inner,
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    final dot = Paint()..color = AppColors.gold;
    final radius = 4 * sy;
    canvas
      ..drawCircle(p(12, 37), radius, dot)
      ..drawCircle(p(312, 37), radius, dot);
  }

  @override
  bool shouldRepaint(SurahCartouchePainter old) => false;
}
