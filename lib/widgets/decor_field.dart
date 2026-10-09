import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Flat geometric background decor: circles, rounded squares, diamonds and a
/// dashed road line. Pure geometry at low opacity, parameterised by a seed so
/// each screen gets a different arrangement of the same vocabulary while the
/// vocabulary itself stays consistent.
class DecorField extends StatelessWidget {
  const DecorField({
    super.key,
    required this.seed,
    this.intensity = 1.0,
    this.dark = false,
  });

  final int seed;

  /// Scales every opacity, so a loader can be whisper-quiet and a tutorial
  /// can be loud with the same painter.
  final double intensity;

  /// Light shapes on a dark ground instead of the other way round.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _DecorPainter(seed: seed, intensity: intensity, dark: dark),
      ),
    );
  }
}

class _DecorPainter extends CustomPainter {
  _DecorPainter({
    required this.seed,
    required this.intensity,
    required this.dark,
  });

  final int seed;
  final double intensity;
  final bool dark;

  static const List<Color> _warm = <Color>[
    AppColors.primary,
    AppColors.success,
    AppColors.info,
    AppColors.secondary,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final math.Random rnd = math.Random(seed);
    final double w = size.width;
    final double h = size.height;
    final int shapes = 5 + rnd.nextInt(3);

    for (int i = 0; i < shapes; i++) {
      final Color base = dark
          ? AppColors.canvas
          : _warm[rnd.nextInt(_warm.length)];
      final double alpha = (dark ? 0.06 : 0.16) * intensity;
      final Paint paint = Paint()..color = base.withValues(alpha: alpha);

      final double cx = w * (0.08 + rnd.nextDouble() * 0.84);
      final double cy = h * (0.06 + rnd.nextDouble() * 0.88);
      final double d = w * (0.12 + rnd.nextDouble() * 0.26);

      switch (i % 3) {
        case 0:
          canvas.drawCircle(Offset(cx, cy), d / 2, paint);
        case 1:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, cy), width: d, height: d),
              Radius.circular(d * 0.28),
            ),
            paint,
          );
        default:
          final Path diamond = Path()
            ..moveTo(cx, cy - d / 2)
            ..lineTo(cx + d / 2, cy)
            ..lineTo(cx, cy + d / 2)
            ..lineTo(cx - d / 2, cy)
            ..close();
          canvas.drawPath(diamond, paint);
      }
    }

    _paintDashedRoad(canvas, size, rnd);
  }

  void _paintDashedRoad(Canvas canvas, Size size, math.Random rnd) {
    final Paint dash = Paint()
      ..color = (dark ? AppColors.canvas : AppColors.ink).withValues(
        alpha: (dark ? 0.08 : 0.12) * intensity,
      )
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final double y = size.height * (0.52 + rnd.nextDouble() * 0.2);
    const double dashLen = 10;
    const double gap = 10;
    double x = size.width * 0.06;
    while (x < size.width * 0.94) {
      canvas.drawLine(Offset(x, y), Offset(x + dashLen, y), dash);
      x += dashLen + gap;
    }
  }

  @override
  bool shouldRepaint(_DecorPainter old) {
    return old.seed != seed || old.intensity != intensity || old.dark != dark;
  }
}
