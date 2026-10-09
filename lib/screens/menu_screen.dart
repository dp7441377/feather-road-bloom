import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/game_config.dart';
import '../theme.dart';
import '../widgets/clay_button.dart';
import '../widgets/decor_field.dart';
import '../widgets/stat_pill.dart';

/// Menu, archetype M2 bottom-sheet: full-bleed art on top, a clay sheet with
/// the copy and the CTAs docked to the bottom.
///
/// The sheet is bottom-anchored and sized by its content, which puts the
/// primary CTA centre at roughly y 1950 on a 1080x2400 capture — inside the
/// tap sweep every automated CTA finder uses.
///
/// Exactly one string on this screen contains PLAY or START: the primary CTA.
/// The secondary deliberately reads GAME RULES rather than HOW TO PLAY, so the
/// harness cannot mistake it for the main call to action.
class MenuScreen extends StatefulWidget {
  const MenuScreen({
    super.key,
    required this.unlockedLevel,
    required this.feathersTotal,
    required this.onStart,
    required this.onRules,
  });

  final int unlockedLevel;
  final int feathersTotal;
  final VoidCallback onStart;
  final VoidCallback onRules;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void initState() {
    super.initState();
    // One staggered entry pass that completes and stops. The hen does not
    // idle-animate: a perpetually moving menu starves the capture agent.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        _entry.forward();
      }
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.bgMenu),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: <double>[0.0, 0.38, 0.58],
              colors: <Color>[
                Color(0x00FFF3D9),
                Color(0x00FFF3D9),
                Color(0xD9FFF3D9),
              ],
            ),
          ),
          child: Stack(
            children: <Widget>[
              const Positioned.fill(child: DecorField(seed: 4, intensity: 0.7)),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _hero(screen),
                ),
              ),
              Positioned(left: 0, right: 0, bottom: 0, child: _sheet()),
            ],
          ),
        ),
      ),
    );
  }

  /// Hero zone: the hen floats in the upper art band, flanked by flat
  /// geometric decor that never crosses her silhouette.
  Widget _hero(Size screen) {
    final double band = screen.height * 0.56;
    return SizedBox(
      height: band,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: 10,
            top: band * 0.04,
            child: _shape(
              120,
              AppColors.primary.withValues(alpha: 0.30),
              circle: true,
            ),
          ),
          Positioned(
            right: 8,
            top: band * 0.50,
            child: _shape(96, AppColors.success.withValues(alpha: 0.26)),
          ),
          Positioned(
            right: 60,
            top: band * 0.08,
            child: _shape(
              64,
              AppColors.info.withValues(alpha: 0.24),
              circle: true,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: band * 0.10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.18),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Image.asset(
                AppAssets.spriteBirdHero,
                width: 190,
                height: 190,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shape(double d, Color color, {bool circle = false}) {
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        color: color,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(28),
      ),
    );
  }

  Widget _sheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _staggered(
                0.0,
                0.4,
                const Text(
                  'FEATHER ROAD BLOOM',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 26,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Tagline sits ABOVE the CTA, never under it (rule 19).
              _staggered(
                0.1,
                0.5,
                const Text(
                  'SWAP THE TILES  ·  GROW THE ROAD',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _staggered(
                0.2,
                0.7,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    StatPill(
                      value:
                          '${widget.unlockedLevel} of ${AppConfig.totalLevels}',
                      label: 'levels',
                      valueColor: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    StatPill(
                      value:
                          '${widget.feathersTotal} of ${AppConfig.totalFeathers}',
                      label: 'feathers',
                      valueColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _staggered(
                0.4,
                1.0,
                ClayButton(
                  label: 'START PLANTING',
                  icon: Icons.play_arrow_rounded,
                  onTap: widget.onStart,
                ),
              ),
              const SizedBox(height: 12),
              _staggered(
                0.4,
                1.0,
                ClayButton(
                  label: 'GAME RULES',
                  primary: false,
                  height: 48,
                  onTap: widget.onRules,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _staggered(double begin, double end, Widget child) {
    final Animation<double> t = CurvedAnimation(
      parent: _entry,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: t,
      builder: (BuildContext context, Widget? inner) {
        return Opacity(
          opacity: t.value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t.value)),
            child: inner,
          ),
        );
      },
      child: child,
    );
  }
}
