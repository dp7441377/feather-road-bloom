/// Tunables for the whole app. Values here are load-bearing for the capture
/// harness as much as for the gameplay — read the comments before changing one.
class AppConfig {
  const AppConfig._();

  /// Splash duration. EXACTLY 8000 (CLAUDE-flutter.md rule 13): the MCP capture
  /// agent needs 4-6s of cold-start overhead before its first screenshot.
  static const int loaderDurationMs = 8000;

  /// The loader progress bar advances in discrete steps instead of running one
  /// long tween — a continuous 8s animation keeps the frame pipeline dirty and
  /// uiautomator never gets a settled tree to dump.
  static const int loaderProgressStepMs = 400;
  static const int loaderProgressSteps = 20;

  /// Idle backstop on GameScreen. The capture agent cannot solve a swap puzzle,
  /// so the round resolves itself — but never before the agent has had time to
  /// photograph actual gameplay.
  static const int mountFloorMs = 26000;
  static const int idleWindowMs = 14000;
  static const int hardCapMs = 55000;

  /// Auto-resolve replays the scramble backwards at this cadence.
  static const int resolveStepMs = 130;

  static const int totalLevels = 12;
  static const int feathersPerLevel = 3;
  static const int totalFeathers = totalLevels * feathersPerLevel;

  // Motion.
  static const int screenFadeMs = 320;
  static const int swapMs = 220;
  static const int bloomMs = 180;
  static const int pressMs = 120;
  static const int celebrateMs = 600;
  static const int shakeMs = 500;
}
