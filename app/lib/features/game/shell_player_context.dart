import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/game_service_provider.dart';
import '../../providers/games_provider.dart';
import '../../providers/observe_session_provider.dart';
import 'flame/region_map_component.dart' show CtMapVisibilityMode;

/// Resolved play/observe context for the in-game shell. SPEC/ui/observe-mode.md.
class ShellPlayerContext {
  const ShellPlayerContext({
    required this.effectiveHumanPlayerId,
    required this.viewingPlayerId,
    required this.mapVisibilityMode,
    required this.playerView,
    required this.omniscientDetail,
    required this.showPlayerChrome,
    required this.canMutateViaUi,
    required this.debugCommandTargetPlayerId,
    required this.inObservePhase,
    required this.observeBannerLabel,
    required this.treasuryNotDefined,
    required this.cargoNotDefined,
  });

  final String? effectiveHumanPlayerId;
  final String? viewingPlayerId;
  final CtMapVisibilityMode mapVisibilityMode;
  final PlayerView? playerView;
  final bool omniscientDetail;
  final bool showPlayerChrome;
  final bool canMutateViaUi;
  final String? debugCommandTargetPlayerId;
  final bool inObservePhase;
  final String? observeBannerLabel;
  final bool treasuryNotDefined;
  final bool cargoNotDefined;

  /// Non-null player id for widgets that require a GP id string.
  String mapPlayerIdFor(Game game) =>
      viewingPlayerId ??
      effectiveHumanPlayerId ??
      game.players.first.id;
}

final shellPlayerContextProvider = Provider<ShellPlayerContext>((ref) {
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

  final humanId =
      game.players.where((p) => p.isHuman).map((p) => p.id).firstOrNull;

  if (!observe.isObserving) {
    final id = humanId ?? game.players.first.id;
    final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
    final topology = mapData?.combinedTopology ?? const MapTopology();
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

  final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
  final topology = mapData?.combinedTopology ?? const MapTopology();

  switch (observe.mode) {
    case ObserveMode.global:
      return ShellPlayerContext(
        effectiveHumanPlayerId: null,
        viewingPlayerId: null,
        mapVisibilityMode: CtMapVisibilityMode.full,
        playerView: null,
        omniscientDetail: true,
        showPlayerChrome: false,
        canMutateViaUi: false,
        debugCommandTargetPlayerId: observe.lastControlledPlayerId,
        inObservePhase: true,
        observeBannerLabel: 'Observing: global',
        treasuryNotDefined: true,
        cargoNotDefined: true,
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
