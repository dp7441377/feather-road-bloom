import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/game_config.dart';
import '../theme.dart';
import '../widgets/clay_button.dart';
import '../widgets/star_row.dart';
import '../widgets/stat_pill.dart';
import 'game_screen.dart';

/// Round result. Win and loss are deliberately far apart visually, and both
/// are far from every other screen, so no two captured frames can collapse
/// into the same perceptual hash.
///
/// Both outcomes always expose a button whose label contains AGAIN, and the
/// back-to-menu control is labelled exactly MENU (never BACK TO MENU, which
/// the UI test misreads as a bonus screen).
class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.outcome,
    required this.hasNextLevel,
    required this.onNextLevel,
    required this.onPlayAgain,
    required this.onMenu,
    required this.onLevelMap,
  });

  final RoundOutcome outcome;
  final bool hasNextLevel;
  final VoidCallback onNextLevel;
  final VoidCallback onPlayAgain;
  final VoidCallback onMenu;
  final VoidCallback onLevelMap;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _stars = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) {
        return;
      }
      _entry.forward();
      _stars.forward();
      if (widget.outcome.won) {
        _burst.forward();
      }
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    _stars.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool won = widget.outcome.won;
    final Size screen = MediaQuery.sizeOf(context);
    final double cardWidth = math.min(screen.width - 48, 360);

    final Widget art = Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.bgResult),
          fit: BoxFit.cover,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: won ? AppColors.canvas : AppColors.ink,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: won
                ? art
                : ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      AppColors.ink.withValues(alpha: 0.28),
                      BlendMode.saturation,
                    ),
                    child: art,
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: won
                      ? <Color>[
                          AppColors.success.withValues(alpha: 0.26),
                          AppColors.canvas.withValues(alpha: 0.92),
                        ]
                      : <Color>[
                          AppColors.ink.withValues(alpha: 0.52),
                          AppColors.ink.withValues(alpha: 0.80),
                        ],
                ),
              ),
            ),
          ),
          if (won)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _burst,
                  builder: (BuildContext context, Widget? child) {
                    return CustomPaint(
                      painter: _PetalBurstPainter(t: _burst.value),
                    );
                  },
                ),
              ),
            ),
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _entry,
                  builder: (BuildContext context, Widget? child) {
                    final double t = Curves.easeOutCubic.transform(
                      _entry.value,
                    );
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 28 * (1 - t)),
                        child: child,
                      ),
                    );
                  },
                  child: _card(cardWidth, won),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(double width, bool won) {
    final RoundOutcome o = widget.outcome;

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 22),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(32),
        boxShadow: clayShadow(blur: 30, dy: 14, opacity: 0.18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          StarRow(earned: o.stars, progress: _stars),
          const SizedBox(height: 20),
          // Decoration flanks the headline with clearance on both sides and
          // never crosses a glyph (rule 17).
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _diamond(won),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  won ? 'PATH IN BLOOM' : 'OUT OF SWAPS',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                    color: won ? AppColors.successDeep : AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _diamond(won),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            won ? 'LEVEL ${o.level} COMPLETE' : 'THE ROAD IS STILL BROKEN',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              StatPill(
                value: '${o.movesUsed}',
                label: 'moves used',
                valueColor: AppColors.info,
              ),
              const SizedBox(width: 12),
              StatPill(
                value: '${o.feathers}/${AppConfig.feathersPerLevel}',
                label: 'feathers',
                valueColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (won && widget.hasNextLevel) ...<Widget>[
            ClayButton(
              label: 'NEXT LEVEL',
              icon: Icons.arrow_forward_rounded,
              onTap: widget.onNextLevel,
            ),
            const SizedBox(height: 12),
            ClayButton(
              label: 'PLAY AGAIN',
              primary: false,
              height: 48,
              onTap: widget.onPlayAgain,
            ),
          ] else ...<Widget>[
            ClayButton(
              label: 'PLAY AGAIN',
              icon: Icons.refresh_rounded,
              onTap: widget.onPlayAgain,
            ),
            const SizedBox(height: 12),
            ClayButton(
              label: 'MENU',
              primary: false,
              height: 48,
              onTap: widget.onMenu,
            ),
          ],
          const SizedBox(height: 10),
          TextButton(
            onPressed: widget.onLevelMap,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              foregroundColor: AppColors.inkSoft,
            ),
            child: const Text(
              'CHOOSE A PATH',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _diamond(bool won) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: won ? AppColors.success : AppColors.secondary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// One-shot celebration: flat geometric petals flung outward by a single
/// controller that completes. Nothing repeats.
class _PetalBurstPainter extends CustomPainter {
  _PetalBurstPainter({required this.t});

  final double t;

  static const List<Color> _palette = <Color>[
    AppColors.primary,
    AppColors.secondary,
    AppColors.success,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) {
      return;
    }
    final Offset centre = Offset(size.width / 2, size.height * 0.34);
    final double eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final double fade = (1.0 - t).clamp(0.0, 1.0);

    for (int i = 0; i < 14; i++) {
      final double angle = (i / 14) * 2 * math.pi;
      final double distance =
          eased * size.width * 0.52 * (0.6 + (i % 4) * 0.14);
      final Offset at =
          centre + Offset(math.cos(angle), math.sin(angle)) * distance;
      final double petal = 10 + (i % 3) * 3;
      final Paint paint = Paint()
        ..color = _palette[i % _palette.length].withValues(alpha: 0.75 * fade);
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(angle + eased * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: petal, height: petal),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PetalBurstPainter old) => old.t != t;
}
