import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

/// [child] on a faint tiled 8-point geometric pattern in gold, as in the
/// mockup. Painted once into its own layer (RepaintBoundary, never
/// repainted on scroll); put it behind scrolling content, not inside it.
class IslamicPatternBackground extends StatelessWidget {
  const IslamicPatternBackground({
    super.key,
    required this.child,
    this.opacity = onIvory,
    this.color = AppColors.gold,
  });

  /// The pattern's strength on ivory pages.
  static const onIvory = 0.09;

  /// The pattern's strength on the green header.
  static const onGreen = 0.18;

  final Widget child;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: CustomPaint(
                isComplex: true,
                painter: IslamicPatternPainter(
                  color: color.withValues(alpha: opacity),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Tiles of the mockup's pattern: in each 56 px tile a square, the same
/// square turned 45° (an 8-point star) and a small circle.
class IslamicPatternPainter extends CustomPainter {
  const IslamicPatternPainter({required this.color});

  final Color color;

  static const tile = 56.0;
  static const _half = 14.0;
  static const _circle = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final square = Rect.fromLTRB(-_half, -_half, _half, _half);
    for (var y = 0.0; y < size.height; y += tile) {
      for (var x = 0.0; x < size.width; x += tile) {
        canvas
          ..save()
          ..translate(x + tile / 2, y + tile / 2)
          ..drawRect(square, stroke)
          ..drawCircle(Offset.zero, _circle, stroke)
          ..rotate(pi / 4)
          ..drawRect(square, stroke)
          ..restore();
      }
    }
  }

  @override
  bool shouldRepaint(IslamicPatternPainter old) => old.color != color;
}
