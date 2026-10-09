import 'package:flutter/material.dart';

import '../theme.dart';

/// The shared stat card (CLAUDE-flutter.md rule 22).
///
/// No raster element lives inside, so three pills in a row can never end up
/// visually different sizes. Colour carries the semantics, the number is big,
/// the caption is small and uppercase. Used identically on Menu, Game and
/// Result.
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.value,
    required this.label,
    required this.valueColor,
    this.emphasis = 1.0,
  });

  final String value;
  final String label;
  final Color valueColor;

  /// Transient scale pulse, driven by the caller when the value changes.
  final double emphasis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: valueColor.withValues(alpha: 0.33),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: valueColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          Transform.scale(
            scale: emphasis,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 22,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: valueColor,
                fontFeatures: kTabularFigures,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            style: const TextStyle(
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
