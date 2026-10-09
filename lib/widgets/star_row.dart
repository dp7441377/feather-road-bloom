import 'package:flutter/material.dart';

import '../assets.dart';
import '../theme.dart';

/// Three stars with a sequential pop-in. The controller is owned by the
/// caller, driven forward once and allowed to complete — nothing here repeats.
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.earned,
    required this.progress,
    this.size = 54,
  });

  final int earned;

  /// 0..1 over the whole three-star sequence.
  final Animation<double> progress;

  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (BuildContext context, Widget? child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int i) {
            final bool won = i < earned;
            final double start = i * 0.22;
            final double t = won
                ? Curves.easeOutBack
                      .transform(
                        ((progress.value - start) / 0.34).clamp(0.0, 1.0),
                      )
                      .clamp(0.0, 1.4)
                : 1.0;
            final double scale = won ? 0.4 + 0.6 * t : 1.0;

            Widget star = Image.asset(
              AppAssets.spriteStar,
              width: size,
              height: size,
              fit: BoxFit.contain,
            );
            if (!won) {
              star = Opacity(
                opacity: 0.22,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    AppColors.inkMuted,
                    BlendMode.saturation,
                  ),
                  child: star,
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 12),
              child: Transform.scale(scale: scale, child: star),
            );
          }),
        );
      },
    );
  }
}
