import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import '../diplomacy/diplomacy_resolver.dart';
import '../world/movement.dart';
import '../world/naval.dart';
import 'order_engine.dart';
import 'order_suggestion_helpers.dart';
import 'order_visibility.dart';
import '../world/player_view.dart';

export 'order_suggestion_helpers.dart';

final Logger _log = Logger();

/// Suggests candidate move orders that are information-legal (per [PlayerView])
/// and rules-legal (per [OrderEngine]) for [view.playerId].
List<MoveOrder> suggestMoveOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  _log.d('logic: suggestMoveOrders player=${view.playerId}');
  final playerId = view.playerId;
  final suggestions = <MoveOrder>[];

  // Build a convenience index of current move orders for this player to avoid
  // suggesting duplicate moves for the same unit + destination.
  final existingMoves = <String, Set<String>>{};
  final existingForPlayer = currentOrders.moveOrdersByPlayerId[playerId] ?? const [];
  for (final m in existingForPlayer) {
    existingMoves.putIfAbsent(m.unitId, () => <String>{}).add(m.destinationProvinceId);
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
    for (final neighborLocalId
        in neighborProvinceIdsInRegion(topology, unitRegion, fromLocalId)) {
      final destinationProvinceId = ProvinceId.full(unitRegion, neighborLocalId);

      // Skip duplicates for this unit.
      final already = existingMoves[unit.id];
      if (already != null && already.contains(destinationProvinceId)) continue;

      final destProvince = view.provinceByRegionAndId(unitRegion, neighborLocalId);
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
        final isMinorOrTribe = game.minorNations.any((m) => m.id == destOwnerId) ||
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

      if (_isMoveOrderAccepted(game, topology, playerId, currentOrders, candidate)) {
        suggestions.add(candidate);
      }
    }
  }

  suggestions.sort((a, b) {
    final unitCmp = a.unitId.compareTo(b.unitId);
    if (unitCmp != 0) return unitCmp;
    return a.destinationProvinceId.compareTo(b.destinationProvinceId);
  });

  _log.d('logic: suggestMoveOrders player=$playerId candidates=${suggestions.length}');
  if (suggestions.isEmpty) _log.w('logic: suggestMoveOrders no candidates player=$playerId');
  return suggestions;
}

