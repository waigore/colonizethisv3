import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../diplomacy/diplomacy_relation_lookup.dart';
import '../diplomacy/diplomacy_resolver.dart';
import '../world/movement.dart';
import '../world/naval.dart';
import '../world/province_lookup.dart';
import 'build_rail_work_rules.dart';
import 'order_engine.dart';
import 'order_visibility.dart';
import 'orders_application_helpers.dart';
import 'unit_type_helpers.dart';
import '../world/player_view.dart';
import '../world/unit_lookup.dart';

export 'order_suggestion_helpers.dart';

final _log = logicLogger();

const String _kOrderSuggestionLogPrefix = 'logic/order_suggestion';

/// Suggests candidate move orders that are information-legal (per [PlayerView])
/// and rules-legal (per [OrderEngine]) for [view.playerId].
List<MoveOrder> suggestMoveOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestMoveOrders player=${view.playerId}',
  );
  final playerId = view.playerId;
  final suggestions = <MoveOrder>[];

  // Build a convenience index of current move orders for this player to avoid
  // suggesting duplicate moves for the same unit + destination.
  final existingMoves = <String, Set<String>>{};
  final existingForPlayer =
      currentOrders.moveOrdersByPlayerId[playerId] ?? const [];
  for (final m in existingForPlayer) {
    existingMoves
        .putIfAbsent(m.unitId, () => <String>{})
        .add(m.destinationProvinceId);
  }

  for (final unit in view.ownUnits) {
    final unitRegion = regionIdForUnit(view, unit);
    final fromProvinceId = unit.locationProvinceId;
    final fromLocalId = ProvinceId.localIdFrom(fromProvinceId);

    // Source province cannot be unknown; by definition the unit is in a known province.
    if (!moveSourceVisibilityOk(view, unitRegion, fromProvinceId)) {
      throw StateError(
        'Source province must be visible; unit ${unit.id} has source province $fromProvinceId with unknown visibility',
      );
    }

    // Enumerate neighboring provinces in unit's region (region-scoped adjacency).
    for (final neighborLocalId in neighborProvinceIdsInRegion(
      topology,
      unitRegion,
      fromLocalId,
    )) {
      final destinationProvinceId = ProvinceId.full(
        unitRegion,
        neighborLocalId,
      );

      // Skip duplicates for this unit.
      final already = existingMoves[unit.id];
      if (already != null && already.contains(destinationProvinceId)) continue;

      final destProvince = view.provinceByRegionAndId(
        unitRegion,
        neighborLocalId,
      );
      final destOwnerId = destProvince?.ownerId;

      // Require that the destination province has at least one tile that is
      // known (visibility != unknown). Restrict to unit's region when ids overlap.
      final hasVisibleTileInDest = view.visibilityByTile.entries.any((e) {
        final parts = e.key.split('|');
        if (parts.length != 4) return false;
        return parts[0] == unitRegion &&
            parts[1] == neighborLocalId &&
            e.value != VisibilityLevel.unknown;
      });
      if (!hasVisibleTileInDest) continue;

      // Apply high-level civilian vs territory rules using only information
      // available in PlayerView. Military units may move anywhere that passes
      // validation; civilians are constrained.
      final isMilitary = isMilitaryUnit(unit.type);
      final isExplorer = isExplorerUnit(unit.type);
      final isMerchant = isMerchantUnit(unit.type);

      var allowedByInfo = true;
      if (!isMilitary && destOwnerId != null && destOwnerId != playerId) {
        final isGpOwner = game.players.any((p) => p.id == destOwnerId);
        final isMinorOrTribe =
            game.minorNations.any((m) => m.id == destOwnerId) ||
            game.tribes.any((t) => t.id == destOwnerId);

        if (isGpOwner) {
          // Civilians may not enter other Great Power territory at all.
          allowedByInfo = false;
        } else if (isMinorOrTribe && !(isExplorer || isMerchant)) {
          // Only Explorers/Merchants may enter Minor/Tribe territory.
          allowedByInfo = false;
        }
      }
      if (!allowedByInfo) continue;

      final candidate = MoveOrder(
        unitId: unit.id,
        destinationProvinceId: destinationProvinceId,
      );

      if (_isMoveOrderAccepted(
        game,
        topology,
        playerId,
        currentOrders,
        candidate,
      )) {
        suggestions.add(candidate);
      }
    }
  }

  suggestions.sort((a, b) {
    final unitCmp = a.unitId.compareTo(b.unitId);
    if (unitCmp != 0) return unitCmp;
    return a.destinationProvinceId.compareTo(b.destinationProvinceId);
  });

  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestMoveOrders player=$playerId candidates=${suggestions.length}',
  );
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestMoveOrders full list ${suggestions.map((m) => "${m.unitId}->${m.destinationProvinceId}").toList()}',
  );
  if (suggestions.isEmpty)
    _log.w(
      '$_kOrderSuggestionLogPrefix: suggestMoveOrders no candidates player=$playerId',
    );
  return suggestions;
}

