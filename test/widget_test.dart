// Pure-logic tests for the level generator and the route solver. They assert
// the property the whole game depends on: every generated level is solvable by
// replaying its own scramble stack in reverse.

import 'package:feather_road_bloom/game/game_config.dart';
import 'package:feather_road_bloom/game/level_generator.dart';
import 'package:feather_road_bloom/game/path_piece.dart';
import 'package:feather_road_bloom/game/route_solver.dart';
import 'package:flutter_test/flutter_test.dart';

RouteResult _solve(Level level, List<PathPiece> tiles) {
  return solveRoute(
    tiles: tiles,
    cols: level.cols,
    rows: level.rows,
    nestIndex: level.nestIndex,
    gardenIndex: level.gardenIndex,
    featherCells: level.featherCells,
  );
}

void main() {
  test('loader duration is exactly 8000ms', () {
    expect(AppConfig.loaderDurationMs, 8000);
  });

  test('every level is solvable by reversing its scramble stack', () {
    for (int n = 1; n <= AppConfig.totalLevels; n++) {
      final Level level = generateLevel(n);

      expect(
        level.featherCells.length,
        AppConfig.feathersPerLevel,
        reason: 'level $n should place three feathers',
      );
      expect(level.solution, isNotEmpty, reason: 'level $n has no scramble');
      expect(
        level.moveLimit,
        greaterThan(level.solution.length),
        reason: 'level $n leaves no slack',
      );

      // The start board must NOT already be a win, or there is no gameplay.
      final RouteResult atStart = _solve(level, level.startTiles);
      expect(
        atStart.connectedToGarden &&
            atStart.feathersCollected == level.featherCells.length,
        isFalse,
        reason: 'level $n starts already solved',
      );

      // Replaying the stack backwards must reach the win condition.
      final List<PathPiece> board = List<PathPiece>.of(
        level.startTiles,
        growable: true,
      );
      for (int i = level.solution.length - 1; i >= 0; i--) {
        final Swap s = level.solution[i];
        final PathPiece tmp = board[s.a];
        board[s.a] = board[s.b];
        board[s.b] = tmp;
      }

      final RouteResult solved = _solve(level, board);
      expect(
        solved.connectedToGarden,
        isTrue,
        reason: 'level $n is not connected after the replay',
      );
      expect(
        solved.feathersCollected,
        level.featherCells.length,
        reason: 'level $n misses a feather after the replay',
      );
    }
  });

  test('open edges rotate clockwise', () {
    expect(openEdges(PieceKind.straight, 0), <Dir>{Dir.up, Dir.down});
    expect(openEdges(PieceKind.straight, 1), <Dir>{Dir.right, Dir.left});
    expect(openEdges(PieceKind.corner, 1), <Dir>{Dir.right, Dir.down});
    expect(opposite(Dir.up), Dir.down);
  });

  test('stars scale with the moves left', () {
    expect(starsFor(movesLeft: 10, moveLimit: 16), 3);
    expect(starsFor(movesLeft: 5, moveLimit: 16), 2);
    expect(starsFor(movesLeft: 1, moveLimit: 16), 1);
  });
}
