import 'path_piece.dart';

/// Outcome of a flood fill from the nest cell.
class RouteResult {
  const RouteResult({
    required this.reached,
    required this.connectedToGarden,
    required this.feathersCollected,
  });

  /// Every cell the route physically reaches from the nest.
  final Set<int> reached;
  final bool connectedToGarden;
  final int feathersCollected;
}

/// Flood fill that only steps between two tiles whose facing edges are both
/// open. Pure function, no Flutter dependency, trivially unit-testable.
RouteResult solveRoute({
  required List<PathPiece> tiles,
  required int cols,
  required int rows,
  required int nestIndex,
  required int gardenIndex,
  required Set<int> featherCells,
}) {
  final Set<int> reached = <int>{nestIndex};
  final List<int> queue = <int>[nestIndex];

  while (queue.isNotEmpty) {
    final int current = queue.removeLast();
    final int cx = current % cols;
    final int cy = current ~/ cols;
    for (final Dir d in tiles[current].edges) {
      final int nx = cx + kDirDx[d.index];
      final int ny = cy + kDirDy[d.index];
      if (nx < 0 || ny < 0 || nx >= cols || ny >= rows) {
        continue;
      }
      final int next = ny * cols + nx;
      if (reached.contains(next)) {
        continue;
      }
      if (!tiles[next].edges.contains(opposite(d))) {
        continue;
      }
      reached.add(next);
      queue.add(next);
    }
  }

  int feathers = 0;
  for (final int cell in featherCells) {
    if (reached.contains(cell)) {
      feathers += 1;
    }
  }

  return RouteResult(
    reached: reached,
    connectedToGarden: reached.contains(gardenIndex),
    feathersCollected: feathers,
  );
}
