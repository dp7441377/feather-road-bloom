import 'package:flutter/material.dart';

import '../theme.dart';
import 'clay_disc.dart';

/// Shared header. Owns the 44px status-bar inset (CLAUDE-flutter.md rule 6)
/// so no screen can forget it, plus the clay backing surface.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 44, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised.withValues(alpha: 0.86),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
        border: Border(
          bottom: BorderSide(
            color: AppColors.ink.withValues(alpha: 0.08),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 44,
            height: 44,
            child: onBack == null
                ? null
                : ClayDisc(icon: Icons.arrow_back_rounded, onTap: onBack!),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: AppColors.ink,
              ),
            ),
          ),
          SizedBox(
            width: 68,
            height: 44,
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}
