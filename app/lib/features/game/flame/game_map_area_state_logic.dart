import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart';

/// Pure-ish helpers for `GameMapArea` state translation.
class GameMapAreaStateLogic {
  static const String _regionOldWorld = 'oldWorld';

  static int regionIndexFromWorldRegionId(String regionId) {
    if (regionId == 'newWorld') return 1;
    return 0; // oldWorld (default)
  }

  static bool isWorkTargetTileProvinceBased(String workTarget) {
    return workTarget == kWorkTargetExplore ||
        workTarget == kWorkTargetStealTech ||
        workTarget == kWorkTargetCounterSpy;
  }

  /// For province-based work targets, translate the tile key to a canonical tile
  /// key within that province (x=0,y=0).
  static String translateWorkTargetTileKey({
    required String tileKey,
    required String workTarget,
  }) {
    if (!isWorkTargetTileProvinceBased(workTarget)) return tileKey;
    final parts = tileKey.split('|');
    if (parts.length < 2) return tileKey;
    return '${parts[0]}|${parts[1]}|0|0';
  }

  static ct_models.Orders addHumanWorkOrder({
    required ct_models.Orders orders,
    required String humanPlayerId,
    required ct_models.WorkOrder workOrder,
  }) {
    final prior = List<ct_models.WorkOrder>.from(
      orders.workOrdersByPlayerId[humanPlayerId] ??
          const <ct_models.WorkOrder>[],
    )..removeWhere((o) => o.unitId == workOrder.unitId);
    prior.add(workOrder);
    final movesWithoutUnit = List<ct_models.MoveOrder>.from(
      orders.moveOrdersByPlayerId[humanPlayerId] ??
          const <ct_models.MoveOrder>[],
    )..removeWhere((o) => o.unitId == workOrder.unitId);
    return orders.copyWith(
      moveOrdersByPlayerId: {
        ...orders.moveOrdersByPlayerId,
        humanPlayerId: movesWithoutUnit,
      },
      workOrdersByPlayerId: {
        ...orders.workOrdersByPlayerId,
        humanPlayerId: prior,
      },
    );
  }

  /// Returns the post-assignment civilian selection key.
  /// Keeps selection only when the selected key already points at the assigned
  /// marker tile; otherwise clears stale blink state.
  static String? selectionAfterWorkAssignment({
    required String? currentSelectedCivilianTileKey,
    required String assignedTileKey,
  }) {
    if (currentSelectedCivilianTileKey == assignedTileKey) {
      return currentSelectedCivilianTileKey;
    }
    return null;
  }