/// Suggests candidate work orders for explorers and civilian workers owned by
/// [view.playerId]. Worker units (Builder, Engineer, Rail Builder): at least
/// one suggestion per (unit, allowed target) when any **player-controlled** tile
/// (owned or purchased) is valid under visibility and the order engine — same
/// scope as work-order validation, not limited to the unit’s current province.
/// Explorers/Spies/Merchants follow type-specific rules. Visibility per
/// SPEC/program/fog-and-exploration-resolution.md.
List<WorkOrder> suggestWorkOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestWorkOrders player=${view.playerId}',
  );
  final playerId = view.playerId;
  final suggestions = <WorkOrder>[];

  // Index existing work orders per unit to avoid suggesting duplicates (by unit + target).
  final existingTargetsByUnit = <String, Set<String>>{};
  final existingForPlayer =
      currentOrders.workOrdersByPlayerId[playerId] ?? const [];
  for (final o in existingForPlayer) {
    existingTargetsByUnit.putIfAbsent(o.unitId, () => <String>{}).add(o.target);
  }

  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;

  // Pre-filter + visibility sort per workTarget; reused across worker units.
  final visibleCandidatesSortedByWorkTarget = <String, List<String>>{};

  final devExclusiveReservedTiles = devExclusiveReservedTileKeysForPlayer(
    game,
    currentOrders,
    playerId,
  );

  for (final unit in view.ownUnits) {
    if (unit.currentWork != null) continue;

    final type = unit.type;
    final isExplorer = isExplorerUnit(type);
    final isWorker = isCivilianWorkerUnit(type);
    final isSpy = isSpyUnit(type);
    final isMerchant = isMerchantUnit(type);
    if (!isExplorer && !isWorker && !isSpy && !isMerchant) continue;

    final regionId = regionIdForUnit(view, unit);
    final provinceId = unit.locationProvinceId;
    final localId = ProvinceId.localIdFrom(provinceId);
    final province = view.provinceByRegionAndId(regionId, provinceId);
    final ownerId = province?.ownerId;
    final tilesInProvince =
        tileKeysByRegion[regionId]?[provinceId] ?? const <String>[];

    _log.d(
      '$_kOrderSuggestionLogPrefix: suggestWorkOrders unit=${unit.id} provinceId=$provinceId provinceName=${province?.displayName} ownerId=$ownerId regionId=$regionId tilesInProvince=${tilesInProvince.length}',
    );

    // Explorers: explore/prospect in their current province only; visibility rules apply.
    if (isExplorer) {
      // Explore: province must be at least revealed, and something left to reveal.
      if (provinceHasAtLeastVisibility(
        view,
        regionId,
        provinceId,
        VisibilityLevel.revealed,
      )) {
        final hasPartiallyHiddenTile = view.visibilityByTile.entries.any((e) {
          final parts = e.key.split('|');
          if (parts.length != 4) return false;
          if (parts[0] != regionId || parts[1] != localId) return false;
          return e.value != VisibilityLevel.fullyVisible;
        });

        if (hasPartiallyHiddenTile) {
          const target = 'explore';
          final existing = existingTargetsByUnit[unit.id];
          if (existing == null || !existing.contains(target)) {
            final targetTileKey = '$regionId|$localId|0|0';
            final candidate = WorkOrder(
              unitId: unit.id,
              target: target,
              targetTileKey: targetTileKey,
            );
            if (_isWorkOrderAccepted(
              game,
              topology,
              playerId,
              currentOrders,
              candidate,
              tileMapByRegion: tileMapByRegion,
            )) {
              suggestions.add(candidate);
            }
          }
        }
      }

      // Prospect: first mineral-eligible, not-yet-prospected tile in province.
      if (provinceHasAtLeastVisibility(
            view,
            regionId,
            provinceId,
            VisibilityLevel.fogged,
          ) &&
          tilesInProvince.isNotEmpty) {
        const prospectTarget = 'prospect';
        final existingProspect = existingTargetsByUnit[unit.id];
        if (existingProspect == null ||
            !existingProspect.contains(prospectTarget)) {
          final prospected =
              game.worldState.playerProspectedTiles[playerId] ??
              const <String>{};
          String? prospectTileKey;
          for (final tk in tilesInProvince) {
            if (prospected.contains(tk)) continue;
            if (!isMineralEligibleTile(game, null, tk)) continue;
            prospectTileKey = tk;
            break;
          }
          if (prospectTileKey != null) {
            final candidate = WorkOrder(
              unitId: unit.id,
              target: prospectTarget,
              targetTileKey: prospectTileKey,
            );
            if (_isWorkOrderAccepted(
              game,
              topology,
              playerId,
              currentOrders,
              candidate,
              tileMapByRegion: tileMapByRegion,
            )) {
              suggestions.add(candidate);
            }
          }
        }
      }
      continue;
    }

    if (isWorker) {
      final allowedTargets = workOrderTargetsByUnitType[type];
      if (allowedTargets != null) {
        for (final target in allowedTargets) {
          final existing = existingTargetsByUnit[unit.id];
          if (existing != null && existing.contains(target)) continue;

          final sortedVisible = visibleCandidatesSortedByWorkTarget.putIfAbsent(
            target,
            () {
              final raw = _rawCandidateTilesForWorkTarget(
                game: game,
                playerId: playerId,
                workTarget: target,
                tileMapByRegion: tileMapByRegion,
              );
              return _sortedVisibleWorkTargetCandidates(view, raw);
            },
          );

          WorkOrder? accepted;
          for (final tk in sortedVisible) {
            if (isDevExclusiveWorkTarget(target) &&
                devExclusiveReservedTiles.contains(tk)) {
              continue;
            }
            final candidate = WorkOrder(
              unitId: unit.id,
              target: target,
              targetTileKey: tk,
            );
            if (_isWorkOrderAccepted(
              game,
              topology,
              playerId,
              currentOrders,
              candidate,
              tileMapByRegion: tileMapByRegion,
            )) {
              accepted = candidate;
              break;
            }
          }
          if (accepted != null) {
            _log.d(
              '$_kOrderSuggestionLogPrefix: suggestWorkOrders candidate=$accepted',
            );
            suggestions.add(accepted);
          } else {
            _log.d(
              '$_kOrderSuggestionLogPrefix: suggestWorkOrders rejected target=$target unit=${unit.id} (no valid tile)',
            );
          }
        }
      }
    }

    if (isSpy && tilesInProvince.isNotEmpty) {
      final allowedTargets = workOrderTargetsByUnitType[type];
      if (allowedTargets != null) {
        if (allowedTargets.contains('counter_spy') && ownerId == playerId) {
          final targetTileKey = tilesInProvince.first;
          final candidate = WorkOrder(
            unitId: unit.id,
            target: 'counter_spy',
            targetTileKey: targetTileKey,
          );
          if (_isWorkOrderAccepted(
            game,
            topology,
            playerId,
            currentOrders,
            candidate,
            tileMapByRegion: tileMapByRegion,
          )) {
            suggestions.add(candidate);
          }
        }
        if (allowedTargets.contains('steal_tech')) {
          for (final other in game.players) {
            if (other.id == playerId || other.capitalProvinceId == null)
              continue;
            final capProvinceId = other.capitalProvinceId!;
            final capRegionId = ProvinceId.regionIdFrom(capProvinceId);
            final capTiles =
                tileKeysByRegion[capRegionId]?[capProvinceId] ?? const [];
            if (capTiles.isEmpty) continue;
            final candidate = WorkOrder(
              unitId: unit.id,
              target: 'steal_tech',
              targetTileKey: capTiles.first,
            );
            if (_isWorkOrderAccepted(
              game,
              topology,
              playerId,
              currentOrders,
              candidate,
              tileMapByRegion: tileMapByRegion,
            )) {
              suggestions.add(candidate);
              break;
            }
          }
        }
      }
    }

    if (isMerchant) {
      final allowedTargets = workOrderTargetsByUnitType[type];
      if (allowedTargets != null && allowedTargets.contains('purchase_land')) {
        final resourceByTile = game.worldState.resourceByTileKey;
        final playerIds = game.players.map((p) => p.id).toSet();
        for (final p in allProvinces(game.worldState)) {
          if (p.ownerId == null || playerIds.contains(p.ownerId!)) continue;
          final regionId = p.regionId;
          final tiles = tileKeysByRegion[regionId]?[p.id] ?? const [];
          for (final tk in tiles) {
            if (resourceByTile[tk] == null) continue;
            if (devExclusiveReservedTiles.contains(tk)) continue;
            final candidate = WorkOrder(
              unitId: unit.id,
              target: 'purchase_land',
              targetTileKey: tk,
            );
            if (_isWorkOrderAccepted(
              game,
              topology,
              playerId,
              currentOrders,
              candidate,
              tileMapByRegion: tileMapByRegion,
            )) {
              suggestions.add(candidate);
              break;
            }
          }
        }
      }
    }
  }

  suggestions.sort((a, b) {
    final unitCmp = a.unitId.compareTo(b.unitId);
    if (unitCmp != 0) return unitCmp;
    final targetCmp = a.target.compareTo(b.target);
    if (targetCmp != 0) return targetCmp;
    return a.targetTileKey.compareTo(b.targetTileKey);
  });

  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestWorkOrders player=$playerId candidates=${suggestions.length}',
  );
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestWorkOrders full list ${suggestions.map((o) => "${o.unitId}:${o.target}").toList()}',
  );
  if (suggestions.isEmpty)
    _log.w(
      '$_kOrderSuggestionLogPrefix: suggestWorkOrders no candidates player=$playerId',
    );
  return suggestions;
}

