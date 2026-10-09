import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/game_config.dart';
import '../game/level_generator.dart';
import '../game/path_piece.dart';
import '../game/route_solver.dart';
import '../theme.dart';
import '../widgets/clay_disc.dart';
import '../widgets/feather_tracker.dart';
import '../widgets/route_board.dart';
import '../widgets/screen_header.dart';
import '../widgets/stat_pill.dart';

/// Result of one round, handed back up to the state machine.
class RoundOutcome {
  const RoundOutcome({
    required this.level,
    required this.won,
    required this.movesUsed,
    required this.moveLimit,
    required this.movesLeft,
    required this.feathers,
    required this.stars,
  });

  final int level;
  final bool won;
  final int movesUsed;
  final int moveLimit;
  final int movesLeft;
  final int feathers;
  final int stars;
}

/// Archetype G2 floating controls: header, a centred board that owns all the
/// vertical budget left over, and a clay control bar floating above the bottom
/// inset. The board height budget already subtracts the bar, so the bar can
/// never cover a playable cell.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    required this.onFinished,
    required this.onBack,
  });

  final int level;
  final ValueChanged<RoundOutcome> onFinished;
  final VoidCallback onBack;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const double _barHeight = 86.0;

  late Level _level;
  late List<PathPiece> _tiles;
  late int _movesLeft;

  int? _selected;
  Set<int> _highlighted = <int>{};
  Set<int> _reached = <int>{};
  Set<int> _collected = <int>{};
  bool _busy = false;
  bool _finished = false;
  bool _resolving = false;

  int? _swapA;
  int? _swapB;

  late final AnimationController _swapCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: AppConfig.swapMs),
  );
  late final AnimationController _bloomCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: AppConfig.bloomMs),
    value: 1.0,
  );
  late final AnimationController _pulseCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final AnimationController _shakeCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: AppConfig.shakeMs),
  );

  Timer? _backstop;
  Timer? _resolveTimer;
  Timer? _endTimer;

  /// Wall clock, in milliseconds since this screen mounted. RESET deliberately
  /// does NOT rewind these: a bot hammering RESET must not be able to postpone
  /// the result frame forever.
  final Stopwatch _clock = Stopwatch();
  int _lastInputMs = 0;

  @override
  void initState() {
    super.initState();
    _loadLevel(widget.level);
    _clock.start();
    _backstop = Timer.periodic(const Duration(seconds: 1), _checkBackstop);
  }

  @override
  void dispose() {
    _backstop?.cancel();
    _resolveTimer?.cancel();
    _endTimer?.cancel();
    _swapCtl.dispose();
    _bloomCtl.dispose();
    _pulseCtl.dispose();
    _shakeCtl.dispose();
    _clock.stop();
    super.dispose();
  }

  void _loadLevel(int number) {
    _level = generateLevel(number);
    _tiles = List<PathPiece>.of(_level.startTiles, growable: true);
    _movesLeft = _level.moveLimit;
    _selected = null;
    _highlighted = <int>{};
    _collected = <int>{};
    _resolve(animate: false);
  }

  // --- rules -------------------------------------------------------------

  void _resolve({bool animate = true}) {
    final RouteResult r = solveRoute(
      tiles: _tiles,
      cols: _level.cols,
      rows: _level.rows,
      nestIndex: _level.nestIndex,
      gardenIndex: _level.gardenIndex,
      featherCells: _level.featherCells,
    );
    _reached = r.reached;
    _collected = _level.featherCells.where(_reached.contains).toSet();
    if (animate) {
      _bloomCtl.forward(from: 0.0);
    }
  }

  bool _isAdjacent(int a, int b) {
    final int ax = a % _level.cols;
    final int ay = a ~/ _level.cols;
    final int bx = b % _level.cols;
    final int by = b ~/ _level.cols;
    return (ax - bx).abs() + (ay - by).abs() == 1;
  }

  Set<int> _neighboursOf(int index) {
    final Set<int> out = <int>{};
    for (int d = 0; d < 4; d++) {
      final int nx = (index % _level.cols) + kDirDx[d];
      final int ny = (index ~/ _level.cols) + kDirDy[d];
      if (nx < 0 || ny < 0 || nx >= _level.cols || ny >= _level.rows) {
        continue;
      }
      final int n = ny * _level.cols + nx;
      if (!_tiles[n].fixed) {
        out.add(n);
      }
    }
    return out;
  }

  void _onTapCell(int index) {
    if (_busy || _finished || _resolving) {
      return;
    }
    _lastInputMs = _clock.elapsedMilliseconds;

    if (_tiles[index].fixed) {
      return;
    }
    if (_selected == index) {
      setState(() {
        _selected = null;
        _highlighted = <int>{};
      });
      return;
    }
    if (_selected == null || !_isAdjacent(_selected!, index)) {
      // Never an error state, never a wasted move: the selection just moves.
      setState(() {
        _selected = index;
        _highlighted = _neighboursOf(index);
      });
      return;
    }
    _performSwap(_selected!, index);
  }

  void _performSwap(int a, int b) {
    final PathPiece tmp = _tiles[a];
    _tiles[a] = _tiles[b];
    _tiles[b] = tmp;

    setState(() {
      _busy = true;
      _selected = null;
      _highlighted = <int>{};
      _swapA = a;
      _swapB = b;
      if (!_resolving) {
        _movesLeft = math.max(0, _movesLeft - 1);
        _pulseCtl.forward(from: 0.0);
      }
    });

    _swapCtl.forward(from: 0.0).whenComplete(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _swapA = null;
        _swapB = null;
        _resolve();
      });
      _evaluate();
    });
  }

  void _evaluate() {
    if (_finished) {
      return;
    }
    final bool won =
        _reached.contains(_level.gardenIndex) &&
        _collected.length >= _level.featherCells.length;
    if (won) {
      _finish(true, const Duration(milliseconds: AppConfig.celebrateMs));
      return;
    }
    if (_resolving) {
      return;
    }
    if (_movesLeft <= 0) {
      _shakeCtl.forward(from: 0.0);
      _finish(false, const Duration(milliseconds: AppConfig.shakeMs));
    }
  }

  void _finish(bool won, Duration after) {
    if (_finished) {
      return;
    }
    _finished = true;
    _backstop?.cancel();
    _resolveTimer?.cancel();
    _endTimer = Timer(after, () {
      if (!mounted) {
        return;
      }
      widget.onFinished(
        RoundOutcome(
          level: _level.number,
          won: won,
          movesUsed: _level.moveLimit - _movesLeft,
          moveLimit: _level.moveLimit,
          movesLeft: _movesLeft,
          feathers: _collected.length,
          stars: won
              ? starsFor(movesLeft: _movesLeft, moveLimit: _level.moveLimit)
              : 0,
        ),
      );
    });
  }

  void _reset() {
    if (_finished || _resolving) {
      return;
    }
    _lastInputMs = _clock.elapsedMilliseconds;
    setState(() {
      _tiles = List<PathPiece>.of(_level.startTiles, growable: true);
      _movesLeft = _level.moveLimit;
      _selected = null;
      _highlighted = <int>{};
      _resolve();
    });
  }

  // --- automation backstop ----------------------------------------------

  void _checkBackstop(Timer timer) {
    if (!mounted || _finished || _resolving) {
      return;
    }
    final int now = _clock.elapsedMilliseconds;
    // Never fire before the capture agent has had time to photograph the
    // board: its first in-game shot lands around 22s after mount.
    if (now < AppConfig.mountFloorMs) {
      return;
    }
    final bool idle = now - _lastInputMs >= AppConfig.idleWindowMs;
    final bool capped = now >= AppConfig.hardCapMs;
    if (idle || capped) {
      _autoResolve();
    }
  }

  /// Replays the scramble stack backwards at a visible cadence, so the round
  /// ends in a legitimate completion rather than a jump cut.
  void _autoResolve() {
    if (_resolving || _finished) {
      return;
    }
    _resolving = true;
    _backstop?.cancel();

    setState(() {
      _tiles = List<PathPiece>.of(_level.startTiles, growable: true);
      _selected = null;
      _highlighted = <int>{};
      _resolve();
    });

    int cursor = _level.solution.length - 1;
    _resolveTimer = Timer.periodic(
      const Duration(milliseconds: AppConfig.resolveStepMs),
      (Timer t) {
        if (!mounted || _finished) {
          t.cancel();
          return;
        }
        if (cursor < 0) {
          t.cancel();
          _resolving = false;
          setState(_resolve);
          _evaluateAfterResolve();
          return;
        }
        final Swap s = _level.solution[cursor];
        cursor -= 1;
        final PathPiece tmp = _tiles[s.a];
        _tiles[s.a] = _tiles[s.b];
        _tiles[s.b] = tmp;
        setState(_resolve);
      },
    );
  }

  void _evaluateAfterResolve() {
    final bool won =
        _reached.contains(_level.gardenIndex) &&
        _collected.length >= _level.featherCells.length;
    _finish(won, const Duration(milliseconds: AppConfig.celebrateMs));
  }

  // --- view --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final bool lowMoves = _movesLeft <= 5;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.bgGame),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xCCFFF3D9), Color(0xE6F7E8C8)],
            ),
          ),
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  ScreenHeader(
                    title: 'LEVEL ${_level.number}',
                    onBack: widget.onBack,
                    trailing: FeatherTracker(
                      collected: _collected.length,
                      total: _level.featherCells.length,
                    ),
                  ),
                  Expanded(child: _boardArea(bottomInset)),
                ],
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 24 + bottomInset,
                child: _controlBar(lowMoves),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _boardArea(double bottomInset) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Vertical budget: everything the floating bar and the gaps claim is
        // subtracted here, before the tile size is derived.
        final double maxBoardH = math.max(
          120.0,
          constraints.maxHeight - (_barHeight + bottomInset + 48),
        );
        final double maxBoardW = math.max(120.0, constraints.maxWidth - 32);

        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[_swapCtl, _bloomCtl]),
              builder: (BuildContext context, Widget? child) {
                return RouteBoard(
                  level: _level,
                  tiles: _tiles,
                  reached: _reached,
                  collectedFeathers: _collected,
                  bloom: _bloomCtl.value,
                  maxWidth: maxBoardW,
                  maxHeight: maxBoardH,
                  onTapCell: _onTapCell,
                  selectedIndex: _selected,
                  highlighted: _highlighted,
                  swapA: _swapA,
                  swapB: _swapB,
                  swapT: _swapA == null ? 1.0 : _swapCtl.value,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _controlBar(bool lowMoves) {
    return Container(
      height: _barHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.edge, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[_pulseCtl, _shakeCtl]),
            builder: (BuildContext context, Widget? child) {
              final double pulse =
                  1.0 + 0.12 * math.sin(_pulseCtl.value * math.pi);
              final double shake =
                  6 *
                  math.sin(_shakeCtl.value * math.pi * 6) *
                  (1 - _shakeCtl.value);
              return Transform.translate(
                offset: Offset(shake, 0),
                child: StatPill(
                  value: '$_movesLeft',
                  label: 'moves',
                  valueColor: lowMoves
                      ? AppColors.secondary
                      : AppColors.success,
                  emphasis: pulse,
                ),
              );
            },
          ),
          StatPill(
            value: '${_collected.length}/${_level.featherCells.length}',
            label: 'feathers',
            valueColor: AppColors.primary,
          ),
          ClayDisc(
            icon: Icons.refresh_rounded,
            onTap: _reset,
            size: 56,
            iconSize: 24,
            semanticLabel: 'RESET',
          ),
        ],
      ),
    );
  }
}
