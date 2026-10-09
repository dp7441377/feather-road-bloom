import 'dart:math' as math;

import 'game_config.dart';
import 'path_piece.dart';
import 'route_solver.dart';

/// A generated, provably solvable level.
class Level {
  Level({
    required this.number,
    required this.cols,
    required this.rows,
    required this.solvedTiles,
    required this.startTiles,
    required this.nestIndex,
    required this.gardenIndex,
    required this.featherCells,
    required this.solution,
    required this.moveLimit,
  });

  final int number;
  final int cols;
  final int rows;

  /// The board in its solved arrangement, kept for the auto-resolve replay.
  final List<PathPiece> solvedTiles;

  /// The scrambled board the player actually starts from.
  final List<PathPiece> startTiles;

  final int nestIndex;
  final int gardenIndex;
  final Set<int> featherCells;

  /// Scramble stack. Applying it in reverse to [startTiles] rebuilds
  /// [solvedTiles] exactly, so it is the solvability proof, the hint source
  /// and the auto-play script all at once.
  final List<Swap> solution;

  final int moveLimit;

  int get cellCount => cols * rows;
}

/// Grid size grows with the level; the board geometry formula reads cols/rows
/// from here, so no layout change is needed.
({int cols, int rows}) gridFor(int level) {
  if (level <= 4) {
    return (cols: 5, rows: 5);
  }
  if (level <= 8) {
    return (cols: 5, rows: 6);
  }
  return (cols: 6, rows: 6);
}

/// Builds the answer first, then walks backwards. Never generate-and-test.
Level generateLevel(int level, {math.Random? random}) {
  final math.Random rnd = random ?? math.Random(level * 7919 + 13);
  final ({int cols, int rows}) grid = gridFor(level);
  final int cols = grid.cols;
  final int rows = grid.rows;

  final int nestIndex = (rows - 1) * cols; // bottom-left
  final int gardenIndex = cols - 1; // top-right

  final List<int> path = _carvePath(
    cols,
    rows,
    nestIndex,
    gardenIndex,
    level,
    rnd,
  );

  // Derive each route tile from the two edges it has to keep open.
  final List<PathPiece> solved = List<PathPiece>.generate(
    cols * rows,
    (_) => const PathPiece(kind: PieceKind.grass),
    growable: true,
  );

  for (int i = 0; i < path.length; i++) {
    final Set<Dir> edges = <Dir>{};
    if (i > 0) {
      edges.add(_dirBetween(path[i], path[i - 1], cols));
    }
    if (i < path.length - 1) {
      edges.add(_dirBetween(path[i], path[i + 1], cols));
    }
    final bool isAnchor = i == 0 || i == path.length - 1;
    solved[path[i]] = pieceForEdges(edges, fixed: isAnchor);
  }

  final Set<int> onPath = path.toSet();

  final List<int> free = <int>[];
  for (int i = 0; i < cols * rows; i++) {
    if (!onPath.contains(i)) {
      free.add(i);
    }
  }
  free.shuffle(rnd);

  // Rubble: immovable blocked cells, always off the solution path.
  int cursor = 0;
  final int blockedCount = math.min(level ~/ 3, free.length ~/ 3);
  for (int i = 0; i < blockedCount; i++) {
    solved[free[cursor]] = const PathPiece(
      kind: PieceKind.blocked,
      fixed: true,
    );
    cursor += 1;
  }

  // Decoy fragments: swappable junk that reads as a broken road.
  const List<PieceKind> decoyKinds = <PieceKind>[
    PieceKind.straight,
    PieceKind.corner,
    PieceKind.corner,
    PieceKind.tee,
  ];
  final int decoyCount = math.min(2 + level ~/ 4, free.length - cursor);
  for (int i = 0; i < decoyCount; i++) {
    solved[free[cursor]] = PathPiece(
      kind: decoyKinds[rnd.nextInt(decoyKinds.length)],
      rotation: rnd.nextInt(4),
    );
    cursor += 1;
  }

  // Feathers sit ON the solved route, spaced along it.
  final Set<int> featherCells = <int>{};
  for (final double frac in <double>[0.25, 0.55, 0.85]) {
    int idx = (path.length * frac).round().clamp(1, path.length - 2);
    while (featherCells.contains(path[idx]) && idx < path.length - 2) {
      idx += 1;
    }
    featherCells.add(path[idx]);
  }

  // Scramble with an invertible stack of adjacent swaps.
  final int swapCount = 6 + level;
  List<PathPiece> start = <PathPiece>[];
  List<Swap> solution = <Swap>[];

  for (int attempt = 0; attempt < 8; attempt++) {
    start = List<PathPiece>.of(solved, growable: true);
    solution = <Swap>[];
    for (int i = 0; i < swapCount; i++) {
      final Swap? s = _randomAdjacentSwap(start, cols, rows, rnd);
      if (s == null) {
        continue;
      }
      final PathPiece tmp = start[s.a];
      start[s.a] = start[s.b];
      start[s.b] = tmp;
      solution.add(s);
    }
    final RouteResult probe = solveRoute(
      tiles: start,
      cols: cols,
      rows: rows,
      nestIndex: nestIndex,
      gardenIndex: gardenIndex,
      featherCells: featherCells,
    );
    final bool alreadyWon =
        probe.connectedToGarden &&
        probe.feathersCollected >= featherCells.length;
    if (!alreadyWon && solution.isNotEmpty) {
      break;
    }
  }

  return Level(
    number: level,
    cols: cols,
    rows: rows,
    solvedTiles: solved,
    startTiles: start,
    nestIndex: nestIndex,
    gardenIndex: gardenIndex,
    featherCells: featherCells,
    solution: solution,
    // Slack of 6 absorbs the swaps that cancel each other out.
    moveLimit: solution.length + 6,
  );
}