/// Suggests build-unit orders that are affordable and valid for [view.playerId].
List<BuildUnitOrder> suggestBuildOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestBuildOrders player=${view.playerId}',
  );
  final playerId = view.playerId;
  final player = view.player;
  final suggestions = <BuildUnitOrder>[];

  final capitalId = player.capitalProvinceId;
  if (capitalId == null) {
    _log.w(
      '$_kOrderSuggestionLogPrefix: suggestBuildOrders no capital player=$playerId',
    );
    return suggestions;
  }

  // Military (regiment) builds.
  for (final entry in RegimentEconomyCatalog.byId.entries) {
    final unitType = entry.key;
    final candidate = BuildUnitOrder(
      unitType: unitType,
      isMilitary:
          buildUnitCategoryForUnitType(unitType) == BuildUnitCategory.military,
      spawnProvinceId: capitalId,
    );

    if (_isBuildOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
    )) {
      suggestions.add(candidate);
    }
  }

  // Naval (ship) builds. SPEC/program/order-suggestions.md.
  for (final entry in ShipEconomyCatalog.byId.entries) {
    final unitType = entry.key;
    final candidate = BuildUnitOrder(
      unitType: unitType,
      isMilitary: false,
      spawnProvinceId: capitalId,
    );

    if (_isBuildOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
    )) {
      suggestions.add(candidate);
    }
  }

  suggestions.sort((a, b) => a.unitType.compareTo(b.unitType));

  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestBuildOrders player=$playerId candidates=${suggestions.length}',
  );
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestBuildOrders full list ${suggestions.map((o) => o.unitType).toList()}',
  );
  if (suggestions.isEmpty)
    _log.w(
      '$_kOrderSuggestionLogPrefix: suggestBuildOrders no candidates player=$playerId',
    );
  return suggestions;
}

/// Suggests research orders for [view.playerId] based on unlocked tech and
/// the public tech catalog. At most one order per slot is suggested; it is up
/// to the AI to select which slot to fund.
List<ResearchOrder> suggestResearchOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestResearchOrders player=${view.playerId}',
  );
  final playerId = view.playerId;
  final player = view.player;
  final suggestions = <ResearchOrder>[];

  final unlocked = player.techUnlocked ?? const {};
  final existingBySlot = <int, ResearchOrder>{};
  final existingForPlayer =
      currentOrders.researchOrdersByPlayerId[playerId] ?? const [];
  for (final o in existingForPlayer) {
    existingBySlot[o.slotIndex] = o;
  }

  // Include discovery gate: only techs researchable with current visibility/prospection. SPEC/game/tech-tree.md.
  final researchableIds = researchableTechIds(
    unlocked,
    hasDiscoveredResource: (r) =>
        hasRevealedResourceForPlayer(game, playerId, r),
  );
  final candidates = <TechDefinition>[];
  for (final id in researchableIds) {
    final tech = techCatalog[id];
    if (tech != null) candidates.add(tech);
  }

  if (candidates.isEmpty) return suggestions;

  candidates.sort((a, b) {
    final eraCmp = a.era.compareTo(b.era);
    if (eraCmp != 0) return eraCmp;
    final costCmp = a.cost.compareTo(b.cost);
    if (costCmp != 0) return costCmp;
    return a.id.compareTo(b.id);
  });

  // For simplicity, suggest the cheapest valid tech for slot 0 if that slot
  // does not already have a research assignment.
  const slotIndex = 0;
  if (!existingBySlot.containsKey(slotIndex)) {
    final tech = candidates.first;
    suggestions.add(
      ResearchOrder(
        slotIndex: slotIndex,
        techId: tech.id,
        funding: ResearchFundingLevel.medium,
      ),
    );
  }

  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestResearchOrders player=$playerId candidates=${suggestions.length}',
  );
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestResearchOrders full list ${suggestions.map((o) => "slot${o.slotIndex}:${o.techId}").toList()}',
  );
  return suggestions;
}

bool _isMoveOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  MoveOrder candidate,
) {
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addMoveOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
  );
  return result.isAccepted;
}

bool _isWorkOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  WorkOrder candidate, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addWorkOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
    tileMapByRegion: tileMapByRegion,
  );
  return result.isAccepted;
}

