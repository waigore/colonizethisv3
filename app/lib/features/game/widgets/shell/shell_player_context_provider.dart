// Riverpod provider for [ShellPlayerContext].
//
// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/observe_session_provider.dart';
import '../../flame/region_map/region_map.dart' show CtMapVisibilityMode;
import 'shell_player_context.dart';

final shellPlayerContextProvider = Provider<ShellPlayerContext>((ref) {
  MapTopology topologyFor(Game game) {
    try {
      return topologyForGame(ref.watch(gameServiceProvider), game);
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