/// Stars awarded for finishing with [movesLeft] of [moveLimit] to spare.
int starsFor({required int movesLeft, required int moveLimit}) {
  if (movesLeft >= moveLimit * 0.5) {
    return 3;
  }
  if (movesLeft >= moveLimit * 0.25) {
    return 2;
  }
  return 1;
}

Dir _dirBetween(int from, int to, int cols) {
  final int dx = (to % cols) - (from % cols);
  final int dy = (to ~/ cols) - (from ~/ cols);
  if (dy < 0) {
    return Dir.up;
  }
  if (dy > 0) {
    return Dir.down;
  }
  return dx > 0 ? Dir.right : Dir.left;
}

Swap? _randomAdjacentSwap(
  List<PathPiece> tiles,
  int cols,
  int rows,
  math.Random rnd,
) {
  for (int tries = 0; tries < 64; tries++) {
    final int a = rnd.nextInt(tiles.length);
    if (tiles[a].fixed) {
      continue;
    }
    final int dir = rnd.nextInt(4);
    final int nx = (a % cols) + kDirDx[dir];
    final int ny = (a ~/ cols) + kDirDy[dir];
    if (nx < 0 || ny < 0 || nx >= cols || ny >= rows) {
      continue;
    }
    final int b = ny * cols + nx;
    if (tiles[b].fixed) {
      continue;
    }
    return Swap(a, b);
  }
  return null;
}

/// Randomised depth-first carve of a simple nest-to-garden path, with a
/// deterministic elbow fallback so generation can never fail.
List<int> _carvePath(
  int cols,
  int rows,
  int start,
  int end,
  int level,
  math.Random rnd,
) {
  final List<int> fallback = _elbowPath(cols, rows, start, end);
  final int capacity = (cols * rows * 2) ~/ 3;
  int target = math.min(9 + level, capacity);
  // Path length parity on a grid is fixed by the Manhattan distance.
  if ((target - fallback.length).isOdd) {
    target -= 1;
  }
  if (target < fallback.length) {
    return fallback;
  }

  for (int wanted = target; wanted >= fallback.length; wanted -= 2) {
    final List<int>? found = _dfsPath(cols, rows, start, end, wanted, rnd);
    if (found != null) {
      return found;
    }
  }
  return fallback;
}

List<int>? _dfsPath(
  int cols,
  int rows,
  int start,
  int end,
  int wantedLength,
  math.Random rnd,
) {
  final List<int> path = <int>[start];
  final Set<int> seen = <int>{start};
  int budget = 40000;

  bool step(int node) {
    if (budget <= 0) {
      return false;
    }
    budget -= 1;
    if (node == end) {
      return path.length >= wantedLength;
    }
    final List<int> order = <int>[0, 1, 2, 3]..shuffle(rnd);
    for (final int dir in order) {
      final int nx = (node % cols) + kDirDx[dir];
      final int ny = (node ~/ cols) + kDirDy[dir];
      if (nx < 0 || ny < 0 || nx >= cols || ny >= rows) {
        continue;
      }
      final int next = ny * cols + nx;
      if (seen.contains(next)) {
        continue;
      }
      if (path.length + 1 > wantedLength) {
        return false;
      }
      if (next == end && path.length + 1 < wantedLength) {
        continue;
      }
      seen.add(next);
      path.add(next);
      if (step(next)) {
        return true;
      }
      path.removeLast();
      seen.remove(next);
    }
    return false;
  }

  return step(start) ? path : null;
}

List<int> _elbowPath(int cols, int rows, int start, int end) {
  final List<int> path = <int>[start];
  int x = start % cols;
  int y = start ~/ cols;
  final int ex = end % cols;
  final int ey = end ~/ cols;
  while (x != ex) {
    x += ex > x ? 1 : -1;
    path.add(y * cols + x);
  }
  while (y != ey) {
    y += ey > y ? 1 : -1;
    path.add(y * cols + x);
  }
  return path;
}

/// Total number of levels, exposed so menu copy never hardcodes it twice.
int get totalLevels => AppConfig.totalLevels;
