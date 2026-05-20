import 'package:flutter/material.dart';

import 'route_paths.dart';
import '../features/debug_log/debug_log_viewer_screen.dart';
import '../features/game/flame/game_screen.dart';
import '../features/game/screens/diplomacy_detail_screen.dart';
import '../features/game/widgets/diplomacy_panel.dart' show FactionKind;
import '../features/game/screens/diplomacy_screen.dart';
import '../features/game/screens/production_screen.dart';
import '../features/game/screens/technology_screen.dart';
import '../features/shell/shell_screen.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

class Routes {
  Routes._();

  static const String shell = RoutePaths.shell;
  static const String game = RoutePaths.game;
  static const String debugLog = RoutePaths.debugLog;
  static const String production = RoutePaths.production;
  static const String diplomacy = RoutePaths.diplomacy;
  static const String diplomacyDetail = RoutePaths.diplomacyDetail;
  static const String technology = RoutePaths.technology;

  static Route<dynamic>? generate(RouteSettings settings) {
    switch (settings.name) {
      case RoutePaths.shell:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ShellScreen(),
        );
      case RoutePaths.game:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const GameScreen(),
        );
      case RoutePaths.debugLog:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const DebugLogViewerScreen(),
        );
      case RoutePaths.production:
      case RoutePaths.diplomacy:
      case RoutePaths.diplomacyDetail:
      case RoutePaths.technology:
        return _buildGameRoute(settings);
      default:
        return null;
    }
  }

  static Route<dynamic>? _buildGameRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, Object?>?;
    if (args == null) return null;

    final game = args['game'] as Game;
    final humanPlayerId = args['humanPlayerId'] as String;

    switch (settings.name) {
      case RoutePaths.production:
        final player = game.playerById(humanPlayerId)!;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ProductionScreen(game: game, player: player),
        );
      case RoutePaths.diplomacy:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              DiplomacyScreen(game: game, humanPlayerId: humanPlayerId),
        );
      case RoutePaths.diplomacyDetail:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => DiplomacyDetailScreen(
            game: game,
            humanPlayerId: humanPlayerId,
            factionId: args['factionId'] as String,
            factionDisplayName: args['factionDisplayName'] as String,
            kind: args['kind'] as FactionKind,
            relation: args['relation'] as DiplomacyRelation?,
          ),
        );
      case RoutePaths.technology:
        final player = game.playerById(humanPlayerId)!;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => TechnologyScreen(game: game, player: player),
        );
      default:
        return null;
    }
  }
}