/// Returns the set of tile keys that are valid targets for a work order
/// (unitId, workTarget) given [currentOrders]. Used by the app to highlight
/// valid tiles when the player is assigning work. SPEC/ui/civilian-units-panel.md.
Set<String> getValidWorkOrderTileKeys(
  Game game,
  MapTopology topology,
  String playerId,
  String unitId,
  String workTarget,
  Orders currentOrders, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final unit = allUnitsFromWorld(
    game.worldState,
  ).where((u) => u.id == unitId).firstOrNull;
  if (unit == null || unit.ownerId != playerId) return {};
  if (unit.currentWork != null) return {};
  if (!isWorkOrderTargetAllowedForUnitType(unit.type, workTarget)) return {};

  final reservedForPicker = devExclusiveReservedTileKeysForPlayer(
    game,
    currentOrders,
    playerId,
    ignorePendingWorkOrderUnitId: unitId,
  );

  final raw = _rawCandidateTilesForWorkTarget(
    game: game,
    playerId: playerId,
    workTarget: workTarget,
    tileMapByRegion: tileMapByRegion,
  );
  final valid = <String>{};
  for (final tileKey in raw) {
    if (isDevExclusiveWorkTarget(workTarget) &&
        reservedForPicker.contains(tileKey)) {
      continue;
    }
    final candidate = WorkOrder(
      unitId: unitId,
      target: workTarget,
      targetTileKey: tileKey,
    );
    if (_isWorkOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
      tileMapByRegion: tileMapByRegion,
    )) {
      valid.add(tileKey);
    }
  }
  _log.d(
    '$_kOrderSuggestionLogPrefix: getValidWorkOrderTileKeys unit=$unitId target=$workTarget count=${valid.length}',
  );
  return valid;
}

