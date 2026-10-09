import 'package:flutter/material.dart';

import '../theme.dart';

/// Round clay icon button. Used for the header back control and the in-game
/// RESET control, so both are guaranteed the same size and the same shadow.
class ClayDisc extends StatelessWidget {
  const ClayDisc({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.iconSize = 22,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceRaised,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: AppColors.ink.withValues(alpha: 0.24),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: iconSize,
            color: AppColors.ink,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}
