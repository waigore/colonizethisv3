import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';
import 'order_suggestion_army_move_picker.dart';
import 'order_suggestion_probe_validator.dart';

/// Inputs for populating per-player army-move picker destination caches.
///
/// SPEC/program/order-suggestions.md — cache contract; Refs #4350.
class ArmyMovePickerSnapshot {
  const ArmyMovePickerSnapshot({
    required this.game,
    required this.playerId,
    required this.playerView,
    required this.topology,
    required this.currentOrders,
    this.sharedCandidateValidator,
  });

  final Game game;
  final String playerId;
  final PlayerView playerView;
  final MapTopology topology;
  final Orders currentOrders;
  final IncrementalCandidateValidator? sharedCandidateValidator;
}

/// Per-player cache of [armyMovePickerDestinations] for overlay Move/Invade.
///
/// Callers own instance lifetime and [refresh] boundaries (same as work-target
/// cache: load/start, turn change, turn-resolution complete, draft mutation).
class PerPlayerArmyMovePickerCache {
  final Map<String, Map<String, List<ArmyMovePickerDestination>>>
  _destinationsByPlayerAndArmy = {};

  List<ArmyMovePickerDestination> destinationsForArmy(
    String playerId,
    String armyId,
  ) {
    final playerCache = _destinationsByPlayerAndArmy[playerId];
    if (playerCache == null) return const [];
    return playerCache[armyId] ?? const [];
  }

  /// Army ids whose cached destinations include [fullProvinceId].
  List<String> armyIdsThatCanReach(String playerId, String fullProvinceId) {
    final playerCache = _destinationsByPlayerAndArmy[playerId];
    if (playerCache == null) return const [];
    final out = <String>[];
    for (final entry in playerCache.entries) {
      if (entry.value.any((d) => d.fullProvinceId == fullProvinceId)) {
        out.add(entry.key);
      }
    }
    out.sort();
    return out;
  }

  /// Non-Home field armies stationed in [provinceId] that have ≥1 destination.
  List<String> stationedFieldArmyIdsWithDestinations(
    String playerId,
    String provinceId,
    Game game,
  ) {
    final out = <String>[];
    for (final army in game.worldState.armies) {
      if (army.ownerId != playerId || army.isHomeArmy) continue;
      if (army.stationedProvinceId != provinceId) continue;
      if (army.regimentUnitIds.isEmpty) continue;
      if (destinationsForArmy(playerId, army.id).isEmpty) continue;
      out.add(army.id);
    }
    out.sort();
    return out;
  }

  /// Non-Home field armies stationed in [provinceId] (ignore destinations).
  List<String> stationedFieldArmyIdsInProvince(
    String playerId,
    String provinceId,
    Game game,
  ) {
    final out = <String>[
      for (final army in game.worldState.armies)
        if (army.ownerId == playerId &&
            !army.isHomeArmy &&
            army.stationedProvinceId == provinceId &&
            army.regimentUnitIds.isNotEmpty)
          army.id,
    ]..sort();
    return out;
  }

  void refresh(ArmyMovePickerSnapshot snapshot) {
    final sharedValidator =
        snapshot.sharedCandidateValidator ??
        buildIncrementalCandidateValidator(
          game: snapshot.game,
          topology: snapshot.topology,
          playerId: snapshot.playerId,
          baseOrders: snapshot.currentOrders,
          resolution: orderResolutionContextFromView(
            snapshot.playerView,
            snapshot.game,
          ),
        );
    final ownedProvinceIds = <String>{
      for (final e in snapshot.playerView.provincesById.entries)
        if (e.value.ownerId == snapshot.playerId) e.key,
    };
    final nextByArmy = <String, List<ArmyMovePickerDestination>>{};
    for (final army in snapshot.game.worldState.armies) {
      if (army.ownerId != snapshot.playerId) continue;
      if (army.isHomeArmy) continue;
      if (army.regimentUnitIds.isEmpty) continue;
      nextByArmy[army.id] = armyMovePickerDestinations(
        game: snapshot.game,
        topology: snapshot.topology,
        playerId: snapshot.playerId,
        army: army,
        currentOrders: snapshot.currentOrders,
        playerOwnedFullProvinceIds: ownedProvinceIds,
        sharedCandidateValidator: sharedValidator,
        resolution: orderResolutionContextFromView(
          snapshot.playerView,
          snapshot.game,
        ),
      );
    }
    _destinationsByPlayerAndArmy[snapshot.playerId] = nextByArmy;
  }

  void clear() {
    _destinationsByPlayerAndArmy.clear();
  }
}