/// Returns the set of tile keys that are valid targets for a work order,
/// filtering by work-target-specific criteria and visibility BEFORE calling
/// the order engine for efficiency.
///
/// Spec: SPEC/program/order-suggestions.md § Pre-filtering by work target type.
Set<String> getValidWorkOrderTileKeysWithVisibility({
  required Game game,
  required MapTopology topology,
  required PlayerView view,
  required String unitId,
  required String workTarget,
  required Orders currentOrders,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final unit = allUnitsFromWorld(
    game.worldState,
  ).where((u) => u.id == unitId).firstOrNull;
  if (unit == null || unit.ownerId != view.playerId) {
    _log.d(
      '$_kOrderSuggestionLogPrefix: getValidWorkOrderTileKeysWithVisibility unit not found or not owned by player',
    );
    return {};
  }
  if (unit.currentWork != null) {
    _log.d(
      '$_kOrderSuggestionLogPrefix: getValidWorkOrderTileKeysWithVisibility unit has current work',
    );
    return {};
  }
  if (!isWorkOrderTargetAllowedForUnitType(unit.type, workTarget)) {
    _log.d(
      '$_kOrderSuggestionLogPrefix: getValidWorkOrderTileKeysWithVisibility target $workTarget not allowed for unit type ${unit.type}',
    );
    return {};
  }

  _log.d(
    '$_kOrderSuggestionLogPrefix: getValidWorkOrderTileKeysWithVisibility unit=${unit.id} type=${unit.type} workTarget=$workTarget',
  );

  final playerId = view.playerId;

  final reservedForPicker = devExclusiveReservedTileKeysForPlayer(
    game,
    currentOrders,
    playerId,
    ignorePendingWorkOrderUnitId: unitId,
  );

  final raw = _rawCandidateTilesForWorkTarget(
    game: game,
    playerId: playerId,
    workTarget: workTarget,
    tileMapByRegion: tileMapByRegion,
  );
  final sortedVisible = _sortedVisibleWorkTargetCandidates(view, raw);

  _log.d(
    '$_kOrderSuggestionLogPrefix: getValidWorkOrderTileKeysWithVisibility visible sorted count=${sortedVisible.length}',
  );

  final valid = <String>{};
  for (final tileKey in sortedVisible) {
    if (isDevExclusiveWorkTarget(workTarget) &&
        reservedForPicker.contains(tileKey)) {
      continue;
    }
    final candidate = WorkOrder(
      unitId: unitId,
      target: workTarget,
      targetTileKey: tileKey,
    );
    if (_isWorkOrderAccepted(
      game,
      topology,
      playerId,
      currentOrders,
      candidate,
      tileMapByRegion: tileMapByRegion,
    )) {
      valid.add(tileKey);
    }
  }

  _log.d(
    '$_kOrderSuggestionLogPrefix: getValidWorkOrderTileKeysWithVisibility unit=$unitId target=$workTarget count=${valid.length} (filtered from ${sortedVisible.length} visible candidates)',
  );
  return valid;
}

/// Pre-filters tiles based on work-target-specific criteria per SPEC/program/order-suggestions.md.
/// Returns a set of candidate tile keys that pass work-target requirements.
Set<String> _preFilterWorkTargetTiles({
  required Game game,
  required String workTarget,
  required String playerId,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Map<String, String> resourceByTile,
  required Map<String, String> purchasedTiles,
  required Set<String> ownedProvinceIds,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final result = <String>{};

  switch (workTarget) {
    case 'build_improvement':
      // Tiles in owned provinces or purchased tiles, must have resource
      _addCandidateTilesForBuildImprovement(
        tileKeysByRegion: tileKeysByRegion,
        resourceByTile: resourceByTile,
        purchasedTiles: purchasedTiles,
        ownedProvinceIds: ownedProvinceIds,
        playerId: playerId,
        result: result,
      );
      break;

    case 'build_road':
      _addCandidateTilesForRoads(
        tileKeysByRegion: tileKeysByRegion,
        purchasedTiles: purchasedTiles,
        ownedProvinceIds: ownedProvinceIds,
        playerId: playerId,
        result: result,
      );
      break;

    case 'build_rail':
      _addCandidateTilesForBuildRail(
        game: game,
        playerId: playerId,
        tileKeysByRegion: tileKeysByRegion,
        purchasedTiles: purchasedTiles,
        ownedProvinceIds: ownedProvinceIds,
        tileMapByRegion: tileMapByRegion,
        result: result,
      );
      break;

    case 'upgrade_town':
    case 'build_fort':
      // Town tiles in owned provinces only
      _addCandidateTilesForTownWork(
        game: game,
        ownedProvinceIds: ownedProvinceIds,
        result: result,
      );
      break;

    case 'build_port':
      // Coastal or river tiles in owned provinces
      _addCandidateTilesForPort(
        game: game,
        ownedProvinceIds: ownedProvinceIds,
        tileKeysByRegion: tileKeysByRegion,
        result: result,
      );
      break;

    case 'counter_spy':
      // Any tile in owned provinces
      _addCandidateTilesForCounterSpy(
        tileKeysByRegion: tileKeysByRegion,
        ownedProvinceIds: ownedProvinceIds,
        result: result,
      );
      break;

    case 'steal_tech':
      // Other GP capital provinces
      _addCandidateTilesForStealTech(
        game: game,
        playerId: playerId,
        result: result,
      );
      break;

    case 'purchase_land':
      // Tiles in Minor/Tribe provinces with resource
      _addCandidateTilesForPurchaseLand(
        game: game,
        tileKeysByRegion: tileKeysByRegion,
        resourceByTile: resourceByTile,
        playerId: playerId,
        result: result,
      );
      break;

    case 'explore':
      for (final regionEntry in tileKeysByRegion.entries) {
        for (final provinceEntry in regionEntry.value.entries) {
          result.addAll(provinceEntry.value);
        }
      }
      break;

    case 'prospect':
      _addCandidateTilesForProspect(
        game: game,
        playerId: playerId,
        tileKeysByRegion: tileKeysByRegion,
        tileMapByRegion: tileMapByRegion,
        result: result,
      );
      break;

    default:
      for (final regionEntry in tileKeysByRegion.entries) {
        for (final provinceEntry in regionEntry.value.entries) {
          result.addAll(provinceEntry.value);
        }
      }
      break;
  }

  return result;
}

Set<String> _rawCandidateTilesForWorkTarget({
  required Game game,
  required String playerId,
  required String workTarget,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final world = game.worldState;
  final ownedProvinceIds = <String>{};
  for (final p in allProvinces(world)) {
    if (p.ownerId == playerId) {
      ownedProvinceIds.add(p.id);
    }
  }
  return _preFilterWorkTargetTiles(
    game: game,
    workTarget: workTarget,
    playerId: playerId,
    tileKeysByRegion: world.tileKeysByRegionAndProvince,
    resourceByTile: world.resourceByTileKey,
    purchasedTiles: world.purchasedTilesByTileKey,
    ownedProvinceIds: ownedProvinceIds,
    tileMapByRegion: tileMapByRegion,
  );
}

List<String> _sortedVisibleWorkTargetCandidates(
  PlayerView view,
  Set<String> rawCandidates,
) {
  final list = <String>[];
  for (final tk in rawCandidates) {
    final visibility = view.visibilityForTile(tk);
    if (visibility == VisibilityLevel.fullyVisible ||
        visibility == VisibilityLevel.fogged) {
      list.add(tk);
    }
  }
  list.sort();
  return list;
}

/// Adds candidate tiles for build_improvement: owned or purchased tiles with resource.
void _addCandidateTilesForBuildImprovement({
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Map<String, String> resourceByTile,
  required Map<String, String> purchasedTiles,
  required Set<String> ownedProvinceIds,
  required String playerId,
  required Set<String> result,
}) {
  for (final regionEntry in tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      final provinceId = provinceEntry.key;
      // Skip sea zones (provinceId is not prefixed)
      if (!ProvinceId.isPrefixed(provinceId)) continue;

      final isOwnedProvince = ownedProvinceIds.contains(provinceId);
      for (final tileKey in provinceEntry.value) {
        // Check if tile is controlled by player (owned province or purchased)
        final isPurchased = purchasedTiles[tileKey] == playerId;
        if (!isOwnedProvince && !isPurchased) continue;

        // Check if tile has a resource
        final resourceId = resourceByTile[tileKey];
        if (resourceId == null || resourceId.isEmpty) continue;

        result.add(tileKey);
      }
    }
  }
}

/// Adds candidate tiles for prospect: land provinces only; mineral-eligible;
/// not yet in the player's prospected set. SPEC/program/order-suggestions.md.
void _addCandidateTilesForProspect({
  required Game game,
  required String playerId,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Set<String> result,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final prospected =
      game.worldState.playerProspectedTiles[playerId] ?? const <String>{};
  for (final regionEntry in tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      final provinceId = provinceEntry.key;
      if (!ProvinceId.isPrefixed(provinceId)) continue;

      for (final tileKey in provinceEntry.value) {
        if (prospected.contains(tileKey)) continue;
        if (!isMineralEligibleTile(game, tileMapByRegion, tileKey)) continue;
        result.add(tileKey);
      }
    }
  }
}

/// Adds candidate tiles for `build_rail`: owned or purchased land tiles with
/// road level 1–2, resolvable terrain, and tech that allows rail on that terrain.
/// SPEC/program/order-suggestions.md, SPEC/game/tech-tree-transport.md.
void _addCandidateTilesForBuildRail({
  required Game game,
  required String playerId,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Map<String, String> purchasedTiles,
  required Set<String> ownedProvinceIds,
  required Map<String, TileMapResult>? tileMapByRegion,
  required Set<String> result,
}) {
  final player = game.players.where((p) => p.id == playerId).firstOrNull;
  if (player == null) return;
  final tech = player.techUnlocked;
  final tileState = game.worldState.tileState;
  for (final regionEntry in tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      final provinceId = provinceEntry.key;
      if (!ProvinceId.isPrefixed(provinceId)) continue;
      final isOwnedProvince = ownedProvinceIds.contains(provinceId);
      for (final tileKey in provinceEntry.value) {
        final isPurchased = purchasedTiles[tileKey] == playerId;
        if (!isOwnedProvince && !isPurchased) continue;
        final roadLevel = tileState.roadLevel(tileKey);
        if (roadLevel != 1 && roadLevel != 2) continue;
        final terrain = terrainTypeForTileKey(tileMapByRegion, tileKey);
        if (rejectionReasonForBuildRailOrder(
              techUnlocked: tech,
              roadLevel: roadLevel,
              terrain: terrain,
            ) !=
            null) {
          continue;
        }
        result.add(tileKey);
      }
    }
  }
}

/// Adds candidate tiles for build_road: owned or purchased tiles.
void _addCandidateTilesForRoads({
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Map<String, String> purchasedTiles,
  required Set<String> ownedProvinceIds,
  required String playerId,
  required Set<String> result,
}) {
  for (final regionEntry in tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      final provinceId = provinceEntry.key;
      // Skip sea zones
      if (!ProvinceId.isPrefixed(provinceId)) continue;

      final isOwnedProvince = ownedProvinceIds.contains(provinceId);
      for (final tileKey in provinceEntry.value) {
        final isPurchased = purchasedTiles[tileKey] == playerId;
        if (!isOwnedProvince && !isPurchased) continue;
        result.add(tileKey);
      }
    }
  }
}

/// Adds candidate tiles for upgrade_town/build_fort: town tiles in owned provinces.
void _addCandidateTilesForTownWork({
  required Game game,
  required Set<String> ownedProvinceIds,
  required Set<String> result,
}) {
  for (final province in allProvinces(game.worldState)) {
    if (!ownedProvinceIds.contains(province.id)) continue;
    final townTileKey = province.townTileKey;
    if (townTileKey == null || townTileKey.isEmpty) continue;
    result.add(townTileKey);
  }
}