  /// Projects player-owned civilian markers using current-turn pending orders.
  /// This keeps map feedback in sync with assign flows before turn resolution.
  static RegionMapViewData projectCivilianMarkersForHumanDraft({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
  }) {
    if (region.civilianTileMarkers.isEmpty) {
      return region;
    }
    final pendingByUnitId = <String, String>{};
    final pending = orders.workOrdersByPlayerId[humanPlayerId] ?? const [];
    for (final order in pending) {
      final target = order.targetTileKey;
      if (target.isEmpty) continue;
      pendingByUnitId[order.unitId] = target;
    }
    if (pendingByUnitId.isEmpty) {
      return region;
    }

    final regionUnits = region.regionId == _regionOldWorld
        ? game.worldState.oldWorld.units
        : game.worldState.newWorld.units;
    final unitsById = <String, ct_models.Unit>{
      for (final u in regionUnits)
        if (u.ownerId == humanPlayerId && _isCivilianUnitType(u.type)) u.id: u,
    };
    if (unitsById.isEmpty) {
      return region;
    }

    final projectedByTile = <String, List<_ProjectedCivilianUnit>>{};
    for (final marker in region.civilianTileMarkers) {
      for (final unitId in marker.unitIds) {
        final unit = unitsById[unitId];
        if (unit == null) continue;
        final projectedTile =
            projectedCivilianTileKey(
              unit: unit,
              playerId: humanPlayerId,
              orders: orders,
            ) ??
            marker.tileKey;
        final parts = projectedTile.split('|');
        if (parts.length < 4 || parts[0] != region.regionId) continue;
        projectedByTile
            .putIfAbsent(projectedTile, () => <_ProjectedCivilianUnit>[])
            .add(
              _ProjectedCivilianUnit(
                unitId: unitId,
                unitType: unit.type,
                pendingTargetTileKey: pendingByUnitId[unitId],
                assignedTileKey: unit.assignedTileKey,
                status: unit.status,
              ),
            );
      }
    }
    if (projectedByTile.isEmpty) {
      return region;
    }

    final projectedMarkers = <CivilianTileMarkerView>[];
    for (final entry in projectedByTile.entries) {
      final tileKey = entry.key;
      final units = entry.value.toList()
        ..sort((a, b) {
          final p = _civilianIconPriorityForType(
            a.unitType,
          ).compareTo(_civilianIconPriorityForType(b.unitType));
          if (p != 0) return p;
          return a.unitId.compareTo(b.unitId);
        });
      final parts = tileKey.split('|');
      final x = int.tryParse(parts[2]);
      final y = int.tryParse(parts[3]);
      if (x == null || y == null) continue;
      final representative = units.first;
      final representativeIsAssigned =
          representative.pendingTargetTileKey == tileKey ||
          (representative.assignedTileKey == tileKey &&
              representative.status == ct_models.UnitStatus.working);
      projectedMarkers.add(
        CivilianTileMarkerView(
          tileKey: tileKey,
          x: x,
          y: y,
          localProvinceId: parts[1],
          unitIds: units.map((u) => u.unitId).toList(),
          unitTypes: {for (final u in units) u.unitId: u.unitType},
          representativeUnitType: representative.unitType,
          stackCount: units.length,
          representativeIsAssigned: representativeIsAssigned,
        ),
      );
    }

    projectedMarkers.sort((a, b) {
      final yc = a.y.compareTo(b.y);
      if (yc != 0) return yc;
      final xc = a.x.compareTo(b.x);
      if (xc != 0) return xc;
      return a.tileKey.compareTo(b.tileKey);
    });

    return RegionMapViewData(
      regionId: region.regionId,
      width: region.width,
      height: region.height,
      cellSize: region.cellSize,
      cells: region.cells,
      capitalMarkers: region.capitalMarkers,
      portMarkers: region.portMarkers,
      factionColors: region.factionColors,
      greatPowerFactionIds: region.greatPowerFactionIds,
      terrainColors: region.terrainColors,
      unitMarkers: region.unitMarkers,
      civilianTileMarkers: projectedMarkers,
      fleetTileMarkers: region.fleetTileMarkers,
      warpMarkers: region.warpMarkers,
      townMarkers: region.townMarkers,
      provinceUnitPresenceByProvinceId: region.provinceUnitPresenceByProvinceId,
      provincePoliticalOwnerByPrefixedProvinceId:
          region.provincePoliticalOwnerByPrefixedProvinceId,
      seaZoneDisplayNameByPrefixedId: region.seaZoneDisplayNameByPrefixedId,
    );
  }

