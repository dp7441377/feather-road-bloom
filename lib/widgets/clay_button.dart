import 'package:flutter/material.dart';

import '../assets.dart';
import '../game/game_config.dart';
import '../theme.dart';

/// The single button widget for the whole app.
///
/// Icon size is locked at 24 and the label line height is pinned to 24 too, so
/// the icon and the text share one baseline and nothing can drift between
/// screens (CLAUDE-flutter.md rule 21).
class ClayButton extends StatefulWidget {
  const ClayButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.primary = true,
    this.height = 62,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool primary;
  final double height;

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: AppConfig.pressMs),
    reverseDuration: const Duration(milliseconds: 140),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool primary = widget.primary;
    final double radius = primary ? 26 : 22;
    final double fontSize = primary ? 17 : 14;

    final Widget label = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.icon != null) ...<Widget>[
          Icon(widget.icon, size: 24, color: AppColors.ink),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              height: 24 / fontSize,
              fontWeight: primary ? FontWeight.w900 : FontWeight.w800,
              letterSpacing: primary ? 1.4 : 1.2,
              color: primary
                  ? AppColors.ink
                  : AppColors.ink.withValues(alpha: 0.78),
            ),
          ),
        ),
      ],
    );

    // Primary: AI texture underneath, warm gradient wash on top of it.
    final Widget face = primary
        ? Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[
                  AppColors.primary.withValues(alpha: 0.92),
                  AppColors.secondary.withValues(alpha: 0.92),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.canvas.withValues(alpha: 0.55),
                  width: 2,
                ),
              ),
            ),
            child: Center(child: label),
          )
        : SizedBox(
            height: widget.height,
            width: double.infinity,
            child: Center(child: label),
          );

    return AnimatedBuilder(
      animation: _press,
      builder: (BuildContext context, Widget? child) {
        return Transform.scale(scale: 1.0 - 0.04 * _press.value, child: child);
      },
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          height: widget.height,
          width: double.infinity,
          decoration: primary ? _primaryShell(radius) : _secondaryShell(radius),
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (TapDownDetails details) => _press.forward(),
            onTapUp: (TapUpDetails details) => _press.reverse(),
            onTapCancel: _press.reverse,
            borderRadius: BorderRadius.circular(radius),
            child: face,
          ),
        ),
      ),
    );
  }

  BoxDecoration _primaryShell(double radius) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: AppColors.primary,
      image: const DecorationImage(
        image: AssetImage(AppAssets.buttonCta),
        fit: BoxFit.cover,
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: AppColors.secondary.withValues(alpha: 0.42),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  BoxDecoration _secondaryShell(double radius) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: AppColors.ink.withValues(alpha: 0.06),
      border: Border.all(
        color: AppColors.ink.withValues(alpha: 0.16),
        width: 1.5,
      ),
    );
  }
}