/// Adds candidate tiles for build_port: coastal/river tiles in owned provinces.
void _addCandidateTilesForPort({
  required Game game,
  required Set<String> ownedProvinceIds,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Set<String> result,
}) {
  // Port tiles must be in owned provinces; further validation checks coastal/river
  for (final regionEntry in tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      final provinceId = provinceEntry.key;
      if (!ProvinceId.isPrefixed(provinceId)) continue;
      if (!ownedProvinceIds.contains(provinceId)) continue;
      result.addAll(provinceEntry.value);
    }
  }
}

/// Adds candidate tiles for counter_spy: any tile in owned provinces.
void _addCandidateTilesForCounterSpy({
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Set<String> ownedProvinceIds,
  required Set<String> result,
}) {
  for (final regionEntry in tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      final provinceId = provinceEntry.key;
      if (!ProvinceId.isPrefixed(provinceId)) continue;
      if (!ownedProvinceIds.contains(provinceId)) continue;
      result.addAll(provinceEntry.value);
    }
  }
}

/// Adds candidate tiles for steal_tech: other GP capital provinces.
void _addCandidateTilesForStealTech({
  required Game game,
  required String playerId,
  required Set<String> result,
}) {
  for (final other in game.players) {
    if (other.id == playerId) continue;
    final capitalProvinceId = other.capitalProvinceId;
    if (capitalProvinceId == null) continue;

    // Find a tile in the capital province
    final regionId = ProvinceId.regionIdFrom(capitalProvinceId);
    final byProvince = game.worldState.tileKeysByRegionAndProvince[regionId];
    final tiles = byProvince?[capitalProvinceId];
    if (tiles != null && tiles.isNotEmpty) {
      result.add(tiles.first);
    }
  }
}

/// Adds candidate tiles for purchase_land: tiles in Minor/Tribe provinces with resource.
void _addCandidateTilesForPurchaseLand({
  required Game game,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Map<String, String> resourceByTile,
  required String playerId,
  required Set<String> result,
}) {
  // Get set of Great Power ids
  final gpIds = game.players.map((p) => p.id).toSet();

  // Get Minor and Tribe ids sets
  final minorIds = game.minorNations.map((m) => m.id).toSet();
  final tribeIds = game.tribes.map((t) => t.id).toSet();

  for (final regionEntry in tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      final provinceId = provinceEntry.key;
      if (!ProvinceId.isPrefixed(provinceId)) continue;

      // Find province owner
      final province = tryGetProvince(game.worldState, provinceId);
      if (province == null) continue;
      final ownerId = province.ownerId;
      if (ownerId == null) continue;

      // Must be Minor or Tribe (not GP, not null)
      if (gpIds.contains(ownerId)) continue;
      if (!minorIds.contains(ownerId) && !tribeIds.contains(ownerId)) continue;

      for (final tileKey in provinceEntry.value) {
        // Must have resource
        final resourceId = resourceByTile[tileKey];
        if (resourceId == null || resourceId.isEmpty) continue;

        // Check if already purchased
        final existingBuyer = game.worldState.purchasedTilesByTileKey[tileKey];
        if (existingBuyer != null) continue; // Already purchased by someone

        result.add(tileKey);
      }
    }
  }
}

bool _isBuildOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  BuildUnitOrder candidate,
) {
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addBuildOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
  );
  return result.isAccepted;
}

/// Suggests naval move orders for fleets owned by [view.playerId]. SPEC/program/naval-movement-resolution.md.
List<NavalMoveOrder> suggestNavalMoveOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestNavalMoveOrders player=${view.playerId}',
  );
  final playerId = view.playerId;
  final suggestions = <NavalMoveOrder>[];
  final existingByFleet = <String, Set<String>>{};
  for (final o
      in currentOrders.navalMoveOrdersByPlayerId[playerId] ?? const []) {
    final key = o.isDock
        ? 'port:${o.destinationPortProvinceId}'
        : (o.destinationSeaZoneId ?? '');
    if (key.isNotEmpty) {
      existingByFleet.putIfAbsent(o.fleetId, () => <String>{}).add(key);
    }
  }

  final homeFleetId = homeFleetIdFor(playerId);
  for (final fleet in game.worldState.fleets) {
    if (fleet.ownerId != playerId || fleet.id == homeFleetId) continue;
    final String? currentZone;
    if (fleet.isAtSea) {
      currentZone = fleet.seaZoneId;
    } else {
      final inPortProvinceId = fleet.inPortAtProvinceId;
      if (inPortProvinceId == null) continue;
      final rl = regionAndLocalProvinceForFleetInPort(
        inPortProvinceId,
        fleet.regionId,
      );
      currentZone = seaZoneIdForProvince(
        topology,
        rl.localId,
        regionId: rl.regionId,
      );
    }
    if (currentZone == null) continue;

    // Suggest move to adjacent sea zones.
    for (final node in topology.nodes) {
      if (node.type != TopologyNodeType.seaZone) continue;
      final destId = node.id;
      if (!isAdjacentSeaZone(topology, currentZone, destId)) continue;
      if (existingByFleet[fleet.id]?.contains(destId) ?? false) continue;
      final candidate = NavalMoveOrder(
        fleetId: fleet.id,
        destinationSeaZoneId: destId,
      );
      if (_isNavalMoveOrderAccepted(
        game,
        topology,
        playerId,
        currentOrders,
        candidate,
      )) {
        suggestions.add(candidate);
      }
    }

    // Suggest dock at adjacent owned provinces (fleets at sea only). SPEC/game/ships-and-naval.md.
    if (fleet.isAtSea) {
      final zoneRegionId = regionIdForSeaZone(topology, currentZone);
      if (zoneRegionId != null) {
        final adjacentLocalIds = provinceIdsAdjacentToSeaZone(
          topology,
          currentZone,
          regionId: zoneRegionId,
        );
        for (final localId in adjacentLocalIds) {
          final fullProvinceId = ProvinceId.full(zoneRegionId, localId);
          if (existingByFleet[fleet.id]?.contains('port:$fullProvinceId') ??
              false)
            continue;
          final province = tryGetProvince(game.worldState, fullProvinceId);
          if (province?.ownerId != playerId) continue;
          final candidate = NavalMoveOrder(
            fleetId: fleet.id,
            destinationPortProvinceId: fullProvinceId,
          );
          if (_isNavalMoveOrderAccepted(
            game,
            topology,
            playerId,
            currentOrders,
            candidate,
          )) {
            suggestions.add(candidate);
          }
        }
      }
    }
  }

  suggestions.sort((a, b) {
    final c = a.fleetId.compareTo(b.fleetId);
    if (c != 0) return c;
    final keyA = a.isDock
        ? 'port:${a.destinationPortProvinceId}'
        : (a.destinationSeaZoneId ?? '');
    final keyB = b.isDock
        ? 'port:${b.destinationPortProvinceId}'
        : (b.destinationSeaZoneId ?? '');
    return keyA.compareTo(keyB);
  });
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestNavalMoveOrders player=$playerId candidates=${suggestions.length}',
  );
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestNavalMoveOrders full list ${suggestions.map((o) => "fleetId=${o.fleetId} destSea=${o.destinationSeaZoneId} destPort=${o.destinationPortProvinceId}").toList()}',
  );
  return suggestions;
}

