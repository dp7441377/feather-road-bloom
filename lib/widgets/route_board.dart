import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/level_generator.dart';
import '../game/path_piece.dart';
import '../theme.dart';
import 'path_tile.dart';

/// Owns the board geometry and lays the tiles out as positioned children of a
/// Stack.
///
/// The frame (inner padding + clay border) is subtracted BEFORE the tile size
/// is derived and the container is then given exactly `tile * n + 2 * frame`,
/// which is what keeps the geometry gate at zero overflow. Nothing here is an
/// Expanded inside an unbounded Expanded.
class RouteBoard extends StatelessWidget {
  const RouteBoard({
    super.key,
    required this.level,
    required this.tiles,
    required this.reached,
    required this.collectedFeathers,
    required this.bloom,
    required this.maxWidth,
    required this.maxHeight,
    required this.onTapCell,
    this.selectedIndex,
    this.highlighted = const <int>{},
    this.swapA,
    this.swapB,
    this.swapT = 1.0,
  });

  static const double boardPad = 10.0;
  static const double boardBorder = 3.0;
  static const double boardFrame = boardPad + boardBorder;

  final Level level;
  final List<PathPiece> tiles;
  final Set<int> reached;
  final Set<int> collectedFeathers;
  final double bloom;
  final double maxWidth;
  final double maxHeight;
  final ValueChanged<int> onTapCell;
  final int? selectedIndex;
  final Set<int> highlighted;

  /// The two cells mid-swap and the 0..1 interlock progress.
  final int? swapA;
  final int? swapB;
  final double swapT;

  @override
  Widget build(BuildContext context) {
    final int cols = level.cols;
    final int rows = level.rows;

    final double usableW = math.min(maxWidth, 380.0);
    final double tileFromW = (usableW - 2 * boardFrame) / cols;
    final double tileFromH = (maxHeight - 2 * boardFrame) / rows;
    final double tile = math.max(
      24.0,
      math.min(tileFromW, tileFromH).floorToDouble(),
    );

    final double boardW = tile * cols + 2 * boardFrame;
    final double boardH = tile * rows + 2 * boardFrame;

    Offset slotOf(int index) {
      return Offset(
        boardFrame + (index % cols) * tile,
        boardFrame + (index ~/ cols) * tile,
      );
    }

    Offset drawOf(int index) {
      // A tile taking part in the swap slides out of the slot it came from.
      if (swapA != null && swapB != null && swapT < 1.0) {
        if (index == swapA) {
          return Offset.lerp(slotOf(swapB!), slotOf(swapA!), swapT)!;
        }
        if (index == swapB) {
          return Offset.lerp(slotOf(swapA!), slotOf(swapB!), swapT)!;
        }
      }
      return slotOf(index);
    }

    final List<Widget> children = <Widget>[];

    for (int i = 0; i < tiles.length; i++) {
      final Offset at = drawOf(i);
      children.add(
        Positioned(
          left: at.dx,
          top: at.dy,
          width: tile,
          height: tile,
          child: PathTile(
            piece: tiles[i],
            size: tile,
            bloom: bloom,
            onRoute: reached.contains(i) && tiles[i].carriesRoute,
            selected: selectedIndex == i,
            highlighted: highlighted.contains(i),
            onTap: () => onTapCell(i),
          ),
        ),
      );
    }

    // Anchors use AI sprites: a single centred object is exactly what the
    // generator is good at, and they never rotate.
    children.add(_anchor(level.nestIndex, AppAssets.spriteNest, slotOf, tile));
    children.add(
      _anchor(level.gardenIndex, AppAssets.spriteGarden, slotOf, tile),
    );

    for (final int cell in level.featherCells) {
      if (collectedFeathers.contains(cell)) {
        continue;
      }
      final Offset at = drawOf(cell);
      final double glow = tile * 0.62;
      children.add(
        Positioned(
          left: at.dx,
          top: at.dy,
          width: tile,
          height: tile,
          child: IgnorePointer(
            child: Center(
              child: Container(
                width: glow,
                height: glow,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.28),
                ),
                child: Center(
                  child: Image.asset(
                    AppAssets.spriteFeather,
                    width: tile * 0.46,
                    height: tile * 0.46,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: boardW,
      height: boardH,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.edge, width: boardBorder),
          boxShadow: clayShadow(blur: 24, dy: 12, opacity: 0.16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(children: children),
        ),
      ),
    );
  }

  Widget _anchor(
    int index,
    String asset,
    Offset Function(int) slotOf,
    double tile,
  ) {
    final Offset at = slotOf(index);
    return Positioned(
      left: at.dx,
      top: at.dy,
      width: tile,
      height: tile,
      child: IgnorePointer(
        child: Center(
          child: Image.asset(
            asset,
            width: tile * 0.78,
            height: tile * 0.78,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
