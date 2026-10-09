/// Grid edge directions, ordered clockwise so `(index + steps) % 4` is a
/// 90-degree rotation and `(index + 2) % 4` is the opposite edge.
enum Dir { up, right, down, left }

enum PieceKind { straight, corner, tee, cross, grass, blocked }

Dir rotateDir(Dir d, int steps) => Dir.values[(d.index + steps) % 4];

Dir opposite(Dir d) => Dir.values[(d.index + 2) % 4];

/// Open edges of each kind at rotation 0.
const Map<PieceKind, List<Dir>> _baseEdges = <PieceKind, List<Dir>>{
  PieceKind.straight: <Dir>[Dir.up, Dir.down],
  PieceKind.corner: <Dir>[Dir.up, Dir.right],
  PieceKind.tee: <Dir>[Dir.up, Dir.right, Dir.down],
  PieceKind.cross: <Dir>[Dir.up, Dir.right, Dir.down, Dir.left],
  PieceKind.grass: <Dir>[],
  PieceKind.blocked: <Dir>[],
};

Set<Dir> openEdges(PieceKind kind, int rotation) {
  final List<Dir> base = _baseEdges[kind]!;
  final Set<Dir> out = <Dir>{};
  for (final Dir d in base) {
    out.add(rotateDir(d, rotation));
  }
  return out;
}

/// A single board cell. Immutable; swapping moves the whole piece (kind and
/// rotation travel together), which is what makes the scramble invertible.
class PathPiece {
  const PathPiece({required this.kind, this.rotation = 0, this.fixed = false});

  final PieceKind kind;
  final int rotation;

  /// Anchors (nest, garden) and blocked rubble never move.
  final bool fixed;

  Set<Dir> get edges => openEdges(kind, rotation);

  bool get carriesRoute => kind != PieceKind.grass && kind != PieceKind.blocked;

  PathPiece copyWith({PieceKind? kind, int? rotation, bool? fixed}) {
    return PathPiece(
      kind: kind ?? this.kind,
      rotation: rotation ?? this.rotation,
      fixed: fixed ?? this.fixed,
    );
  }
}

/// One adjacent swap. The scramble stack is a list of these; replaying it in
/// reverse order restores the solved board exactly.
class Swap {
  const Swap(this.a, this.b);

  final int a;
  final int b;
}

/// Derives the kind + rotation that opens exactly the given edges.
/// Only 1- and 2-edge cases occur on a carved route.
PathPiece pieceForEdges(Set<Dir> wanted, {bool fixed = false}) {
  if (wanted.length <= 1) {
    final Dir d = wanted.isEmpty ? Dir.up : wanted.first;
    final bool vertical = d == Dir.up || d == Dir.down;
    return PathPiece(
      kind: PieceKind.straight,
      rotation: vertical ? 0 : 1,
      fixed: fixed,
    );
  }
  for (final PieceKind kind in <PieceKind>[
    PieceKind.straight,
    PieceKind.corner,
    PieceKind.tee,
    PieceKind.cross,
  ]) {
    for (int r = 0; r < 4; r++) {
      final Set<Dir> e = openEdges(kind, r);
      if (e.length == wanted.length && e.containsAll(wanted)) {
        return PathPiece(kind: kind, rotation: r, fixed: fixed);
      }
    }
  }
  return PathPiece(kind: PieceKind.cross, fixed: fixed);
}

/// Column/row deltas indexed by `Dir.index` (up, right, down, left).
const List<int> kDirDx = <int>[0, 1, 0, -1];
const List<int> kDirDy = <int>[-1, 0, 1, 0];
