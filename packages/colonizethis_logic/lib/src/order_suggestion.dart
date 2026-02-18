import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_engine.dart';
import 'player_view.dart';

/// Suggests candidate move orders that are information-legal (per [PlayerView])
/// and rules-legal (per [OrderEngine]) for [view.playerId].
List<MoveOrder> suggestMoveOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
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
    final fromProvinceId = unit.provinceId;

    // Enumerate neighboring provinces via topology.
    for (final edge in topology.edges) {
      String? neighborId;
      if (edge.id1 == fromProvinceId) {
        neighborId = edge.id2;
      } else if (edge.id2 == fromProvinceId) {
        neighborId = edge.id1;
      }
      if (neighborId == null) continue;

      // Only consider neighbors that are provinces.
      final neighborNode = topology.nodes.firstWhere(
        (n) => n.id == neighborId,
        orElse: () => const TopologyNode(
          id: '',
          regionId: '',
          type: TopologyNodeType.seaZone,
        ),
      );
      if (neighborNode.type != TopologyNodeType.province) continue;

      // Skip duplicates for this unit.
      final already = existingMoves[unit.id];
      if (already != null && already.contains(neighborId)) continue;

      final destProvince = view.provinceById(neighborId);
      final destOwnerId = destProvince?.ownerId;

      // Require that the destination province has at least one tile that is
      // known (visibility != unknown). This uses PlayerView visibility rather
      // than omniscient map state.
      final hasVisibleTileInDest = view.visibilityByTile.entries.any((e) {
        final parts = e.key.split('|');
        if (parts.length != 4) return false;
        final provinceId = parts[1];
        return provinceId == neighborId &&
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
        destinationProvinceId: neighborId,
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

  return suggestions;
}

/// Suggests candidate work orders for explorers and civilian workers owned by
/// [view.playerId]. Current implementation is conservative and focuses on
/// obviously legal actions; it can be extended later as fog-of-war wiring is
/// completed.
List<WorkOrder> suggestWorkOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  final playerId = view.playerId;
  final suggestions = <WorkOrder>[];

  // Index existing work orders per unit to avoid suggesting duplicates.
  final existingTargetsByUnit = <String, Set<String>>{};
  final existingForPlayer = currentOrders.workOrdersByPlayerId[playerId] ?? const [];
  for (final o in existingForPlayer) {
    existingTargetsByUnit.putIfAbsent(o.unitId, () => <String>{}).add(o.target);
  }

  for (final unit in view.ownUnits) {
    final type = unit.type;
    final isExplorer = isExplorerUnit(type);
    final isWorker = isCivilianWorkerUnit(type);
    if (!isExplorer && !isWorker) continue;

    final province = view.provinceById(unit.provinceId);
    final ownerId = province?.ownerId;

    // Explorers: always allowed to explore/prospect in their current province,
    // but only suggest explore when there is something left to reveal.
    if (isExplorer) {
      final provinceId = unit.provinceId;

      // Check if any tile in this province is not yet fully visible.
      final hasPartiallyHiddenTile = view.visibilityByTile.entries.any((e) {
        final parts = e.key.split('|');
        if (parts.length != 4) return false;
        final tileProvinceId = parts[1];
        if (tileProvinceId != provinceId) return false;
        return e.value != VisibilityLevel.fullyVisible;
      });

      // Suggest explore only when there is something left to reveal.
      if (hasPartiallyHiddenTile) {
        const target = 'explore';
        final existing = existingTargetsByUnit[unit.id];
        if (existing == null || !existing.contains(target)) {
          final candidate = WorkOrder(unitId: unit.id, target: target);
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

      // Prospect remains unconditional for now until unit tile positions and
      // per-tile prospection are wired; OrderEngine will still enforce rules.
      const prospectTarget = 'prospect';
      final existingProspect = existingTargetsByUnit[unit.id];
      if (existingProspect == null || !existingProspect.contains(prospectTarget)) {
        final candidate = WorkOrder(unitId: unit.id, target: prospectTarget);
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
      continue;
    }

    // Civilian workers: only work in owned provinces.
    if (ownerId != null && ownerId != playerId) {
      continue;
    }

    for (final target in const [
      'build_improvement',
      'upgrade_town',
      'build_road',
      'build_port',
      'build_fort',
      'build_rail',
    ]) {
      final existing = existingTargetsByUnit[unit.id];
      if (existing != null && existing.contains(target)) continue;

      final candidate = WorkOrder(unitId: unit.id, target: target);
      if (_isWorkOrderAccepted(game, topology, playerId, currentOrders, candidate)) {
        suggestions.add(candidate);
      }
    }
  }

  suggestions.sort((a, b) {
    final unitCmp = a.unitId.compareTo(b.unitId);
    if (unitCmp != 0) return unitCmp;
    return a.target.compareTo(b.target);
  });

  return suggestions;
}

/// Suggests build-unit orders that are affordable and valid for [view.playerId].
List<BuildUnitOrder> suggestBuildOrders(
  PlayerView view,
  Game game,
  MapTopology topology,
  Orders currentOrders,
) {
  final playerId = view.playerId;
  final player = view.player;
  final suggestions = <BuildUnitOrder>[];

  final capitalId = player.capitalProvinceId;
  if (capitalId == null) {
    return suggestions;
  }

  // For now, suggest only military builds using RegimentEconomyCatalog.
  for (final entry in RegimentEconomyCatalog.byId.entries) {
    final unitType = entry.key;
    final candidate = BuildUnitOrder(
      unitType: unitType,
      isMilitary: true,
      spawnProvinceId: capitalId,
    );

    if (_isBuildOrderAccepted(game, topology, playerId, currentOrders, candidate)) {
      suggestions.add(candidate);
    }
  }

  suggestions.sort((a, b) => a.unitType.compareTo(b.unitType));

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