  /// Projects fleet marker tiles using human naval move drafts; grayscale and
  /// halo flags follow issue #1745 / SPEC/ui/map-widget.md.
  static RegionMapViewData projectFleetMarkersForHumanDraft({
    required RegionMapViewData region,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    required Map<String, TileMapResult> tileMapByRegion,
    required Map<String, MapTopology> topologyByRegion,
    required MapTopology combinedTopology,
  }) {
    final moves = orders.navalMoveOrdersByPlayerId[humanPlayerId] ?? const [];
    final missions =
        orders.navalMissionOrdersByPlayerId[humanPlayerId] ?? const [];
    final moveByFleetId = <String, ct_models.NavalMoveOrder>{
      for (final m in moves) m.fleetId: m,
    };
    final missionFleetIds = <String>{for (final m in missions) m.fleetId};

    bool hasDraftNaval(String fleetId) =>
        moveByFleetId.containsKey(fleetId) || missionFleetIds.contains(fleetId);

    ct_models.Fleet? findFleet(String id) {
      for (final f in game.worldState.fleets) {
        if (f.id == id) {
          return f;
        }
      }
      return null;
    }

    String seaZoneLocalId(String seaZoneId) {
      return seaZoneId.contains('|') ? seaZoneId.split('|').last : seaZoneId;
    }

    String destinationRegionForSeaZone({
      required String seaZoneId,
      required String fallbackRegionId,
    }) {
      final fromCombined = regionIdForSeaZone(combinedTopology, seaZoneId);
      if (fromCombined != null) {
        return fromCombined;
      }
      final localSeaZoneId = seaZoneLocalId(seaZoneId);
      for (final entry in topologyByRegion.entries) {
        final hasZone = entry.value.nodes.any(
          (n) => n.type == TopologyNodeType.seaZone && n.id == localSeaZoneId,
        );
        if (hasZone) {
          return entry.key;
        }
      }
      return fallbackRegionId;
    }

    String? destinationTileForMove({
      required ct_models.NavalMoveOrder move,
      required String fleetRegionId,
    }) {
      if (move.isDock) {
        final pid = move.destinationPortProvinceId!;
        final p = tryGetProvince(game.worldState, pid);
        if (p == null) {
          return null;
        }
        final destReg = p.regionId;
        final tmDock = tileMapByRegion[destReg];
        final tpDock = topologyByRegion[destReg];
        if (tmDock == null || tpDock == null) {
          return null;
        }
        final seaIdsDock = {
          for (final n in tpDock.nodes)
            if (n.type == TopologyNodeType.seaZone) n.id,
        };
        return harborDrawableSeaTileKeyForPortProvince(
          game: game,
          regionId: destReg,
          localProvinceId: ct_models.ProvinceId.localIdFrom(p.id),
          tileMap: tmDock,
          seaZoneIds: seaIdsDock,
          contextLabel: 'dock draft destination',
        );
      }
      final seaId = move.destinationSeaZoneId!;
      final destReg = destinationRegionForSeaZone(
        seaZoneId: seaId,
        fallbackRegionId: fleetRegionId,
      );
      final tm = tileMapByRegion[destReg];
      final tp = topologyByRegion[destReg];
      if (tm == null || tp == null) {
        return null;
      }
      final seaIds = {
        for (final n in tp.nodes)
          if (n.type == TopologyNodeType.seaZone) n.id,
      };
      final local = seaZoneLocalId(seaId);
      return seaZoneCentroidTileKey(
        tileMap: tm,
        regionId: destReg,
        localSeaZoneId: local,
        seaZoneNodeIds: seaIds,
      );
    }

    String normalizedSeaScope({
      required String seaZoneId,
      required String fallbackRegionId,
    }) {
      final regionId = destinationRegionForSeaZone(
        seaZoneId: seaZoneId,
        fallbackRegionId: fallbackRegionId,
      );
      final local = seaZoneLocalId(seaZoneId);
      return 'sea:$regionId|$local';
    }

    String locationScopeForMove({
      required ct_models.NavalMoveOrder move,
      required String fleetRegionId,
    }) {
      if (move.isDock) {
        final pid = move.destinationPortProvinceId!;
        final p = tryGetProvince(game.worldState, pid);
        if (p != null) {
          final localProvinceId = ct_models.ProvinceId.localIdFrom(p.id);
          return 'port:${p.regionId}|$localProvinceId';
        }
        return 'port:$pid';
      }
      return normalizedSeaScope(
        seaZoneId: move.destinationSeaZoneId!,
        fallbackRegionId: fleetRegionId,
      );
    }

    String? currentLocationScopeForFleet(ct_models.Fleet f) {
      if (f.isAtSea && f.seaZoneId != null) {
        return normalizedSeaScope(
          seaZoneId: f.seaZoneId!,
          fallbackRegionId: f.regionId,
        );
      }
      if (f.inPortAtProvinceId != null) {
        final p = tryGetProvince(game.worldState, f.inPortAtProvinceId!);
        if (p != null) {
          final localProvinceId = ct_models.ProvinceId.localIdFrom(p.id);
          return 'port:${p.regionId}|$localProvinceId';
        }
        return 'port:${f.inPortAtProvinceId!}';
      }
      return null;
    }

    String? currentTileForFleet(ct_models.Fleet f) {
      final tm = tileMapByRegion[f.regionId];
      final tp = topologyByRegion[f.regionId];
      if (tm == null || tp == null) {
        return null;
      }
      final seaIds = {
        for (final n in tp.nodes)
          if (n.type == TopologyNodeType.seaZone) n.id,
      };
      if (f.isAtSea && f.seaZoneId != null) {
        final z = f.seaZoneId!;
        final zoneKey = z.contains('|') ? z : '${f.regionId}|$z';
        final local = zoneKey.contains('|') ? zoneKey.split('|').last : zoneKey;
        return seaZoneCentroidTileKey(
          tileMap: tm,
          regionId: f.regionId,
          localSeaZoneId: local,
          seaZoneNodeIds: seaIds,
        );
      }
      if (f.inPortAtProvinceId != null) {
        final p = tryGetProvince(game.worldState, f.inPortAtProvinceId!);
        if (p == null) {
          return null;
        }
        final reg = p.regionId;
        final tmPort = tileMapByRegion[reg];
        final tpPort = topologyByRegion[reg];
        if (tmPort == null || tpPort == null) {
          return null;
        }
        final seaIdsPort = {
          for (final n in tpPort.nodes)
            if (n.type == TopologyNodeType.seaZone) n.id,
        };
        return harborDrawableSeaTileKeyForPortProvince(
          game: game,
          regionId: reg,
          localProvinceId: ct_models.ProvinceId.localIdFrom(p.id),
          tileMap: tmPort,
          seaZoneIds: seaIdsPort,
          contextLabel: 'in-port fleet current',
        );
      }
      return null;
    }

    final fleetIdsToProject = <String>{for (final m in moves) m.fleetId};
    for (final marker in region.fleetTileMarkers) {
      for (final fleetId in marker.fleetIds) {
        fleetIdsToProject.add(fleetId);
      }
    }
    if (fleetIdsToProject.isEmpty) {
      return region;
    }

    final groups = <String, _FleetTileProj>{};
    for (final fleetId in fleetIdsToProject) {
      final fleet = findFleet(fleetId);
      final mv = moveByFleetId[fleetId];
      if (fleet == null) {
        continue;
      }
      String? tileKey;
      String? locationScopeKey;
      if (mv != null) {
        tileKey = destinationTileForMove(
          move: mv,
          fleetRegionId: fleet.regionId,
        );
        tileKey ??= currentTileForFleet(fleet);
        locationScopeKey = locationScopeForMove(
          move: mv,
          fleetRegionId: fleet.regionId,
        );
      } else {
        tileKey = currentTileForFleet(fleet);
        locationScopeKey = currentLocationScopeForFleet(fleet);
      }
      if (tileKey == null) {
        continue;
      }
      final parts = tileKey.split('|');
      if (parts.length < 4 || parts[0] != region.regionId) {
        continue;
      }

      final g = groups.putIfAbsent(tileKey, _FleetTileProj.new);
      g.fleetIds.add(fleetId);
      g.locationScopeKeys.add(locationScopeKey ?? '');
      if (mv != null) {
        g.anyNavalMoveDraft = true;
      }
    }

    final out = <FleetTileMarkerView>[];
    for (final e in groups.entries) {
      final tk = e.key;
      final g = e.value;
      final sortedIds = g.fleetIds.toList()..sort();
      final parts = tk.split('|');
      final x = int.tryParse(parts[parts.length - 2]);
      final y = int.tryParse(parts[parts.length - 1]);
      if (x == null || y == null) {
        continue;
      }
      final scopeCandidates = g.locationScopeKeys.toList()..sort();
      final scope = scopeCandidates.isEmpty ? '' : scopeCandidates.first;
      out.add(
        FleetTileMarkerView(
          tileKey: tk,
          x: x,
          y: y,
          locationScopeKey: scope,
          fleetIds: sortedIds,
          stackCount: sortedIds.length,
          renderGrayscale: sortedIds.every(hasDraftNaval),
          applyFleetRevealHalo: g.anyNavalMoveDraft,
        ),
      );
    }
    out.sort((a, b) {
      final yc = a.y.compareTo(b.y);
      if (yc != 0) {
        return yc;
      }
      final xc = a.x.compareTo(b.x);
      if (xc != 0) {
        return xc;
      }
      return a.tileKey.compareTo(b.tileKey);
    });

    return RegionMapViewData(
      regionId: region.regionId,
      width: region.width,
      height: region.height,
      cellSize: region.cellSize,
      cells: region.cells,
      capitalMarkers: region.capitalMarkers,
      portMarkers: region.portMarkers,
      factionColors: region.factionColors,
      greatPowerFactionIds: region.greatPowerFactionIds,
      terrainColors: region.terrainColors,
      unitMarkers: region.unitMarkers,
      civilianTileMarkers: region.civilianTileMarkers,
      fleetTileMarkers: out,
      warpMarkers: region.warpMarkers,
      townMarkers: region.townMarkers,
      provinceUnitPresenceByProvinceId: region.provinceUnitPresenceByProvinceId,
      provincePoliticalOwnerByPrefixedProvinceId:
          region.provincePoliticalOwnerByPrefixedProvinceId,
      seaZoneDisplayNameByPrefixedId: region.seaZoneDisplayNameByPrefixedId,
    );
  }

