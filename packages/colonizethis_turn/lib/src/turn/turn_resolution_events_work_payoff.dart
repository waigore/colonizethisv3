import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'turn_resolution_events_common.dart';
import 'turn_event_sink.dart';

/// Ids-only payoff snapshot captured from [stateAfter] (Refs #4778).
class WorkOrderPayoffSnapshot {
  const WorkOrderPayoffSnapshot({
    this.payoffKind,
    this.payoffCommodityId,
    this.payoffLevel,
  });

  final String? payoffKind;
  final String? payoffCommodityId;
  final int? payoffLevel;
}

WorkOrderPayoffSnapshot workOrderPayoffSnapshot({
  required Game stateAfter,
  required String workTarget,
  required String tileKey,
}) {
  final resourceId = stateAfter.worldState.resourceAtTile(tileKey);
  final provinceId = Unit.provinceIdFromTileKey(tileKey);
  final province = provinceId == null
      ? null
      : stateAfter.worldState.tryGetProvince(provinceId);
  return switch (workTarget) {
    kWorkTargetExplore => const WorkOrderPayoffSnapshot(
      payoffKind: WorkOrderPayoffKind.fullyVisible,
    ),
    kWorkTargetBuildImprovement => WorkOrderPayoffSnapshot(
      payoffKind: WorkOrderPayoffKind.yieldRaise,
      payoffCommodityId: resourceId,
    ),
    kWorkTargetUpgradeTown => _townSnapshot(province?.townDevelopmentLevel),
    kWorkTargetBuildRoad => const WorkOrderPayoffSnapshot(
      payoffKind: WorkOrderPayoffKind.bindsCapital,
    ),
    kWorkTargetBuildPort => const WorkOrderPayoffSnapshot(
      payoffKind: WorkOrderPayoffKind.portPresent,
    ),
    kWorkTargetBuildRail => const WorkOrderPayoffSnapshot(
      payoffKind: WorkOrderPayoffKind.railroadPresent,
    ),
    kWorkTargetBuildFort => _fortSnapshot(province?.fortLevel),
    kWorkTargetPurchaseLand => _purchaseSnapshot(resourceId),
    _ => const WorkOrderPayoffSnapshot(),
  };
}

WorkOrderCompletedEvent buildWorkOrderCompletedEvent({
  required Game stateAfter,
  required String playerId,
  required String unitId,
  required String workTarget,
  required String targetTileKey,
  required String provinceId,
  required int turnNumber,
  String? revealedResourceId,
}) {
  final snap = workTarget == kWorkTargetProspect
      ? const WorkOrderPayoffSnapshot()
      : workOrderPayoffSnapshot(
          stateAfter: stateAfter,
          workTarget: workTarget,
          tileKey: targetTileKey,
        );
  return WorkOrderCompletedEvent(
    playerId: playerId,
    unitId: unitId,
    workTarget: workTarget,
    targetTileKey: targetTileKey,
    provinceId: provinceId,
    turnNumber: turnNumber,
    revealedResourceId: revealedResourceId,
    payoffKind: snap.payoffKind,
    payoffCommodityId: snap.payoffCommodityId,
    payoffLevel: snap.payoffLevel,
  );
}

/// Same-turn 1-turn Purchase land is missing from pre-Build/Work `currentWork`.
void emitSamePhasePurchaseLandCompletedEvents(
  Game stateBefore,
  Game stateAfter,
  int turn,
  TurnEventSink sink,
  Orders orders,
) {
  final afterById = stateAfter.worldState.allUnitsById;
  for (final playerId in sortedPlayerIdsForTurnEvents(stateAfter)) {
    final newly = _newlyPurchasedTiles(
      stateBefore: stateBefore,
      stateAfter: stateAfter,
      playerId: playerId,
    );
    if (newly.isEmpty) continue;
    final purchaseByTile = <String, String>{};
    for (final order in orders.workOrdersByPlayerId[playerId] ?? const []) {
      if (order.target != kWorkTargetPurchaseLand ||
          order.targetTileKey.isEmpty) {
        continue;
      }
      purchaseByTile.putIfAbsent(order.targetTileKey, () => order.unitId);
    }
    for (final tileKey in newly) {
      final unitId = purchaseByTile[tileKey];
      if (unitId == null) continue;
      final unit = afterById[unitId];
      final provinceId =
          Unit.provinceIdFromTileKey(tileKey) ?? unit?.locationProvinceId ?? '';
      sink.emit(
        buildWorkOrderCompletedEvent(
          stateAfter: stateAfter,
          playerId: playerId,
          unitId: unitId,
          workTarget: kWorkTargetPurchaseLand,
          targetTileKey: tileKey,
          provinceId: provinceId,
          turnNumber: turn,
        ),
      );
    }
  }
}

List<String> _newlyPurchasedTiles({
  required Game stateBefore,
  required Game stateAfter,
  required String playerId,
}) {
  final before = stateBefore.worldState.purchasedTilesByTileKey;
  final after = stateAfter.worldState.purchasedTilesByTileKey;
  final newly = <String>[];
  for (final entry in after.entries) {
    if (entry.value != playerId) continue;
    if (before[entry.key] == playerId) continue;
    newly.add(entry.key);
  }
  newly.sort();
  return newly;
}

WorkOrderPayoffSnapshot _townSnapshot(int? level) {
  if (level == null) return const WorkOrderPayoffSnapshot();
  final kind = switch (level) {
    <= 1 => WorkOrderPayoffKind.workshopsStart,
    2 => WorkOrderPayoffKind.workshopsPause,
    _ => WorkOrderPayoffKind.workshopsResume,
  };
  return WorkOrderPayoffSnapshot(payoffKind: kind, payoffLevel: level);
}

WorkOrderPayoffSnapshot _fortSnapshot(int? level) {
  if (level == null) return const WorkOrderPayoffSnapshot();
  final kind = switch (level) {
    0 => WorkOrderPayoffKind.fortOpenField,
    1 => WorkOrderPayoffKind.fortWood,
    2 => WorkOrderPayoffKind.fortStone,
    _ => WorkOrderPayoffKind.fortModern,
  };
  return WorkOrderPayoffSnapshot(payoffKind: kind, payoffLevel: level);
}

WorkOrderPayoffSnapshot _purchaseSnapshot(String? resourceId) {
  if (resourceId == null || resourceId.isEmpty) {
    return const WorkOrderPayoffSnapshot(
      payoffKind: WorkOrderPayoffKind.purchaseTradeable,
    );
  }
  final riches = richesCommodityIds.contains(resourceId);
  return WorkOrderPayoffSnapshot(
    payoffKind: riches
        ? WorkOrderPayoffKind.purchaseRiches
        : WorkOrderPayoffKind.purchaseTradeable,
    payoffCommodityId: resourceId,
  );
}
