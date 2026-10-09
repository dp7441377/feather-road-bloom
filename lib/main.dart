import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'game/game_config.dart';
import 'panels/level_map_panel.dart';
import 'panels/tutorial_panel.dart';
import 'screens/game_screen.dart';
import 'screens/loader_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/result_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Without an explicit semantics handle Flutter ships an empty accessibility
  // tree in release builds on these devices, and every text-driven UI probe
  // degrades to blind coordinate taps.
  SemanticsBinding.instance.ensureSemantics();
  runApp(const FeatherRoadBloomApp());
}

enum Screen { loader, menu, levelMap, tutorial, game, result }

class FeatherRoadBloomApp extends StatelessWidget {
  const FeatherRoadBloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feather Road Bloom',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppFlow(),
    );
  }
}

/// The whole navigation model: one enum plus setState, crossfaded by an
/// AnimatedSwitcher. No router, no deep links, no back stack to fall out of.
class AppFlow extends StatefulWidget {
  const AppFlow({super.key});

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  Screen _screen = Screen.loader;

  int _level = 1;
  int _unlockedLevel = 1;
  int _feathersTotal = 0;
  final Map<int, int> _starsByLevel = <int, int>{};

  RoundOutcome? _outcome;

  void _go(Screen screen) {
    if (!mounted) {
      return;
    }
    setState(() => _screen = screen);
  }

  /// The menu CTA goes straight into the game with the current level. An
  /// intermediate picker between Menu and Game is what traps an automated
  /// walkthrough, so the picker stays reachable but never mandatory.
  void _startLevel(int level) {
    setState(() {
      _level = level.clamp(1, AppConfig.totalLevels);
      _screen = Screen.game;
    });
  }

  void _onRoundFinished(RoundOutcome outcome) {
    setState(() {
      _outcome = outcome;
      _screen = Screen.result;
      if (outcome.won) {
        final int previousStars = _starsByLevel[outcome.level] ?? 0;
        if (outcome.stars > previousStars) {
          _starsByLevel[outcome.level] = outcome.stars;
        }
        // Feathers bank once per level, so replaying cannot inflate the count.
        if (previousStars == 0) {
          _feathersTotal += outcome.feathers;
        }
        if (outcome.level >= _unlockedLevel &&
            _unlockedLevel < AppConfig.totalLevels) {
          _unlockedLevel = outcome.level + 1;
        }
      }
    });
  }

  /// Android back never leaves the app: a popped-empty back stack shows the
  /// launcher, which pollutes an automated capture sequence.
  void _onBack() {
    switch (_screen) {
      case Screen.loader:
      case Screen.menu:
        break;
      case Screen.levelMap:
      case Screen.tutorial:
      case Screen.result:
        _go(Screen.menu);
      case Screen.game:
        _go(Screen.levelMap);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          _onBack();
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: AppConfig.screenFadeMs),
        child: KeyedSubtree(
          key: ValueKey<String>('${_screen.name}-$_level'),
          child: _current(),
        ),
      ),
    );
  }

  Widget _current() {
    switch (_screen) {
      case Screen.loader:
        return LoaderScreen(onDone: () => _go(Screen.menu));

      case Screen.menu:
        return MenuScreen(
          unlockedLevel: _unlockedLevel,
          feathersTotal: _feathersTotal,
          onStart: () => _startLevel(_unlockedLevel),
          onRules: () => _go(Screen.tutorial),
        );

      case Screen.levelMap:
        return LevelMapPanel(
          unlockedLevel: _unlockedLevel,
          starsByLevel: _starsByLevel,
          feathersTotal: _feathersTotal,
          onPlayLevel: _startLevel,
          onBack: () => _go(Screen.menu),
        );

      case Screen.tutorial:
        return TutorialPanel(
          onStart: () => _startLevel(_unlockedLevel),
          onBack: () => _go(Screen.menu),
        );

      case Screen.game:
        return GameScreen(
          key: ValueKey<int>(_level),
          level: _level,
          onFinished: _onRoundFinished,
          onBack: () => _go(Screen.levelMap),
        );

      case Screen.result:
        final RoundOutcome outcome =
            _outcome ??
            const RoundOutcome(
              level: 1,
              won: false,
              movesUsed: 0,
              moveLimit: 0,
              movesLeft: 0,
              feathers: 0,
              stars: 0,
            );
        return ResultScreen(
          outcome: outcome,
          hasNextLevel: outcome.level < AppConfig.totalLevels,
          onNextLevel: () => _startLevel(outcome.level + 1),
          onPlayAgain: () => _startLevel(outcome.level),
          onMenu: () => _go(Screen.menu),
          onLevelMap: () => _go(Screen.levelMap),
        );
    }
  }
}
