import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../core/services/game_service.dart';
import '../features/game/shell_player_context.dart';

/// Resolved inputs shared by the watch-then-compute "game summary" providers
/// (e.g. `treasurySummaryProvider`, `homeFleetCargoSummaryProvider`).
///
/// Carries the current [game], its resolved [shell] context, the non-null
/// scoped [playerId], and the cached map data ([tileMapByRegion] / [topology])
/// fetched via [gameService]. The map fields may be unavailable in widget tests
/// that mount game UI without Hive-backed services; callers must guard on
/// [hasMapData] before consuming them.
class GameSummaryContext {
  const GameSummaryContext({
    required this.game,
    required this.shell,
    required this.playerId,
    required this.orders,
    required this.tileMapByRegion,
    required this.topology,
  });

  final Game game;
  final ShellPlayerContext shell;
  final String playerId;
  final Orders orders;
  final Map<String, TileMapResult>? tileMapByRegion;
  final MapTopology topology;

  /// True when cached per-region tile maps are present and non-empty.
  bool get hasMapData => tileMapByRegion != null && tileMapByRegion!.isNotEmpty;
}

/// Shared watch-then-compute skeleton for game summary providers (#3279
/// target state #8). Callers pass values already read from Riverpod providers;
/// this helper centralises the guard/fetch/try-catch wrapper without accepting
/// [Ref] / [WidgetRef] parameters.
T computeGameSummary<T>({
  required Game? game,
  required ShellPlayerContext shell,
  required Orders orders,
  required GameService gameService,
  required T whenNoGame,
  required bool Function(ShellPlayerContext shell) notDefined,
  required T Function() whenNotDefined,
  required CtLogger log,
  required T Function(GameSummaryContext context) compute,
  required T Function(Game game, String playerId) onError,
}) {
  if (game == null) {
    return whenNoGame;
  }

  if (notDefined(shell)) {
    return whenNotDefined();
  }

  final playerId = shell.viewingPlayerId ?? shell.mapPlayerIdFor(game);

  try {
    final mapData = gameService.getMapData(game.id);
    return compute(
      GameSummaryContext(
        game: game,
        shell: shell,
        playerId: playerId,
        orders: orders,
        tileMapByRegion: mapData?.tileMapByRegion,
        topology: mapData?.combinedTopology ?? const MapTopology(),
      ),
    );
  } catch (e, stackTrace) {
    log.w('summary_failed gameId=${game.id}', error: e, stackTrace: stackTrace);
    return onError(game, playerId);
  }
}
