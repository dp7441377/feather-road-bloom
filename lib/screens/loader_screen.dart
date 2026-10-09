import 'dart:async';

import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/game_config.dart';
import '../theme.dart';
import '../widgets/decor_field.dart';

/// Branded splash.
///
/// Deep plum, the exact inverse of the cream Menu, so the pHash distance
/// between frame 1 and frame 2 can never collapse (rule 14).
///
/// Animation budget is deliberately tiny: one 900ms entry controller that
/// completes, and a stepped [Timer.periodic] for the progress bar. There is no
/// looping controller and no long-running tween anywhere on this screen — a perpetually
/// dirty frame pipeline means uiautomator never gets a settled tree and the
/// loader frame is lost.
class LoaderScreen extends StatefulWidget {
  const LoaderScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<LoaderScreen> createState() => _LoaderScreenState();
}

class _LoaderScreenState extends State<LoaderScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _entry,
    curve: const Interval(0.0, 0.56, curve: Curves.easeOut),
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 0.82,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutBack));

  Timer? _progressTimer;
  Timer? _doneTimer;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    // Start counting from the first rasterized frame, not from initState:
    // the native launch window would otherwise eat part of the 8 seconds.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) {
        return;
      }
      _entry.forward();
      _progressTimer = Timer.periodic(
        const Duration(milliseconds: AppConfig.loaderProgressStepMs),
        (Timer timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() {
            _progress = (_progress + 1 / AppConfig.loaderProgressSteps).clamp(
              0.0,
              1.0,
            );
          });
          if (_progress >= 1.0) {
            timer.cancel();
          }
        },
      );
      _doneTimer = Timer(
        const Duration(milliseconds: AppConfig.loaderDurationMs),
        () {
          if (mounted) {
            widget.onDone();
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _doneTimer?.cancel();
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loaderTop,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.bgLoader),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                AppColors.loaderTop.withValues(alpha: 0.86),
                AppColors.loaderMid.withValues(alpha: 0.78),
                AppColors.loaderBottom.withValues(alpha: 0.90),
              ],
            ),
          ),
          child: Stack(
            children: <Widget>[
              const Positioned.fill(
                child: DecorField(seed: 11, intensity: 0.9, dark: true),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(scale: _scale, child: _content()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.14),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 34,
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              AppAssets.spriteBirdHero,
              width: 148,
              height: 148,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 34),
        const Text(
          'FEATHER ROAD',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.0,
            color: AppColors.canvas,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'BLOOM',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: 6.0,
            color: AppColors.primary,
            shadows: <Shadow>[Shadow(color: Color(0x80EF8248), blurRadius: 18)],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'MEND THE PATH',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.4,
            color: AppColors.canvas.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 40),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 180,
            height: 8,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.canvas.withValues(alpha: 0.16),
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress,
                  heightFactor: 1,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[AppColors.primary, AppColors.secondary],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _dot(AppColors.success),
            const SizedBox(width: 12),
            _dot(AppColors.primary),
            const SizedBox(width: 12),
            _dot(AppColors.info),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'LOADING',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 3.0,
            color: AppColors.canvas.withValues(alpha: 0.48),
          ),
        ),
      ],
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
