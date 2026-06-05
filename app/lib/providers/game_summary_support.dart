import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/shell_player_context.dart';
import 'game_service_provider.dart';
import 'games_provider.dart';

/// Resolved inputs shared by the watch-then-compute "game summary" providers
/// (e.g. `treasurySummaryProvider`, `homeFleetCargoSummaryProvider`).
///
/// Carries the current [game], its resolved [shell] context, the non-null
/// scoped [playerId], and the cached map data ([tileMapByRegion] / [topology])
/// fetched via `gameServiceProvider`. The map fields may be unavailable in
/// widget tests that mount game UI without Hive-backed services; callers must
/// guard on [hasMapData] before consuming them.
class GameSummaryContext {
  const GameSummaryContext({
    required this.ref,
    required this.game,
    required this.shell,
    required this.playerId,
    required this.tileMapByRegion,
    required this.topology,
  });

  final Ref ref;
  final Game game;
  final ShellPlayerContext shell;
  final String playerId;
  final Map<String, TileMapResult>? tileMapByRegion;
  final MapTopology topology;

  /// True when cached per-region tile maps are present and non-empty.
  bool get hasMapData => tileMapByRegion != null && tileMapByRegion!.isNotEmpty;
}

/// Shared watch-then-compute skeleton for game summary providers (#3279
/// target state #8). Centralises the identical preamble previously duplicated
/// across `treasury_summary_provider.dart` and `home_fleet_cargo_provider.dart`:
///
/// 1. watch `currentGameProvider`; return [whenNoGame] when absent;
/// 2. watch `shellPlayerContextProvider`; return [whenNotDefined] when
///    [notDefined] holds (e.g. global observe);
/// 3. resolve the scoped player id and cached map data, then run [compute]
///    inside a guarded `try`; on failure log via [log] and return [onError].
///
/// This is intentionally a minimal free function rather than a base class: the
/// two known call sites diverge in their per-summary value computation, so the
/// only stable shared surface is this guard/fetch/try-catch wrapper.
T watchGameSummary<T>(
  Ref ref, {
  required T whenNoGame,
  required bool Function(ShellPlayerContext shell) notDefined,
  required T Function() whenNotDefined,
  required CtLogger log,
  required T Function(GameSummaryContext context) compute,
  required T Function(Game game, String playerId) onError,
}) {
  final game = ref.watch(currentGameProvider);
  if (game == null) {
    return whenNoGame;
  }

  final shell = ref.watch(shellPlayerContextProvider);
  if (notDefined(shell)) {
    return whenNotDefined();
  }

  final playerId = shell.viewingPlayerId ?? shell.mapPlayerIdFor(game);

  try {
    final service = ref.watch(gameServiceProvider);
    final mapData = service.getMapData(game.id);
    return compute(
      GameSummaryContext(
        ref: ref,
        game: game,
        shell: shell,
        playerId: playerId,
        tileMapByRegion: mapData?.tileMapByRegion,
        topology: mapData?.combinedTopology ?? const MapTopology(),
      ),
    );
  } catch (e, stackTrace) {
    log.w('summary_failed gameId=${game.id}', error: e, stackTrace: stackTrace);
    return onError(game, playerId);
  }
}
