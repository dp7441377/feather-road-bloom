/// Centralized asset paths. Every constant here MUST be referenced from
/// lib/screens, lib/panels or lib/widgets (CLAUDE-flutter.md rule 12).
///
/// `assets/icon_1024.png` is deliberately absent: it is the launcher-icon
/// source only, is excluded from `pubspec.yaml` flutter.assets and must never
/// be loaded at runtime.
class AppAssets {
  const AppAssets._();

  static const String bgLoader = 'assets/bg_loader.png';
  static const String bgMenu = 'assets/bg_menu.png';
  static const String bgMap = 'assets/bg_map.png';
  static const String bgGame = 'assets/bg_game.png';
  static const String bgResult = 'assets/bg_result.png';

  static const String spriteBirdHero = 'assets/sprite_bird_hero.png';
  static const String spriteFeather = 'assets/sprite_feather.png';
  static const String spriteNest = 'assets/sprite_nest.png';
  static const String spriteGarden = 'assets/sprite_garden.png';
  static const String spriteStar = 'assets/sprite_star.png';

  static const String buttonCta = 'assets/button_cta.png';
}
