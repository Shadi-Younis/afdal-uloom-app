import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

/// THE 8-point star of the app (docs/design/star_closeup.png): two green
/// squares, one turned 45°, with a gold outline; inside, a smaller gold
/// outline star, eight gold dots on a ring and a gold center. Every
/// 8-point star in the app is this widget.
class IslamicStar extends StatelessWidget {
  const IslamicStar({
    super.key,
    this.size = 30,
    this.color = AppColors.green,
    this.gold = AppColors.gold,
    this.semanticLabel,
  });

  final double size;

  /// The star's fill.
  final Color color;

  /// Outlines, dots and center.
  final Color gold;

  /// Null: purely decorative, hidden from screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final star = CustomPaint(
      size: Size.square(size),
      painter: IslamicStarPainter(color: color, gold: gold),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: star)
        : Semantics(label: semanticLabel, image: true, child: star);
  }
}

/// Paints [IslamicStar]; the geometry is the approved SVG's, in a 40-unit
/// box scaled to the canvas.
class IslamicStarPainter extends CustomPainter {
  const IslamicStarPainter({required this.color, required this.gold});

  final Color color;
  final Color gold;

  static const _box = 40.0;
  static const _outer = 13.0;
  // Covers the inner half of the outer strokes, leaving only the star's
  // outline (as the SVG's third square does).
  static const _cover = 12.2;
  static const _inner = 7.0;
  static const _center = 3.0;
  static const _ringRadius = 10.5;
  static const _dotRadius = 0.9;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = min(size.width, size.height) / _box;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(scale);

    final fill = Paint()..color = color;
    final outline = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final thin = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final dot = Paint()..color = gold;

    void square(double half, Paint paint, {bool turned = false}) {
      canvas.save();
      if (turned) canvas.rotate(pi / 4);
      canvas.drawRect(Rect.fromLTRB(-half, -half, half, half), paint);
      canvas.restore();
    }

    for (final turned in [false, true]) {
      square(_outer, fill, turned: turned);
      square(_outer, outline, turned: turned);
    }
    square(_cover, fill);
    square(_inner, thin);
    square(_inner, thin, turned: true);
    canvas.drawCircle(Offset.zero, _center, dot);
    for (var i = 0; i < 8; i++) {
      final angle = pi / 8 + i * pi / 4;
      canvas.drawCircle(
        Offset(cos(angle), sin(angle)) * _ringRadius,
        _dotRadius,
        dot,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(IslamicStarPainter old) =>
      old.color != color || old.gold != gold;
}
