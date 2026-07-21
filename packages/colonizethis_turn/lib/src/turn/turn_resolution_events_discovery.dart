import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'turn_event_sink.dart';
import 'turn_resolution_events_common.dart';
import 'turn_resolution_helpers.dart';

Set<String> _seaZonesAtSeaForPlayer(Game game, String playerId) {
  final zones = <String>{};
  for (final fleet in game.worldState.fleets) {
    if (fleet.ownerId != playerId ||
        !fleet.isAtSea ||
        fleet.seaZoneId == null) {
      continue;
    }
    final localSeaZoneId = fleet.seaZoneId!;
    final prefixed = localSeaZoneId.contains('|')
        ? localSeaZoneId
        : ProvinceId.full(fleet.regionId, localSeaZoneId);
    zones.add(prefixed);
  }
  return zones;
}

/// Emit work_order_completed for units that finished deterministic build/work targets.
void emitWorkOrderCompletedEvents(
  Game stateBefore,
  Game stateAfter,
  int turn,
  TurnEventSink sink,
) {
  final beforeById = stateBefore.worldState.allUnitsById;
  final afterById = stateAfter.worldState.allUnitsById;
  final supportedTargets = <String>{
    kWorkTargetBuildImprovement,
    kWorkTargetUpgradeTown,
    kWorkTargetBuildRoad,
    kWorkTargetBuildPort,
    kWorkTargetBuildFort,
    kWorkTargetBuildRail,
    kWorkTargetExplore,
  };
  for (final entry in beforeById.entries) {
    final beforeUnit = entry.value;
    final beforeWork = beforeUnit.currentWork;
    if (beforeWork == null ||
        beforeWork.remainingTurns > 1 ||
        !supportedTargets.contains(beforeWork.workTarget)) {
      continue;
    }
    final afterUnit = afterById[entry.key];
    if (afterUnit == null || afterUnit.currentWork != null) {
      continue;
    }
    final provinceId =
        Unit.provinceIdFromTileKey(beforeWork.tileKey) ??
        beforeUnit.locationProvinceId;
    final event = WorkOrderCompletedEvent(
      playerId: beforeUnit.ownerId,
      unitId: beforeUnit.id,
      workTarget: beforeWork.workTarget,
      targetTileKey: beforeWork.tileKey,
      provinceId: provinceId,
      turnNumber: turn,
    );
    sink.emit(event);
  }
}

/// Emit player-scoped province/sea discovery outcomes for this resolved turn.
///
/// [beforeIndex]/[afterIndex] may be supplied by callers that already built the
/// per-state [ProvinceVisibilityIndex] (e.g. the turn-resolution pipeline reuses
/// the same indices for the news digest) so it is computed once per turn rather
/// than once here and again in `buildTurnNewsDigestForComplete`
/// (`SPEC/program/turn-resolution.md` and the turn-resolution budget rule). When
/// omitted, each index is built from the matching state, preserving prior
/// behaviour for standalone callers.
void emitPlayerDiscoveryEvents(
  Game stateBefore,
  Game stateAfter,
  int turn,
  TurnEventSink sink, {
  ProvinceVisibilityIndex? beforeIndex,
  ProvinceVisibilityIndex? afterIndex,
}) {
  final resolvedBeforeIndex =
      beforeIndex ?? buildProvinceVisibilityIndex(stateBefore);
  final resolvedAfterIndex =
      afterIndex ?? buildProvinceVisibilityIndex(stateAfter);
  final sortedPlayerIds = sortedPlayerIdsForTurnEvents(stateAfter);
  for (final playerId in sortedPlayerIds) {
    _emitPlayerProvinceDiscoveryEvents(
      stateAfter: stateAfter,
      playerId: playerId,
      turn: turn,
      beforeIndex: resolvedBeforeIndex,
      afterIndex: resolvedAfterIndex,
      sink: sink,
    );
    final beforeSea = _seaZonesAtSeaForPlayer(stateBefore, playerId);
    final afterSea = _seaZonesAtSeaForPlayer(stateAfter, playerId);
    final newlyDiscovered = afterSea.difference(beforeSea).toList()..sort();
    for (final seaZoneId in newlyDiscovered) {
      final event = PlayerSeaZoneDiscoveredEvent(
        playerId: playerId,
        seaZoneId: seaZoneId,
        turnNumber: turn,
      );
      sink.emit(event);
    }
  }
}

void _emitPlayerProvinceDiscoveryEvents({
  required Game stateAfter,
  required String playerId,
  required int turn,
  required ProvinceVisibilityIndex beforeIndex,
  required ProvinceVisibilityIndex afterIndex,
  required TurnEventSink sink,
}) {
  for (final province in stateAfter.worldState.allProvinces()) {
    final fullProvinceId = prefixedProvinceId(province);
    final wasKnown = beforeIndex.isKnownToPlayer(playerId, fullProvinceId);
    final nowKnown = afterIndex.isKnownToPlayer(playerId, fullProvinceId);
    if (wasKnown || !nowKnown) {
      continue;
    }
    final event = PlayerProvinceDiscoveredEvent(
      playerId: playerId,
      provinceId: fullProvinceId,
      turnNumber: turn,
    );
    sink.emit(event);
  }
}