/// Suggests naval mission orders for fleets owned by [view.playerId]. Phase 6.
List<NavalMissionOrder> suggestNavalMissionOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestNavalMissionOrders player=${view.playerId}',
  );
  final playerId = view.playerId;
  final suggestions = <NavalMissionOrder>[];
  final existingByFleet = <String>{};
  for (final o
      in currentOrders.navalMissionOrdersByPlayerId[playerId] ?? const []) {
    existingByFleet.add(o.fleetId);
  }

  const missions = ['patrol', 'defend', 'none'];
  for (final fleet in game.worldState.fleets) {
    if (fleet.ownerId != playerId) continue;
    if (existingByFleet.contains(fleet.id)) continue;
    for (final mission in missions) {
      final candidate = NavalMissionOrder(fleetId: fleet.id, mission: mission);
      if (_isNavalMissionOrderAccepted(
        game,
        topology,
        playerId,
        currentOrders,
        candidate,
      )) {
        suggestions.add(candidate);
      }
    }
  }

  suggestions.sort((a, b) {
    final c = a.fleetId.compareTo(b.fleetId);
    if (c != 0) return c;
    return a.mission.compareTo(b.mission);
  });
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestNavalMissionOrders player=$playerId candidates=${suggestions.length}',
  );
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestNavalMissionOrders full list ${suggestions.map((o) => "fleetId=${o.fleetId} mission=${o.mission}").toList()}',
  );
  return suggestions;
}

bool _isNavalMoveOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  NavalMoveOrder candidate,
) {
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addNavalMoveOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
  );
  return result.isAccepted;
}

bool _isNavalMissionOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  NavalMissionOrder candidate,
) {
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addNavalMissionOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
  );
  return result.isAccepted;
}

bool _isDiplomaticOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  DiplomaticOrder candidate, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addDiplomaticOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
    tileMapByRegion: tileMapByRegion,
  );
  return result.isAccepted;
}

/// Trial append for suggestion enumeration. SPEC/program/order-suggestions.md.
Orders _appendDiplomaticOrderForTrial(
  Orders orders,
  String playerId,
  DiplomaticOrder order,
) {
  final prev =
      orders.diplomaticOrdersByPlayerId[playerId] ?? const <DiplomaticOrder>[];
  return orders.copyWith(
    diplomaticOrdersByPlayerId: {
      ...orders.diplomaticOrdersByPlayerId,
      playerId: [...prev, order],
    },
  );
}

/// Next overture stage for suggestion (none→tradeConsulate→embassy→nap→joinEmpire).
OvertureStage? _nextOvertureStage(OvertureStage current) {
  switch (current) {
    case OvertureStage.none:
      return OvertureStage.tradeConsulate;
    case OvertureStage.tradeConsulate:
      return OvertureStage.embassy;
    case OvertureStage.embassy:
      return OvertureStage.nap;
    case OvertureStage.nap:
      return OvertureStage.joinEmpire;
    case OvertureStage.joinEmpire:
      return null;
  }
}

/// Per-target suggestion order: first candidate that passes the order engine wins.
/// SPEC/program/order-suggestions.md § Diplomatic orders.
List<DiplomaticOrder> _diplomaticCandidatesForTargetOrdered({
  required Game game,
  required String playerId,
  required Player player,
  required String targetId,
  required Set<String> knownTargetIds,
  required Set<String> knownFactionIds,
}) {
  final treasury = player.treasury;
  final out = <DiplomaticOrder>[];
  if (targetId == playerId) return out;

  final rel = getRelation(game, playerId, targetId);
  final atWar = rel?.atWar ?? false;
  final atPeace = rel == null || rel.atPeace;
  final isGpTarget = game.players.any((p) => p.id == targetId);
  final isMinorOrTribe =
      game.minorNations.any((m) => m.id == targetId) ||
          game.tribes.any((t) => t.id == targetId);

  if (knownTargetIds.contains(targetId) && atWar) {
    out.add(
      DiplomaticOrder(
        type: DiplomaticOrderType.offerPeace,
        targetFactionId: targetId,
      ),
    );
  }
  if (isGpTarget &&
      rel != null &&
      rel.atPeace &&
      rel.level != RelationLevel.allied) {
    out.add(
      DiplomaticOrder(
        type: DiplomaticOrderType.alliance,
        targetFactionId: targetId,
      ),
    );
  }
  if (isMinorOrTribe && knownFactionIds.contains(targetId)) {
    final overtureOrder = _establishOvertureSuggestionOrder(
      game: game,
      playerId: playerId,
      targetId: targetId,
      treasury: treasury,
    );
    if (overtureOrder != null) out.add(overtureOrder);
  }

  OvertureState? overtureRow;
  for (final o in game.overtureStates) {
    if (o.gpId == playerId && o.targetId == targetId) {
      overtureRow = o;
      break;
    }
  }
  if (overtureRow != null) {
    if (overtureRow.hasEmbassy && treasury >= grantAidDefaultAmount) {
      out.add(
        DiplomaticOrder(
          type: DiplomaticOrderType.grantAid,
          targetFactionId: targetId,
          amount: grantAidDefaultAmount,
        ),
      );
    }
    if (overtureRow.hasConsulate && treasury >= setSubsidyDefaultAmount) {
      out.add(
        DiplomaticOrder(
          type: DiplomaticOrderType.setSubsidy,
          targetFactionId: targetId,
          amount: setSubsidyDefaultAmount,
        ),
      );
    }
  }

  if (knownTargetIds.contains(targetId) && atPeace) {
    out.add(
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: targetId,
      ),
    );
  }

  return out;
}