/// Suggests candidate work orders for explorers and civilian workers owned by
/// [view.playerId]. Work suggestions are only for the unit's current province
/// (unit.provinceId); the API must never suggest work in a province the unit
/// is not in. Visibility rules per SPEC/program/fog-and-exploration-resolution.md.
List<WorkOrder> suggestWorkOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  _log.d('logic: suggestWorkOrders player=${view.playerId}');
  final playerId = view.playerId;
  final suggestions = <WorkOrder>[];

  // Index existing work orders per unit to avoid suggesting duplicates (by unit + target).
  final existingTargetsByUnit = <String, Set<String>>{};
  final existingForPlayer = currentOrders.workOrdersByPlayerId[playerId] ?? const [];
  for (final o in existingForPlayer) {
    existingTargetsByUnit.putIfAbsent(o.unitId, () => <String>{}).add(o.target);
  }

  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;

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
    final tilesInProvince = tileKeysByRegion[regionId]?[provinceId] ?? const [];

    _log.d('logic: suggestWorkOrders unit=${unit.id} provinceId=$provinceId provinceName=${province?.displayName} ownerId=$ownerId regionId=$regionId tilesInProvince=${tilesInProvince.length}');

    // Explorers: explore/prospect in their current province only; visibility rules apply.
    if (isExplorer) {
      // Explore: province must be at least revealed, and something left to reveal.
      if (provinceHasAtLeastVisibility(
          view, regionId, provinceId, VisibilityLevel.revealed)) {
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
            final candidate = WorkOrder(unitId: unit.id, target: target, targetTileKey: targetTileKey);
            if (_isWorkOrderAccepted(
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

      // Prospect: need a tile in province; use first tile if any.
      if (provinceHasAtLeastVisibility(
              view, regionId, provinceId, VisibilityLevel.fogged) &&
          tilesInProvince.isNotEmpty) {
        const prospectTarget = 'prospect';
        final existingProspect = existingTargetsByUnit[unit.id];
        if (existingProspect == null || !existingProspect.contains(prospectTarget)) {
          final prospectTileKey = tilesInProvince.first;
          final candidate = WorkOrder(unitId: unit.id, target: prospectTarget, targetTileKey: prospectTileKey);
          if (_isWorkOrderAccepted(
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
      continue;
    }

    // Civilian workers: only work in owned provinces.
    if (ownerId != null && ownerId != playerId) {
      continue;
    }

    if (isWorker && tilesInProvince.isNotEmpty) {
      final allowedTargets = workOrderTargetsByUnitType[type];
      if (allowedTargets != null) {
        for (final target in allowedTargets) {
          final existing = existingTargetsByUnit[unit.id];
          if (existing != null && existing.contains(target)) continue;

          final targetTileKey = tilesInProvince.first;
          final candidate = WorkOrder(unitId: unit.id, target: target, targetTileKey: targetTileKey);
          if (_isWorkOrderAccepted(game, topology, playerId, currentOrders, candidate)) {
            _log.d('logic: suggestWorkOrders candidate=$candidate');
            suggestions.add(candidate);
          } else {
            _log.d('logic: suggestWorkOrders rejected candidate=$candidate');
          }
        }
      }
    }

    if (isSpy && tilesInProvince.isNotEmpty) {
      final allowedTargets = workOrderTargetsByUnitType[type];
      if (allowedTargets != null) {
        if (allowedTargets.contains('counter_spy') && ownerId == playerId) {
          final targetTileKey = tilesInProvince.first;
          final candidate = WorkOrder(unitId: unit.id, target: 'counter_spy', targetTileKey: targetTileKey);
          if (_isWorkOrderAccepted(game, topology, playerId, currentOrders, candidate)) {
            suggestions.add(candidate);
          }
        }
        if (allowedTargets.contains('steal_tech')) {
          for (final other in game.players) {
            if (other.id == playerId || other.capitalProvinceId == null) continue;
            final capProvinceId = other.capitalProvinceId!;
            final capRegionId = ProvinceId.regionIdFrom(capProvinceId);
            final capTiles = tileKeysByRegion[capRegionId]?[capProvinceId] ?? const [];
            if (capTiles.isEmpty) continue;
            final candidate = WorkOrder(unitId: unit.id, target: 'steal_tech', targetTileKey: capTiles.first);
            if (_isWorkOrderAccepted(game, topology, playerId, currentOrders, candidate)) {
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
        for (final p in [...game.worldState.oldWorld.provinces, ...game.worldState.newWorld.provinces]) {
          if (p.ownerId == null || playerIds.contains(p.ownerId!)) continue;
          final regionId = p.regionId;
          final tiles = tileKeysByRegion[regionId]?[p.id] ?? const [];
          for (final tk in tiles) {
            if (resourceByTile[tk] == null) continue;
            final candidate = WorkOrder(unitId: unit.id, target: 'purchase_land', targetTileKey: tk);
            if (_isWorkOrderAccepted(game, topology, playerId, currentOrders, candidate)) {
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

  _log.d('logic: suggestWorkOrders player=$playerId candidates=${suggestions.length}');
  if (suggestions.isEmpty) _log.w('logic: suggestWorkOrders no candidates player=$playerId');
  return suggestions;
}

/// Suggests build-unit orders that are affordable and valid for [view.playerId].
List<BuildUnitOrder> suggestBuildOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  _log.d('logic: suggestBuildOrders player=${view.playerId}');
  final playerId = view.playerId;
  final player = view.player;
  final suggestions = <BuildUnitOrder>[];

  final capitalId = player.capitalProvinceId;
  if (capitalId == null) {
    _log.w('logic: suggestBuildOrders no capital player=$playerId');
    return suggestions;
  }

  // Military (regiment) builds.
  for (final entry in RegimentEconomyCatalog.byId.entries) {
    final unitType = entry.key;
    final candidate = BuildUnitOrder(
      unitType: unitType,
      isMilitary: buildUnitCategoryForUnitType(unitType) == BuildUnitCategory.military,
      spawnProvinceId: capitalId,
    );

    if (_isBuildOrderAccepted(game, topology, playerId, currentOrders, candidate)) {
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

    if (_isBuildOrderAccepted(game, topology, playerId, currentOrders, candidate)) {
      suggestions.add(candidate);
    }
  }

  suggestions.sort((a, b) => a.unitType.compareTo(b.unitType));

  _log.d('logic: suggestBuildOrders player=$playerId candidates=${suggestions.length}');
  if (suggestions.isEmpty) _log.w('logic: suggestBuildOrders no candidates player=$playerId');
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
  _log.d('logic: suggestResearchOrders player=${view.playerId}');
  final playerId = view.playerId;
  final player = view.player;
  final suggestions = <ResearchOrder>[];

  final unlocked = player.techUnlocked ?? const {};
  final existingBySlot = <int, ResearchOrder>{};
  final existingForPlayer = currentOrders.researchOrdersByPlayerId[playerId] ?? const [];
  for (final o in existingForPlayer) {
    existingBySlot[o.slotIndex] = o;
  }

  final candidates = <TechDefinition>[];
  for (final entry in techCatalog.entries) {
    final tech = entry.value;
    if (unlocked[tech.id] == true) continue;
    var prereqsOk = true;
    for (final pre in tech.prerequisiteIds) {
      if (unlocked[pre] != true) {
        prereqsOk = false;
        break;
      }
    }
    if (!prereqsOk) continue;
    candidates.add(tech);
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

  _log.d('logic: suggestResearchOrders player=$playerId candidates=${suggestions.length}');
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
  final result = engine.addMoveOrderWithContext(game, topology, playerId, candidate);
  return result.isAccepted;
}

bool _isWorkOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  WorkOrder candidate,
) {
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addWorkOrderWithContext(game, topology, playerId, candidate);
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
  Orders currentOrders,
) {
  final units = [
    ...game.worldState.oldWorld.units,
    ...game.worldState.newWorld.units,
  ];
  final unit = units.where((u) => u.id == unitId).firstOrNull;
  if (unit == null || unit.ownerId != playerId) return {};
  if (unit.currentWork != null) return {};
  if (!isWorkOrderTargetAllowedForUnitType(unit.type, workTarget)) return {};

  final tileKeysByRegion = game.worldState.tileKeysByRegionAndProvince;
  final valid = <String>{};
  for (final regionEntry in tileKeysByRegion.entries) {
    for (final provinceEntry in regionEntry.value.entries) {
      for (final tileKey in provinceEntry.value) {
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
        )) {
          valid.add(tileKey);
        }
      }
    }
  }
  _log.d('logic: getValidWorkOrderTileKeys unit=$unitId target=$workTarget count=${valid.length}');
  return valid;
}

bool _isBuildOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  BuildUnitOrder candidate,
) {
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addBuildOrderWithContext(game, topology, playerId, candidate);
  return result.isAccepted;
}

/// Suggests naval move orders for fleets owned by [view.playerId]. SPEC/program/naval-movement-resolution.md.
List<NavalMoveOrder> suggestNavalMoveOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  _log.d('logic: suggestNavalMoveOrders player=${view.playerId}');
  final playerId = view.playerId;
  final suggestions = <NavalMoveOrder>[];
  final existingByFleet = <String, Set<String>>{};
  for (final o in currentOrders.navalMoveOrdersByPlayerId[playerId] ?? const []) {
    existingByFleet.putIfAbsent(o.fleetId, () => <String>{}).add(o.destinationSeaZoneId);
  }

  for (final fleet in game.worldState.fleets) {
    if (fleet.ownerId != playerId) continue;
    for (final node in topology.nodes) {
      if (node.type != TopologyNodeType.seaZone) continue;
      final destId = node.id;
      if (!isAdjacentSeaZone(topology, fleet.seaZoneId, destId)) continue;
      if (existingByFleet[fleet.id]?.contains(destId) ?? false) continue;
      final candidate = NavalMoveOrder(fleetId: fleet.id, destinationSeaZoneId: destId);
      if (_isNavalMoveOrderAccepted(game, topology, playerId, currentOrders, candidate)) {
        suggestions.add(candidate);
      }
    }
  }

  suggestions.sort((a, b) {
    final c = a.fleetId.compareTo(b.fleetId);
    if (c != 0) return c;
    return a.destinationSeaZoneId.compareTo(b.destinationSeaZoneId);
  });
  _log.d('logic: suggestNavalMoveOrders player=$playerId candidates=${suggestions.length}');
  return suggestions;
}

/// Suggests naval mission orders for fleets owned by [view.playerId]. Phase 6.
List<NavalMissionOrder> suggestNavalMissionOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  _log.d('logic: suggestNavalMissionOrders player=${view.playerId}');
  final playerId = view.playerId;
  final suggestions = <NavalMissionOrder>[];
  final existingByFleet = <String>{};
  for (final o in currentOrders.navalMissionOrdersByPlayerId[playerId] ?? const []) {
    existingByFleet.add(o.fleetId);
  }

  const missions = ['patrol', 'defend', 'none'];
  for (final fleet in game.worldState.fleets) {
    if (fleet.ownerId != playerId) continue;
    if (existingByFleet.contains(fleet.id)) continue;
    for (final mission in missions) {
      final candidate = NavalMissionOrder(fleetId: fleet.id, mission: mission);
      if (_isNavalMissionOrderAccepted(game, topology, playerId, currentOrders, candidate)) {
        suggestions.add(candidate);
      }
    }
  }

  suggestions.sort((a, b) {
    final c = a.fleetId.compareTo(b.fleetId);
    if (c != 0) return c;
    return a.mission.compareTo(b.mission);
  });
  _log.d('logic: suggestNavalMissionOrders player=$playerId candidates=${suggestions.length}');
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
  final result = engine.addNavalMoveOrderWithContext(game, topology, playerId, candidate);
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
  final result = engine.addNavalMissionOrderWithContext(game, topology, playerId, candidate);
  return result.isAccepted;
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

/// Suggests candidate diplomatic orders that are valid and visible for [view.playerId].
/// SPEC/program/ai-systems-impl.md; .github/ISSUE_AI_SPEC_GAPS.md item 11.
List<DiplomaticOrder> suggestDiplomaticOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  _log.d('logic: suggestDiplomaticOrders player=${view.playerId}');
  final playerId = view.playerId;
  final suggestions = <DiplomaticOrder>[];
  final player = view.player;
  final treasury = player.treasury;

  final otherGps = game.players.where((p) => p.id != playerId).map((p) => p.id).toList();
  final minorIds = game.minorNations.map((m) => m.id).toList();
  final tribeIds = game.tribes.map((t) => t.id).toList();
  final allTargets = <String>[...otherGps, ...minorIds, ...tribeIds];

  for (final targetId in allTargets) {
    if (targetId == playerId) continue;
    final rel = getRelation(game, playerId, targetId);
    final atPeace = rel == null || rel.atPeace;
    if (atPeace) {
      suggestions.add(DiplomaticOrder(type: DiplomaticOrderType.declareWar, targetFactionId: targetId));
    }
    if (rel != null && rel.atWar) {
      suggestions.add(DiplomaticOrder(type: DiplomaticOrderType.offerPeace, targetFactionId: targetId));
    }
  }

  for (final targetId in otherGps) {
    final rel = getRelation(game, playerId, targetId);
    if (rel != null && rel.atPeace && rel.level != RelationLevel.allied) {
      suggestions.add(DiplomaticOrder(type: DiplomaticOrderType.alliance, targetFactionId: targetId));
    }
  }

  for (final targetId in [...minorIds, ...tribeIds]) {
    final existing = getOverture(game, playerId, targetId);
    final current = existing?.stage ?? OvertureStage.none;
    final next = _nextOvertureStage(current);
    if (next == null) continue;
    if (next == OvertureStage.tradeConsulate || next == OvertureStage.embassy) {
      final cost = next == OvertureStage.tradeConsulate ? overtureConsulateCost : overtureEmbassyCost;
      if (treasury < cost) continue;
    }
    if (next == OvertureStage.joinEmpire) {
      final rel = getRelation(game, playerId, targetId);
      final score = rel?.score ?? 50;
      if (score < 51) continue;
      final cost = joinEmpireCostForMinorOrTribe(game, targetId);
      if (treasury < cost) continue;
    }
    suggestions.add(DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: targetId,
      overtureStage: next,
    ));
  }

  final overtureStates = game.overtureStates;
  for (final o in overtureStates) {
    if (o.gpId != playerId) continue;
    final targetId = o.targetId;
    if (o.hasEmbassy && treasury >= 100) {
      suggestions.add(DiplomaticOrder(
        type: DiplomaticOrderType.grantAid,
        targetFactionId: targetId,
        amount: 100,
      ));
    }
    if (o.hasConsulate && treasury >= 100) {
      suggestions.add(DiplomaticOrder(
        type: DiplomaticOrderType.setSubsidy,
        targetFactionId: targetId,
        amount: 100,
      ));
    }
  }

  suggestions.sort((a, b) {
    final t = a.type.index.compareTo(b.type.index);
    if (t != 0) return t;
    return a.targetFactionId.compareTo(b.targetFactionId);
  });
  _log.d('logic: suggestDiplomaticOrders player=$playerId candidates=${suggestions.length}');
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
    Orders currentOrders,
  );
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
    Orders currentOrders,
  );
}

