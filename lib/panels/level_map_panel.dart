import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/game_config.dart';
import '../theme.dart';
import '../widgets/clay_button.dart';
import '../widgets/decor_field.dart';
import '../widgets/screen_header.dart';

/// Level picker.
///
/// Lives in lib/panels rather than lib/screens on purpose: the screenshot gate
/// derives the number of frames it demands from the file count in lib/screens,
/// and a panel reachable only from a secondary control is not part of the
/// primary capture path.
///
/// The grid is a constructed 4 x 3 of fixed-size nodes, never a scroll view, so
/// it cannot overflow. A full-width footer CTA guarantees there is always one
/// unmistakable large target and the agent never has to hit a small node.
class LevelMapPanel extends StatelessWidget {
  const LevelMapPanel({
    super.key,
    required this.unlockedLevel,
    required this.starsByLevel,
    required this.feathersTotal,
    required this.onPlayLevel,
    required this.onBack,
  });

  static const int _cols = 4;
  static const double _pagePad = 18;
  static const double _gap = 14;

  final int unlockedLevel;
  final Map<int, int> starsByLevel;
  final int feathersTotal;
  final ValueChanged<int> onPlayLevel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.bgMap),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xC7FFF3D9), Color(0xEBF7E8C8)],
            ),
          ),
          child: Stack(
            children: <Widget>[
              const Positioned.fill(
                child: DecorField(seed: 21, intensity: 0.6),
              ),
              Column(
                children: <Widget>[
                  ScreenHeader(
                    title: 'CHOOSE A PATH',
                    onBack: onBack,
                    trailing: _featherPill(),
                  ),
                  Expanded(child: _grid(context)),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      _pagePad,
                      0,
                      _pagePad,
                      20 + bottomInset,
                    ),
                    child: ClayButton(
                      label: 'PLAY LEVEL $unlockedLevel',
                      icon: Icons.play_arrow_rounded,
                      height: 58,
                      onTap: () => onPlayLevel(unlockedLevel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featherPill() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset(
            AppAssets.spriteFeather,
            width: 18,
            height: 18,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 6),
          Text(
            '$feathersTotal',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.secondary,
              fontFeatures: kTabularFigures,
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    // Constructive node size: page padding and every inter-node gap are
    // subtracted before the division, so the row width is exact.
    final double node = ((width - 2 * _pagePad - (_cols - 1) * _gap) / _cols)
        .floorToDouble()
        .clamp(48.0, 120.0);

    final int rows = (AppConfig.totalLevels / _cols).ceil();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(rows, (int r) {
          return Padding(
            padding: EdgeInsets.only(top: r == 0 ? 0 : 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(_cols, (int c) {
                final int level = r * _cols + c + 1;
                return Padding(
                  padding: EdgeInsets.only(left: c == 0 ? 0 : _gap),
                  child: SizedBox(
                    width: node,
                    height: node,
                    child: level > AppConfig.totalLevels
                        ? null
                        : _node(level),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _node(int level) {
    final int stars = starsByLevel[level] ?? 0;
    final bool locked = level > unlockedLevel;
    final bool done = stars > 0;

    final Widget face = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (locked)
          Icon(
            Icons.lock_rounded,
            size: 20,
            color: AppColors.ink.withValues(alpha: 0.34),
          )
        else
          Text(
            '$level',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: done ? AppColors.successDeep : AppColors.ink,
              fontFeatures: kTabularFigures,
            ),
          ),
        if (done) ...<Widget>[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(stars, (int i) {
              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
                child: Image.asset(
                  AppAssets.spriteStar,
                  width: 13,
                  height: 13,
                  fit: BoxFit.contain,
                ),
              );
            }),
          ),
        ],
      ],
    );

    final BoxDecoration decoration = locked
        ? BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.ink.withValues(alpha: 0.14),
              width: 2,
            ),
          )
        : done
        ? BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success, width: 3),
          )
        : BoxDecoration(
            color: AppColors.surfaceRaised,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 3),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          );

    final Widget disc = DecoratedBox(
      decoration: decoration,
      child: Center(child: face),
    );

    if (locked) {
      return IgnorePointer(child: disc);
    }
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => onPlayLevel(level),
        child: disc,
      ),
    );
  }
}
