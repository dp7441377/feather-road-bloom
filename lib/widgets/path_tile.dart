import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/path_piece.dart';
import '../theme.dart';

/// One board cell.
///
/// Drawn with a [CustomPainter] rather than an AI sprite on purpose: route
/// fragments rotate in exact 90-degree steps and have to butt up seamlessly
/// against their neighbours. A generated PNG carries its own internal bbox and
/// padding, so rotated sprites would visibly misalign at the tile seams.
class PathTile extends StatelessWidget {
  const PathTile({
    super.key,
    required this.piece,
    required this.size,
    required this.bloom,
    this.onRoute = false,
    this.selected = false,
    this.highlighted = false,
    this.onTap,
  });

  final PathPiece piece;
  final double size;

  /// 0..1 colour lerp towards the live-route green.
  final double bloom;

  final bool onRoute;
  final bool selected;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: CustomPaint(
            painter: PathTilePainter(
              piece: piece,
              bloomT: onRoute ? bloom : 0.0,
              selected: selected,
              highlighted: highlighted,
            ),
          ),
        ),
      ),
    );
  }
}

class PathTilePainter extends CustomPainter {
  PathTilePainter({
    required this.piece,
    required this.bloomT,
    required this.selected,
    required this.highlighted,
  });

  final PathPiece piece;
  final double bloomT;
  final bool selected;
  final bool highlighted;

  @override
  void paint(Canvas canvas, Size size) {
    const double inset = 3.0;
    final Rect face = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final RRect faceRRect = RRect.fromRectAndRadius(
      face,
      const Radius.circular(16),
    );

    if (piece.kind == PieceKind.blocked) {
      canvas.drawRRect(
        faceRRect,
        Paint()..color = AppColors.ink.withValues(alpha: 0.10),
      );
      canvas.drawRRect(
        faceRRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.ink.withValues(alpha: 0.14),
      );
      return;
    }

    // Clay face.
    canvas.drawRRect(faceRRect, Paint()..color = AppColors.surfaceSunken);
    canvas.drawRRect(
      faceRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.edge,
    );

    if (piece.kind == PieceKind.grass) {
      _paintGrass(canvas, size);
    } else {
      _paintRoute(canvas, size);
    }

    if (highlighted && !selected) {
      canvas.drawRRect(
        faceRRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.info.withValues(alpha: 0.35),
      );
    }
    if (selected) {
      canvas.drawRRect(
        faceRRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = AppColors.info,
      );
    }
  }

  void _paintGrass(Canvas canvas, Size size) {
    final Paint blade = Paint()
      ..color = AppColors.success.withValues(alpha: 0.5)
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round;
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double h = size.height * 0.14;
    for (int i = -1; i <= 1; i++) {
      final double x = cx + i * size.width * 0.16;
      canvas.drawLine(
        Offset(x, cy + h),
        Offset(x + i * size.width * 0.05, cy - h),
        blade,
      );
    }
  }

  void _paintRoute(Canvas canvas, Size size) {
    final Color stroke = Color.lerp(
      AppColors.routeInert,
      AppColors.success,
      bloomT.clamp(0.0, 1.0),
    )!;

    final Paint paint = Paint()
      ..color = stroke
      ..strokeWidth = size.width * 0.30
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double reach = size.width / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(piece.rotation * math.pi / 2);

    switch (piece.kind) {
      case PieceKind.straight:
        canvas.drawLine(Offset(0, -reach), Offset(0, reach), paint);
      case PieceKind.corner:
        canvas.drawLine(Offset(0, -reach), Offset.zero, paint);
        canvas.drawLine(Offset.zero, Offset(reach, 0), paint);
      case PieceKind.tee:
        canvas.drawLine(Offset(0, -reach), Offset(0, reach), paint);
        canvas.drawLine(Offset.zero, Offset(reach, 0), paint);
      case PieceKind.cross:
        canvas.drawLine(Offset(0, -reach), Offset(0, reach), paint);
        canvas.drawLine(Offset(-reach, 0), Offset(reach, 0), paint);
      case PieceKind.grass:
      case PieceKind.blocked:
        break;
    }

    // Clay centre dot keeps the junctions from reading as a flat blob.
    canvas.drawCircle(
      Offset.zero,
      size.width * 0.09,
      Paint()..color = AppColors.surfaceRaised.withValues(alpha: 0.55),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PathTilePainter old) {
    return old.piece.kind != piece.kind ||
        old.piece.rotation != piece.rotation ||
        old.bloomT != bloomT ||
        old.selected != selected ||
        old.highlighted != highlighted;
  }
}
