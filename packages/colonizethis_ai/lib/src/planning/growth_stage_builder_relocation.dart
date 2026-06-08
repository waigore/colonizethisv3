// Growth-stage Builder relocation to fabric-feedstock provinces.
// SPEC/ai/growth-stage-planner.md § Builder relocation.

import 'package:colonizethis_logic/order_suggestion_api.dart';

import 'growth_stage.dart';
import 'growth_stage_work_priorities.dart';
import 'planning_imports.dart';

const Set<String> _kFabricFeedstockResourceIds = {'wool', 'cotton'};

/// Owned province ids (ascending) that host at least one unimproved fabric
/// feedstock tile for [playerId].
List<String> ownedFabricFeedstockProvinceIdsSorted(
  Game game,
  String playerId, {
  Set<String> fabricFeedstockResourceIds = _kFabricFeedstockResourceIds,
}) {
  if (fabricFeedstockResourceIds.isEmpty) return const <String>[];
  final ws = game.worldState;
  final ownerByProvince = getProvinceOwnerMap(game);
  final provinceIds = <String>{};
  for (final entry in ws.resourceByTileKey.entries) {
    if (!fabricFeedstockResourceIds.contains(entry.value)) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    if (ownerByProvince[provinceId] != playerId) continue;
    if (ws.tileState.improvementLevel(entry.key) < 1) {
      provinceIds.add(provinceId);
    }
  }
  final sorted = provinceIds.toList()..sort();
  return List<String>.unmodifiable(sorted);
}

/// Idle Builder unit ids the growth-stage planner keeps under its **own**
/// relocation authority while [playerId] is in a feedstock (bootstrap /
/// infrastructure) stage, so the generic weighted move planner
/// (`runMovePlanner`) does not relocate them across owned provinces before they
/// settle to improve a `wool`/`cotton`/`timber`/`iron`/`coal` tile
/// (Refs #3371 AC14 — Builder anti-thrash).
///
/// Without this reservation the generic move planner picks one idle unit per
/// turn at weighted random and, scoring own-territory destinations at 1.0,
/// repeatedly shuffles bootstrap Builders between owned provinces. Combined
/// with the growth-stage relocation [MoveOrder] (which pulls a Builder toward a
/// fabric-feedstock province), the two planners ping-pong the same Builders so
/// they never stay put long enough for `selectFullAiCivilianWorkOrders` to
/// assign the feedstock `build_improvement` — the seed-42 gp3 fabric chain
/// never starts.
///
/// Returns the idle (`currentWork == null`) Builders owned by [playerId] when a
/// feedstock stage is active (the [growthStageFeedstockPreference] requests
/// fabric or infrastructure feedstock). Returns the empty set when the flag is
/// off or no feedstock stage is active, so the flag-off default and mature-GP
/// behaviour are unchanged. Pure and deterministic over `(game, view)`.
Set<String> growthStageReservedBuilderUnitIds({
  required Game game,
  required PlayerView view,
  required String playerId,
  bool growthStagePlannerEnabled = kGrowthStagePlannerEnabled,
}) {
  if (!growthStagePlannerEnabled) return const <String>{};
  final stage = GrowthStage.compute(game, playerId);
  final preference = growthStageFeedstockPreference(
    game: game,
    playerId: playerId,
    stage: stage,
    growthStagePlannerEnabled: growthStagePlannerEnabled,
  );
  if (preference.fabricFeedstockResourceIds.isEmpty &&
      preference.infraFeedstockResourceIds.isEmpty) {
    return const <String>{};
  }
  final reserved = <String>{};
  for (final unit in view.ownUnits) {
    if (unit.type != kUnitTypeBuilder) continue;
    if (unit.currentWork != null) continue;
    reserved.add(unit.id);
  }
  return reserved;
}

