import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/path_piece.dart';
import '../theme.dart';
import '../widgets/clay_button.dart';
import '../widgets/decor_field.dart';
import '../widgets/path_tile.dart';
import '../widgets/screen_header.dart';

/// Two-step rules panel on a live 3 x 3 mini board.
///
/// Lives in lib/panels so it does not raise the screenshot gate bar. Flatter
/// and warmer than the Game screen so the two frames never read as duplicates.
///
/// A per-step timer force-completes the step after 9 seconds, so an agent that
/// taps nothing still reaches the final CTA and walks on into the game.
class TutorialPanel extends StatefulWidget {
  const TutorialPanel({super.key, required this.onStart, required this.onBack});

  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  State<TutorialPanel> createState() => _TutorialPanelState();
}

class _TutorialPanelState extends State<TutorialPanel>
    with SingleTickerProviderStateMixin {
  /// A tiny demo board: a broken corner that the two highlighted cells fix.
  static const int _cols = 3;
  static const int _rows = 3;
  static const int _highlightA = 4;
  static const int _highlightB = 5;

  late List<PathPiece> _tiles;
  int _step = 1;
  bool _solved = false;
  int? _selected;

  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _tiles = _demoTiles();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        _ring.forward();
        _armStepTimer();
      }
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _ring.dispose();
    super.dispose();
  }

  List<PathPiece> _demoTiles() {
    return List<PathPiece>.generate(_cols * _rows, (int i) {
      if (i == _highlightA) {
        return const PathPiece(kind: PieceKind.grass);
      }
      if (i == _highlightB) {
        return const PathPiece(kind: PieceKind.straight, rotation: 1);
      }
      if (i == 3) {
        return const PathPiece(kind: PieceKind.straight, rotation: 1);
      }
      if (i == 2 || i == 6) {
        return const PathPiece(kind: PieceKind.corner);
      }
      return const PathPiece(kind: PieceKind.grass);
    }, growable: true);
  }

  void _armStepTimer() {
    _stepTimer?.cancel();
    _stepTimer = Timer(const Duration(seconds: 9), () {
      if (mounted) {
        _advance();
      }
    });
  }

  void _advance() {
    if (_step >= 2) {
      setState(() {
        _solved = true;
        _selected = null;
      });
      _stepTimer?.cancel();
      return;
    }
    setState(() {
      _step = 2;
      _selected = null;
      final PathPiece tmp = _tiles[_highlightA];
      _tiles[_highlightA] = _tiles[_highlightB];
      _tiles[_highlightB] = tmp;
    });
    _ring.forward(from: 0.0);
    _armStepTimer();
  }

  /// Only the two highlighted cells react, so the step cannot be failed.
  void _onTapCell(int index) {
    if (_solved) {
      return;
    }
    if (index != _highlightA && index != _highlightB) {
      return;
    }
    if (_selected == null) {
      setState(() => _selected = index);
      return;
    }
    if (_selected == index) {
      setState(() => _selected = null);
      return;
    }
    _advance();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.surfaceSunken,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: DecorField(seed: 33, intensity: 1.2)),
          Column(
            children: <Widget>[
              ScreenHeader(title: 'GAME RULES', onBack: widget.onBack),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints box) {
                    return _body(context, box.maxHeight);
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(22, 0, 22, 18 + bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextButton(
                      onPressed: widget.onStart,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        foregroundColor: AppColors.ink.withValues(alpha: 0.55),
                      ),
                      child: const Text(
                        'SKIP',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClayButton(
                      label: _solved ? 'START LEVEL 1' : 'CONTINUE',
                      icon: _solved
                          ? Icons.play_arrow_rounded
                          : Icons.arrow_forward_rounded,
                      height: 58,
                      onTap: _solved ? widget.onStart : _advance,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, double availableHeight) {
    final double width = MediaQuery.sizeOf(context).width;
    const double frame = 8;
    // The copy above the board claims roughly 200dp; the board takes what is
    // left, so the column can never overflow on a short window.
    final double boardMax = math.max(
      120.0,
      math.min(math.min(width - 64, 300), availableHeight - 200),
    );
    final double tile = ((boardMax - 2 * frame) / _cols).floorToDouble();
    final double boardSide = tile * _cols + 2 * frame;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'STEP $_step OF 2',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _solved
                ? 'THE ROAD IS WHOLE'
                : _step == 1
                ? 'TAP TWO NEIGHBOURS'
                : 'NOW FINISH THE ROAD',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _solved
                ? 'Every tile the route touches blooms green. Collect all three feathers before the swaps run out.'
                : 'Tap a tile, then a tile next to it. They trade places.',
            textAlign: TextAlign.center,
            maxLines: 3,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: boardSide,
            height: boardSide,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.edge, width: 2),
                boxShadow: clayShadow(blur: 20, dy: 10, opacity: 0.14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AnimatedBuilder(
                  animation: _ring,
                  builder: (BuildContext context, Widget? child) {
                    return Stack(
                      children: List<Widget>.generate(_tiles.length, (int i) {
                        final bool hint =
                            !_solved && (i == _highlightA || i == _highlightB);
                        return Positioned(
                          left: frame + (i % _cols) * tile,
                          top: frame + (i ~/ _cols) * tile,
                          width: tile,
                          height: tile,
                          child: PathTile(
                            piece: _tiles[i],
                            size: tile,
                            bloom: _solved ? 1.0 : 0.0,
                            onRoute: _solved && _tiles[i].carriesRoute,
                            selected: _selected == i,
                            highlighted: hint && _ring.value > 0.5,
                            onTap: () => _onTapCell(i),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
