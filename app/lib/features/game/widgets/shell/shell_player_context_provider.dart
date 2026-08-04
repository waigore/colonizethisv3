import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/game_service/game_service.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/observe_session_provider.dart';
import '../../flame/region_map/region_map.dart' show CtMapVisibilityMode;
import 'shell_player_context.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_orders/src/orders/civilian_projected_tile.dart';
import 'package:colonizethis_logic/src/turn_to_year.dart';
import 'package:colonizethis_logic/src/civilians/spy_relocate_intel.dart';
import 'package:colonizethis_logic/src/civilians/civilians_missing_work_orders.dart';

MapTopology _topologyForGame(GameService service, Game game) {
  final mapData = tryGetGameMapData(() => service.getMapData(game.id));
  return mapData?.combinedTopology ?? const MapTopology();
}

/// Riverpod provider for [ShellPlayerContext] (Refs #4117 de-part).
final shellPlayerContextProvider = Provider<ShellPlayerContext>((ref) {
  MapTopology topologyFor(Game game) {
    try {
      return _topologyForGame(ref.watch(gameServiceProvider), game);
    } catch (_) {
      return const MapTopology();
    }
  }

  final game = ref.watch(currentGameProvider);
  final observe = ref.watch(observeSessionProvider);

  if (game == null) {
    return const ShellPlayerContext(
      effectiveHumanPlayerId: null,
      viewingPlayerId: null,
      mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
      playerView: null,
      omniscientDetail: false,
      showPlayerChrome: true,
      canMutateViaUi: true,
      debugCommandTargetPlayerId: null,
      inObservePhase: false,
      observeBannerLabel: null,
      treasuryNotDefined: false,
      cargoNotDefined: false,
    );
  }

  final humanId = game.players
      .where((p) => p.isHuman)
      .map((p) => p.id)
      .firstOrNull;

  if (!observe.isObserving) {
    final id = humanId ?? game.players.first.id;
    final topology = topologyFor(game);
    final view = buildPlayerView(game, topology, id);
    return ShellPlayerContext(
      effectiveHumanPlayerId: humanId,
      viewingPlayerId: id,
      mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
      playerView: view,
      omniscientDetail: false,
      showPlayerChrome: true,
      canMutateViaUi: true,
      debugCommandTargetPlayerId: id,
      inObservePhase: false,
      observeBannerLabel: null,
      treasuryNotDefined: false,
      cargoNotDefined: false,
    );
  }

  final topology = topologyFor(game);

  switch (observe.mode) {
    case ObserveMode.global:
      return ShellPlayerContext.globalObserve(
        debugCommandTargetPlayerId: observe.lastControlledPlayerId,
      );
    case ObserveMode.player:
      final targetId = observe.observedPlayerId ?? game.players.first.id;
      final target = game.playerById(targetId);
      final displayName = target?.displayName.trim();
      final bannerName = (displayName == null || displayName.isEmpty)
          ? targetId
          : displayName;
      final view = buildPlayerView(game, topology, targetId);
      return ShellPlayerContext(
        effectiveHumanPlayerId: null,
        viewingPlayerId: targetId,
        mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
        playerView: view,
        omniscientDetail: false,
        showPlayerChrome: true,
        canMutateViaUi: false,
        debugCommandTargetPlayerId: observe.lastControlledPlayerId,
        inObservePhase: true,
        observeBannerLabel: 'Observing: $targetId ($bannerName)',
        treasuryNotDefined: false,
        cargoNotDefined: false,
      );
    case ObserveMode.off:
      break;
  }

  final id = humanId ?? game.players.first.id;
  final view = buildPlayerView(game, topology, id);
  return ShellPlayerContext(
    effectiveHumanPlayerId: humanId,
    viewingPlayerId: id,
    mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
    playerView: view,
    omniscientDetail: false,
    showPlayerChrome: true,
    canMutateViaUi: true,
    debugCommandTargetPlayerId: id,
    inObservePhase: false,
    observeBannerLabel: null,
    treasuryNotDefined: false,
    cargoNotDefined: false,
  );
});
