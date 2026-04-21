part of 'orders_application.dart';

void _runWorkPhase(
  _BuildWorkState state,
  void Function(_BuildWorkState, Unit, String) applyExploreCompletion,
  void Function(
    _BuildWorkState,
    Unit,
    CurrentWork,
    List<Province> Function(),
    void Function(List<Province>),
  )
  applyCompletedWorkTarget,
) {
  final workOrders = state.workOrders;
  final tileState = state.work.tileState;
  final oldUnitsById = state.work.oldUnitsById;
  final newUnitsById = state.work.newUnitsById;
  final purchasedTilesByTileKey = state.work.purchasedTilesByTileKey;

  for (final player in state.game.players) {
    var stockpile = player.stockpile;
    var workers = player.workerPool;
    var treasury = player.treasury;

    Unit? lookupUnit(String unitId) =>
        oldUnitsById[unitId] ?? newUnitsById[unitId];

    void updateUnit(String unitId, Unit updated) {
      if (oldUnitsById.containsKey(unitId)) {
        oldUnitsById[unitId] = updated;
      } else {
        newUnitsById[unitId] = updated;
      }
    }

    void completeInstantCivilianOrder(Unit unit, String targetTileKey) {
      updateUnit(
        unit.id,
        unit.copyWith(
          status: UnitStatus.idle,
          tileKey: targetTileKey,
          clearOriginTileKey: true,
          clearAssignedTileKey: true,
          clearCurrentWork: true,
        ),
      );
    }

    String regionForUnit(String unitId) =>
        oldUnitsById.containsKey(unitId) ? kRegionOldWorld : kRegionNewWorld;

    Province? provinceById(String id) =>
        state.game.worldState.tryGetProvince(id);

    bool canAffordMaterialCost(WorkOrderCost cost) {
      for (final e in cost.entries) {
        if (stockpile.quantityOf(e.key) < e.value) return false;
      }
      return true;
    }

    void deductMaterialCost(WorkOrderCost cost) {
      for (final e in cost.entries) {
        stockpile = stockpile.applyDelta(e.key, -e.value);
      }
    }

    for (final order in workOrders[player.id] ?? const []) {
      final u = lookupUnit(order.unitId);
      if (u == null) continue;
      final targetTileKey = order.targetTileKey;
      final hasValidTarget = targetTileKey.isNotEmpty;

      // Configuration for standard work order targets that use material cost.
      // Reduces duplication in WorkOrder application by centralizing validation,
      // cost computation, and unit update logic.
      // Special targets (purchase_land, prospect, explore, steal_tech, counter_spy)
      // are handled separately due to their unique logic.
      ({
        String target,
        bool Function(String) allowedForUnitType,
        WorkOrderCost? Function() costFn,
        int Function() totalTurnsFn,
      })
      workTargetConfig(String target) {
        switch (target) {
          case kWorkTargetBuildImprovement:
            return (
              target: target,
              allowedForUnitType: (t) =>
                  isWorkOrderTargetAllowedForUnitType(t, target),
              costFn: () => workOrderMaterialCost(
                target,
                improvementLevel: tileState.improvementLevel(targetTileKey),
              ),
              totalTurnsFn: () => totalTurnsForWork(
                target,
                improvementLevel: tileState.improvementLevel(targetTileKey),
              ),
            );
          case kWorkTargetBuildRoad:
            return (
              target: target,
              allowedForUnitType: (t) =>
                  isWorkOrderTargetAllowedForUnitType(t, target),
              costFn: () => workOrderMaterialCost(target),
              totalTurnsFn: () => totalTurnsForWork(target),
            );
          case kWorkTargetBuildPort:
            return (
              target: target,
              allowedForUnitType: (t) =>
                  isWorkOrderTargetAllowedForUnitType(t, target),
              costFn: () => workOrderMaterialCost(target),
              totalTurnsFn: () => totalTurnsForWork(target),
            );
          case kWorkTargetBuildFort:
            return (
              target: target,
              allowedForUnitType: (t) =>
                  isWorkOrderTargetAllowedForUnitType(t, target),
              costFn: () {
                final prov = provinceById(u.locationProvinceId);
                final fortLevel = prov?.fortLevel ?? 0;
                return workOrderMaterialCost(target, fortLevel: fortLevel);
              },
              totalTurnsFn: () {
                final prov = provinceById(u.locationProvinceId);
                final fortLevel = prov?.fortLevel ?? 0;
                return totalTurnsForWork(target, fortLevel: fortLevel);
              },
            );
          case kWorkTargetBuildRail:
            return (
              target: target,
              allowedForUnitType: (t) =>
                  isWorkOrderTargetAllowedForUnitType(t, target),
              costFn: () => workOrderMaterialCost(target),
              totalTurnsFn: () => totalTurnsForWork(target),
            );
          case kWorkTargetUpgradeTown:
            return (
              target: target,
              allowedForUnitType: (t) =>
                  isWorkOrderTargetAllowedForUnitType(t, target),
              costFn: () => workOrderMaterialCost(target),
              totalTurnsFn: () => totalTurnsForWork(target),
            );
          default:
            // Fall through to individual handling for non-standard targets
            return (
              target: target,
              allowedForUnitType: (_) => false,
              costFn: () => null,
              totalTurnsFn: () => 1,
            );
        }
      }

      // Applies a standard work order using the config dispatch.
      // Returns true if the order was applied, false otherwise.
      bool applyStandardWorkOrder(String orderTarget) {
        if (u.currentWork != null) return false;
        if (!hasValidTarget) return false;

        final config = workTargetConfig(orderTarget);
        if (!config.allowedForUnitType(u.type)) return false;

        final cost = config.costFn();
        if (cost == null) return false;
        if (!canAffordMaterialCost(cost)) return false;

        deductMaterialCost(cost);
        final totalTurns = config.totalTurnsFn();

        _log.d(
          'work order accepted and assigned unit=${order.unitId} target=$orderTarget targetTileKey=$targetTileKey totalTurns=$totalTurns',
        );
        updateUnit(
          order.unitId,
          u.copyWith(
            status: UnitStatus.working,
            tileKey: targetTileKey,
            originTileKey: u.originTileKey ?? u.tileKey,
            assignedTileKey: targetTileKey,
            currentWork: CurrentWork(
              workTarget: orderTarget,
              tileKey: targetTileKey,
              totalTurns: totalTurns,
              remainingTurns: totalTurns,
            ),
          ),
        );
        return true;
      }

      if (order.target == kWorkTargetPurchaseLand &&
          isWorkOrderTargetAllowedForUnitType(
            u.type,
            kWorkTargetPurchaseLand,
          ) &&
          u.currentWork == null &&
          hasValidTarget) {
        // SPEC/game/diplomacy.md (GP–Minor/Tribe Rules): purchase_land requires an Embassy
        // with the Minor/Tribe and the buyer must not be at war with that faction.
        final resourceId =
            state.game.worldState.resourceByTileKey[targetTileKey];
        if (resourceId != null) {
          final provinceId =
              Unit.provinceIdFromTileKey(targetTileKey) ?? u.locationProvinceId;
          final province = provinceById(provinceId);
          final ownerId = province?.ownerId;
          if (ownerId == null) {
            continue;
          }

          final hasEmbassy = state.game.overtureStates.any(
            (o) => o.gpId == player.id && o.targetId == ownerId && o.hasEmbassy,
          );
          if (!hasEmbassy) {
            continue;
          }

          final atWar = state.game.diplomacyRelations.any((rel) {
            final ids = {rel.factionId1, rel.factionId2};
            return ids.contains(player.id) &&
                ids.contains(ownerId) &&
                rel.atWar;
          });
          if (atWar) {
            continue;
          }

          final cost = purchaseLandCost(resourceId);
          if (treasury >= cost) {
            // First purchaser wins; tile can only be owned by one GP. SPEC/civilian-units.md.
            if (!purchasedTilesByTileKey.containsKey(targetTileKey)) {
              treasury -= cost;
              purchasedTilesByTileKey[targetTileKey] = player.id;
              completeInstantCivilianOrder(u, targetTileKey);
            }
          }
        }
        continue;
      }

      if (order.target == kWorkTargetStealTech &&
          isWorkOrderTargetAllowedForUnitType(u.type, kWorkTargetStealTech) &&
          u.currentWork == null &&
          hasValidTarget) {
        final totalTurns = totalTurnsForWork(kWorkTargetStealTech);
        _log.d(
          'work order accepted and assigned unit=${order.unitId} target=steal_tech targetTileKey=$targetTileKey totalTurns=$totalTurns',
        );
        updateUnit(
          order.unitId,
          u.copyWith(
            status: UnitStatus.working,
            tileKey: targetTileKey,
            originTileKey: u.originTileKey ?? u.tileKey,
            assignedTileKey: targetTileKey,
            currentWork: CurrentWork(
              workTarget: kWorkTargetStealTech,
              tileKey: targetTileKey,
              totalTurns: totalTurns,
              remainingTurns: totalTurns,
            ),
          ),
        );
        continue;
      }

      if (order.target == kWorkTargetCounterSpy &&
          isWorkOrderTargetAllowedForUnitType(u.type, kWorkTargetCounterSpy) &&
          u.currentWork == null &&
          hasValidTarget) {
        final totalTurns = totalTurnsForWork(kWorkTargetCounterSpy);
        _log.d(
          'work order accepted and assigned unit=${order.unitId} target=counter_spy targetTileKey=$targetTileKey totalTurns=$totalTurns',
        );
        updateUnit(
          order.unitId,
          u.copyWith(
            status: UnitStatus.working,
            tileKey: targetTileKey,
            originTileKey: u.originTileKey ?? u.tileKey,
            assignedTileKey: targetTileKey,
            currentWork: CurrentWork(
              workTarget: kWorkTargetCounterSpy,
              tileKey: targetTileKey,
              totalTurns: totalTurns,
              remainingTurns: 1,
            ),
          ),
        );
        continue;
      }

      if (order.target == kWorkTargetProspect &&
          hasValidTarget &&
          u.currentWork == null &&
          isExplorerUnit(u.type) &&
          isMineralEligibleTile(
            state.game,
            state.tileMapByRegion,
            targetTileKey,
          )) {
        final existing =
            state.game.worldState.playerProspectedTiles[player.id] ?? const {};
        final newProspected = Set<String>.from(existing)..add(targetTileKey);
        state.game = state.game.copyWith(
          worldState: state.game.worldState.copyWith(
            playerProspectedTiles: {
              ...state.game.worldState.playerProspectedTiles,
              player.id: newProspected,
            },
          ),
        );
        completeInstantCivilianOrder(u, targetTileKey);
      }
      if (order.target == kWorkTargetBuildImprovement) {
        if (applyStandardWorkOrder(kWorkTargetBuildImprovement)) continue;
      }
      if (order.target == kWorkTargetExplore &&
          isExplorerUnit(u.type) &&
          u.currentWork == null &&
          hasValidTarget) {
        final regionId = regionForUnit(order.unitId);
        final provinceId =
            Unit.provinceIdFromTileKey(targetTileKey) ?? u.locationProvinceId;
        final byProvince =
            state.game.worldState.tileKeysByRegionAndProvince[regionId];
        final tilesInP = byProvince?[provinceId]?.length ?? 0;
        if (tilesInP > 0 && byProvince != null && byProvince.isNotEmpty) {
          var maxTiles = 0;
          for (final list in byProvince.values) {
            if (list.length > maxTiles) maxTiles = list.length;
          }
          if (maxTiles < 1) maxTiles = 1;
          final totalTurns = (3 * tilesInP / maxTiles).ceil().clamp(1, 999);
          _log.d(
            'work order accepted and assigned unit=${order.unitId} target=explore targetTileKey=$targetTileKey totalTurns=$totalTurns',
          );
          updateUnit(
            order.unitId,
            u.copyWith(
              status: UnitStatus.working,
              tileKey: targetTileKey,
              originTileKey: u.originTileKey ?? u.tileKey,
              assignedTileKey: targetTileKey,
              currentWork: CurrentWork(
                workTarget: kWorkTargetExplore,
                tileKey: targetTileKey,
                totalTurns: totalTurns,
                remainingTurns: totalTurns,
              ),
            ),
          );
          continue;
        }
      }
      final workTarget = order.target;
      if (workTarget == kWorkTargetBuildRoad) {
        if (applyStandardWorkOrder(kWorkTargetBuildRoad)) continue;
      }
      if (workTarget == kWorkTargetBuildPort) {
        if (applyStandardWorkOrder(kWorkTargetBuildPort)) continue;
      }
      if (workTarget == kWorkTargetBuildFort) {
        final prov = provinceById(u.locationProvinceId);
        final fortLevel = prov?.fortLevel ?? 0;
        if (fortLevel == 1 &&
            player.techUnlocked?[kTechIdMineEngineering] != true) {
          _log.d(
            'build_fort skipped - Mine Engineering required for fort level 2',
          );
          continue;
        }
        if (fortLevel == 2 &&
            player.techUnlocked?[kTechIdModernForts] != true) {
          _log.d('build_fort skipped - Modern Forts required for fort level 3');
          continue;
        }
        if (applyStandardWorkOrder(kWorkTargetBuildFort)) continue;
      }
      if (workTarget == kWorkTargetBuildRail) {
        final terrain = terrainTypeForTileKey(
          state.tileMapByRegion,
          targetTileKey,
        );
        final railReason = rejectionReasonForBuildRailOrder(
          techUnlocked: player.techUnlocked,
          roadLevel: tileState.roadLevel(targetTileKey),
          terrain: terrain,
        );
        if (railReason != null) {
          _log.d('build_rail skipped - $railReason');
          continue;
        }
        if (applyStandardWorkOrder(kWorkTargetBuildRail)) continue;
      }
      if (workTarget == kWorkTargetUpgradeTown) {
        if (applyStandardWorkOrder(kWorkTargetUpgradeTown)) continue;
      }
    }

    state.work.updatedPlayers.add(
      player.copyWith(
        stockpile: stockpile,
        workerPool: workers,
        treasury: treasury,
      ),
    );
  }
}
