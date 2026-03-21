import 'package:flutter/material.dart';

import '../features/debug_log/debug_log_viewer_screen.dart';
import '../features/game/flame/game_screen.dart';
import '../features/game/widgets/diplomacy_screen.dart';
import '../features/game/widgets/production_screen.dart';
import '../features/game/widgets/technology_screen.dart';
import '../features/shell/shell_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

class Routes {
  Routes._();

  static const String shell = '/';
  static const String game = '/game';
  static const String debugLog = '/debug-log';
  static const String production = '/game/production';
  static const String diplomacy = '/game/diplomacy';
  static const String technology = '/game/technology';

  static Route<dynamic>? generate(RouteSettings settings) {
    switch (settings.name) {
      case shell:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const ShellScreen(),
        );
      case game:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const GameScreen(),
        );
      case debugLog:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const DebugLogViewerScreen(),
        );
      case production:
      case diplomacy:
      case technology:
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
      case production:
        final player = game.players.firstWhere((p) => p.id == humanPlayerId);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ProductionScreen(game: game, player: player),
        );
      case diplomacy:
        final topology = args['topology'] as MapTopology;
        final currentOrders =
            args['currentOrders'] as Orders? ?? const Orders();
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => DiplomacyScreen(
            game: game,
            humanPlayerId: humanPlayerId,
            topology: topology,
            currentOrders: currentOrders,
            onOrdersChanged: (newOrders) {},
          ),
        );
      case technology:
        final player = game.players.firstWhere((p) => p.id == humanPlayerId);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => TechnologyScreen(
            game: game,
            player: player,
          ),
        );
      default:
        return null;
    }
  }
}