  static bool _isCivilianUnitType(String unitType) {
    final role = unitRoleForType(unitType);
    if (role == null) return false;
    return role != UnitRole.military && role != UnitRole.naval;
  }

  static String _normalizeCivilianTypeForPriority(String type) {
    return type.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
  }

  static int _civilianIconPriorityForType(String type) {
    final normalized = _normalizeCivilianTypeForPriority(type);
    switch (normalized) {
      case 'builder':
        return 0;
      case 'engineer':
        return 1;
      case 'railbuilder':
        return 2;
      case 'explorer':
        return 3;
      case 'merchant':
        return 4;
      case 'spy':
        return 5;
      default:
        return 999;
    }
  }

  /// Returns province-overlay prospect action visibility + enablement.
  ///
  /// The panel must read stable world/player tile state only so map scrolling
  /// and rebuild churn do not trigger expensive order-engine validation.
  static ({bool showIcon, bool enabled, bool hasExplorerUnits})
  provinceProspectActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    required MapTopology? topology,
    required ct_models.Orders currentOrders,
    required Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final tileParts = selectedTileKey.split('|');
    if (tileParts.length < 4) {
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }
    final tileVisibility = playerView.visibilityForTile(selectedTileKey);
    if (tileVisibility == VisibilityLevel.unknown) {
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }
    final tileRegionId = tileParts[0];
    final tileProvinceId = tileParts[1];
    final prefixedProvinceId = '$tileRegionId|$tileProvinceId';
    final isProvinceTile =
        tryGetProvince(game.worldState, prefixedProvinceId) != null;
    if (!isProvinceTile) {
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }

