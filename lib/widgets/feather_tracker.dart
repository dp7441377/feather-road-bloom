import 'package:flutter/material.dart';

import '../assets.dart';
import '../theme.dart';

/// Three slots in the game header; each fills with a feather as it is picked up.
class FeatherTracker extends StatelessWidget {
  const FeatherTracker({
    super.key,
    required this.collected,
    required this.total,
  });

  final int collected;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(total, (int i) {
        final bool filled = i < collected;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
          child: SizedBox(
            width: 18,
            height: 18,
            child: filled
                ? Image.asset(
                    AppAssets.spriteFeather,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.ink.withValues(alpha: 0.12),
                    ),
                  ),
          ),
        );
      }),
    );
  }
}