DiplomaticOrder? _establishOvertureSuggestionOrder({
  required Game game,
  required String playerId,
  required String targetId,
  required int treasury,
}) {
  final rel = getRelation(game, playerId, targetId);
  final atWar = rel?.atWar ?? false;
  if (atWar) return null;

  final existing = getOverture(game, playerId, targetId);
  final current = existing?.stage ?? OvertureStage.none;
  final next = _nextOvertureStage(current);
  if (next == null) return null;
  if (next == OvertureStage.tradeConsulate || next == OvertureStage.embassy) {
    final cost = next == OvertureStage.tradeConsulate
        ? overtureConsulateCost
        : overtureEmbassyCost;
    if (treasury < cost) return null;
  }
  if (next == OvertureStage.joinEmpire) {
    final score = rel?.score ?? relationScoreNeutral;
    if (score < relationScoreMinFriendly) return null;
    final cost = joinEmpireCostForMinorOrTribe(game, targetId);
    if (treasury < cost) return null;
  }
  return DiplomaticOrder(
    type: DiplomaticOrderType.establishOverture,
    targetFactionId: targetId,
    overtureStage: next,
  );
}

/// Suggests candidate diplomatic orders that are valid and visible for [view.playerId].
/// SPEC/program/order-suggestions.md; SPEC/program/ai-systems-impl.md.
List<DiplomaticOrder> suggestDiplomaticOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestDiplomaticOrders player=${view.playerId}',
  );
  final playerId = view.playerId;
  final suggestions = <DiplomaticOrder>[];
  final player = view.player;

  // Determine which factions are actually "known" to this player per SPEC:
  // - Any faction with an existing DiplomacyRelation to the player.
  // - Any faction that owns at least one province with a tile visible to the player.
  // Self is never a diplomatic target.
  final knownFactionIds = <String>{};

  for (final rel in game.diplomacyRelations) {
    if (rel.factionId1 == playerId) {
      knownFactionIds.add(rel.factionId2);
    } else if (rel.factionId2 == playerId) {
      knownFactionIds.add(rel.factionId1);
    }
  }

  for (final entry in view.visibilityByTile.entries) {
    if (entry.value == VisibilityLevel.unknown) continue;
    final parts = entry.key.split('|');
    if (parts.length != 4) continue;
    final regionId = parts[0];
    final provinceLocalId = parts[1];
    final provinceId = ProvinceId.full(regionId, provinceLocalId);
    final province = view.provinceByRegionAndId(regionId, provinceId);
    final ownerId = province?.ownerId;
    if (ownerId != null && ownerId != playerId) {
      knownFactionIds.add(ownerId);
    }
  }

  final otherGps = game.players
      .where((p) => p.id != playerId)
      .map((p) => p.id)
      .toList();
  final minorIds = game.minorNations.map((m) => m.id).toList();
  final tribeIds = game.tribes.map((t) => t.id).toList();
  final allTargets = <String>[...otherGps, ...minorIds, ...tribeIds];
  final knownTargets = allTargets
      .where((id) => knownFactionIds.contains(id))
      .toList();
  final knownTargetIds = knownTargets.toSet();

  final unionTargets = <String>{
    ...knownTargets,
    ...otherGps,
    for (final id in minorIds)
      if (knownFactionIds.contains(id)) id,
    for (final id in tribeIds)
      if (knownFactionIds.contains(id)) id,
    for (final o in game.overtureStates)
      if (o.gpId == playerId) o.targetId,
  };

  final sortedTargetIds = unionTargets.toList()..sort();
  for (final targetId in sortedTargetIds) {
    if (targetId == playerId) continue;

    final candidates = _diplomaticCandidatesForTargetOrdered(
      game: game,
      playerId: playerId,
      player: player,
      targetId: targetId,
      knownTargetIds: knownTargetIds,
      knownFactionIds: knownFactionIds,
    );
    var trialOrders = currentOrders;

    for (final candidate in candidates) {
      if (candidate.type == DiplomaticOrderType.grantAid ||
          candidate.type == DiplomaticOrderType.setSubsidy) {
        continue;
      }
      if (!_isDiplomaticOrderAccepted(
        game,
        topology,
        playerId,
        trialOrders,
        candidate,
        tileMapByRegion: tileMapByRegion,
      )) {
        continue;
      }
      suggestions.add(candidate);
      trialOrders = _appendDiplomaticOrderForTrial(
        trialOrders,
        playerId,
        candidate,
      );
      break;
    }

    for (final candidate in candidates) {
      if (candidate.type != DiplomaticOrderType.grantAid &&
          candidate.type != DiplomaticOrderType.setSubsidy) {
        continue;
      }
      if (!_isDiplomaticOrderAccepted(
        game,
        topology,
        playerId,
        trialOrders,
        candidate,
        tileMapByRegion: tileMapByRegion,
      )) {
        continue;
      }
      suggestions.add(candidate);
      trialOrders = _appendDiplomaticOrderForTrial(
        trialOrders,
        playerId,
        candidate,
      );
    }
  }

  suggestions.sort((a, b) {
    final t = a.type.index.compareTo(b.type.index);
    if (t != 0) return t;
    final idCmp = a.targetFactionId.compareTo(b.targetFactionId);
    if (idCmp != 0) return idCmp;
    final stageCmp = (a.overtureStage?.index ?? -1).compareTo(
      b.overtureStage?.index ?? -1,
    );
    if (stageCmp != 0) return stageCmp;
    return (a.amount ?? 0).compareTo(b.amount ?? 0);
  });
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestDiplomaticOrders player=$playerId candidates=${suggestions.length}',
  );
  _log.d(
    '$_kOrderSuggestionLogPrefix: suggestDiplomaticOrders full list ${suggestions.map((o) => "${o.type.name}:${o.targetFactionId}").toList()}',
  );
  return suggestions;
}

/// Abstract order suggestion API for AI. SPEC/program/order-engine.md, ai-systems-impl.md.
/// colonizethis_ai calls this to get candidate orders; logic provides the implementation.
abstract class OrderSuggestionAPI {
  List<MoveOrder> suggestMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  );
  List<WorkOrder> suggestWorkOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  });
  List<BuildUnitOrder> suggestBuildOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  );
  List<ResearchOrder> suggestResearchOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  );
  List<NavalMoveOrder> suggestNavalMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  );
  List<NavalMissionOrder> suggestNavalMissionOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  );
  List<DiplomaticOrder> suggestDiplomaticOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  });
}