bool _builderProvinceHostsUnimprovedFabricFeedstock({
  required Game game,
  required String playerId,
  required String provinceId,
  required Set<String> fabricFeedstockResourceIds,
}) {
  return ownedFabricFeedstockProvinceIdsSorted(
        game,
        playerId,
        fabricFeedstockResourceIds: fabricFeedstockResourceIds,
      ).contains(provinceId);
}

bool _unitHasPendingDraftOrder({
  required Orders orders,
  required String playerId,
  required String unitId,
}) {
  for (final m in orders.moveOrdersByPlayerId[playerId] ?? const []) {
    if (m.unitId == unitId) return true;
  }
  for (final w in orders.workOrdersByPlayerId[playerId] ?? const []) {
    if (w.unitId == unitId) return true;
  }
  return false;
}

/// When the growth-stage planner needs fabric feedstock but every idle Builder
/// sits in a province without an unimproved `wool`/`cotton` tile, returns one
/// validated [MoveOrder] routing the lowest-id eligible Builder to the
/// lowest-id owned fabric-feedstock province (Refs #3371 AC7).
MoveOrder? suggestGrowthStageBuilderFeedstockRelocation({
  required Game game,
  required PlayerView view,
  required MapTopology topology,
  required Orders currentOrders,
  required OrderSuggestionAPI suggestionAPI,
  required GrowthStage stage,
  required GrowthStageFeedstockPreference feedstockPreference,
  bool growthStagePlannerEnabled = kGrowthStagePlannerEnabled,
}) {
  if (!growthStagePlannerEnabled) return null;
  if (feedstockPreference.fabricFeedstockResourceIds.isEmpty) return null;

  final playerId = view.playerId;
  final fabricIds = feedstockPreference.fabricFeedstockResourceIds;
  final feedstockProvinces = ownedFabricFeedstockProvinceIdsSorted(
    game,
    playerId,
    fabricFeedstockResourceIds: fabricIds,
  );
  if (feedstockProvinces.isEmpty) return null;

  final idleBuilders = view.ownUnits
      .where(
        (u) =>
            u.type == kUnitTypeBuilder &&
            u.status == UnitStatus.idle &&
            u.currentWork == null,
      )
      .toList()
    ..sort((a, b) => a.id.compareTo(b.id));

  Unit? builderToMove;
  for (final builder in idleBuilders) {
    if (_unitHasPendingDraftOrder(
      orders: currentOrders,
      playerId: playerId,
      unitId: builder.id,
    )) {
      continue;
    }
    final provinceId = builder.locationProvinceId;
    if (!_builderProvinceHostsUnimprovedFabricFeedstock(
      game: game,
      playerId: playerId,
      provinceId: provinceId,
      fabricFeedstockResourceIds: fabricIds,
    )) {
      builderToMove = builder;
      break;
    }
  }
  if (builderToMove == null) return null;

  final moveCandidates = suggestionAPI.suggestMoveOrders(
    view,
    game,
    topology,
    currentOrders,
  );
  if (moveCandidates.isEmpty) return null;

  final targetProvinceId = feedstockProvinces.firstWhere(
    (p) => p != builderToMove!.locationProvinceId,
    orElse: () => feedstockProvinces.first,
  );

  final ws = game.worldState;
  final forBuilder = moveCandidates
      .where((m) => m.unitId == builderToMove!.id)
      .where(
        (m) => Unit.provinceIdFromTileKey(m.destinationTileKey) == targetProvinceId,
      )
      .toList();
  if (forBuilder.isEmpty) return null;

  int feedstockTileRank(String tileKey) {
    final resourceId = ws.resourceByTileKey[tileKey];
    if (resourceId != null && fabricIds.contains(resourceId)) return 0;
    return 1;
  }

  forBuilder.sort((a, b) {
    final byFeedstock = feedstockTileRank(
      a.destinationTileKey,
    ).compareTo(feedstockTileRank(b.destinationTileKey));
    if (byFeedstock != 0) return byFeedstock;
    return a.destinationTileKey.compareTo(b.destinationTileKey);
  });
  return forBuilder.first;
}