    final isMineralEligible = isMineralEligibleTile(
      game,
      tileMapByRegion,
      selectedTileKey,
    );
    if (!isMineralEligible) {
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }

    final playerProspectedTiles =
        game.worldState.playerProspectedTiles[humanPlayerId] ??
        const <String>{};
    if (playerProspectedTiles.contains(selectedTileKey)) {
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }

    final allUnits = <ct_models.Unit>[
      ...game.worldState.oldWorld.units,
      ...game.worldState.newWorld.units,
    ];
    final explorerUnits = allUnits
        .where((unit) => unit.ownerId == humanPlayerId)
        .where(
          (unit) =>
              workOrderTargetsByUnitType[unit.type]?.contains(
                kWorkTargetProspect,
              ) ??
              false,
        )
        .toList();
    if (explorerUnits.isEmpty) {
      return (showIcon: true, enabled: false, hasExplorerUnits: false);
    }
    return (showIcon: true, enabled: true, hasExplorerUnits: true);
  }
}

class _FleetTileProj {
  _FleetTileProj();

  final Set<String> fleetIds = {};
  final Set<String> locationScopeKeys = {};
  bool anyNavalMoveDraft = false;
}

class _ProjectedCivilianUnit {
  const _ProjectedCivilianUnit({
    required this.unitId,
    required this.unitType,
    required this.pendingTargetTileKey,
    required this.assignedTileKey,
    required this.status,
  });

  final String unitId;
  final String unitType;
  final String? pendingTargetTileKey;
  final String? assignedTileKey;
  final ct_models.UnitStatus status;
}
