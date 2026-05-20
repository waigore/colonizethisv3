import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart';

import 'per_player_work_target_selection_cache.dart';

/// Pure-ish helpers for `GameMapArea` state translation.
class GameMapAreaStateLogic {
  /// Full turn resolution is a no-op once military [Game.victory] is set or the
  /// campaign calendar cap has been reached ([Game.calendarCampaignHalted]).
  /// SPEC/game/victory.md § UI blocking.
  static bool allowsFullTurnResolution(ct_models.Game game) {
    return !game.calendarCampaignHalted && game.victory == null;
  }

  static const ({bool showIcon, bool enabled, bool hasExplorerUnits})
  kHiddenExplorerInlineActionState = (
    showIcon: false,
    enabled: false,
    hasExplorerUnits: false,
  );
  static const ({bool showIcon, bool enabled, bool hasBuilderUnits})
  kHiddenBuilderInlineActionState = (
    showIcon: false,
    enabled: false,
    hasBuilderUnits: false,
  );

  static int regionIndexFromWorldRegionId(String regionId) {
    if (regionId == 'newWorld') return 1;
    return 0; // oldWorld (default)
  }

  /// Work-target tile translation hook for assignment flows.
  ///
  /// Civilian draft projection and locate use exact assigned tile keys for every
  /// work target, so no target-specific tile normalization is applied here.
  static String translateWorkTargetTileKey({
    required String tileKey,
    required String workTarget,
  }) {
    if (workTarget.isEmpty) return tileKey;
    return tileKey;
  }

  static const Set<String> kCacheFirstWorkTargets = {
    kWorkTargetExplore,
    kWorkTargetStealTech,
    kWorkTargetCounterSpy,
    kWorkTargetPurchaseLand,
    kWorkTargetProspect,
    kWorkTargetBuildImprovement,
    kWorkTargetUpgradeTown,
    kWorkTargetBuildRoad,
    kWorkTargetBuildPort,
    kWorkTargetBuildFort,
    kWorkTargetBuildRail,
  };

  static const Set<String> _runtimeConflictProtectedCacheTargets = {
    kWorkTargetExplore,
    kWorkTargetStealTech,
    kWorkTargetCounterSpy,
    kWorkTargetPurchaseLand,
    kWorkTargetProspect,
    kWorkTargetBuildImprovement,
    kWorkTargetUpgradeTown,
    kWorkTargetBuildRoad,
    kWorkTargetBuildPort,
    kWorkTargetBuildFort,
    kWorkTargetBuildRail,
  };

  /// Filters stale conflict tiles from app-cached work-target selections.
  ///
  /// This is a post-cache set-subtraction guard only: it does not recompute
  /// valid tiles and applies only to targets that use worker-family stale-tile
  /// protection.
  static Set<String> filterCacheSelectionForRuntimeStaleTileConflicts({
    required Set<String> cachedTileKeys,
    required ct_models.Game game,
    required ct_models.Orders currentOrders,
    required String playerId,
    required String selectedUnitId,
    required String workTarget,
  }) {
    if (cachedTileKeys.isEmpty ||
        !_runtimeConflictProtectedCacheTargets.contains(workTarget)) {
      return cachedTileKeys;
    }
    final conflicting = <String>{};
    final pending = currentOrders.workOrdersByPlayerId[playerId] ?? const [];
    for (final order in pending) {
      if (order.targetTileKey.isEmpty || order.unitId == selectedUnitId) {
        continue;
      }
      if (!_runtimeConflictProtectedCacheTargets.contains(order.target)) {
        continue;
      }
      conflicting.add(order.targetTileKey);
    }
    for (final unit in [
      ...game.worldState.oldWorld.units,
      ...game.worldState.newWorld.units,
    ]) {
      if (unit.ownerId != playerId || unit.id == selectedUnitId) {
        continue;
      }
      final currentWork = unit.currentWork;
      if (currentWork == null || currentWork.tileKey.isEmpty) {
        continue;
      }
      if (!_runtimeConflictProtectedCacheTargets.contains(
        currentWork.workTarget,
      )) {
        continue;
      }
      conflicting.add(currentWork.tileKey);
    }
    if (conflicting.isEmpty) {
      return cachedTileKeys;
    }
    return cachedTileKeys.difference(conflicting);
  }

  /// Resolves selectable work-target tile keys for the civilian map picker.
  ///
  /// [kCacheFirstWorkTargets] read from [workTargetSelectionCache] only (no
  /// live `getValidWorkOrderTileKeysWithVisibility` fallback in that path).
  static Set<String> resolveValidTileKeysForCivilianWorkSelection({
    required String workTarget,
    required PerPlayerWorkTargetSelectionCache workTargetSelectionCache,
    required String humanPlayerId,
    required String selectedUnitId,
    required ct_models.Game game,
    required ct_models.Orders currentOrders,
    required PlayerView playerView,
    required MapTopology topology,
    required Map<String, TileMapResult>? tileMapByRegion,
  }) {
    if (kCacheFirstWorkTargets.contains(workTarget)) {
      return filterCacheSelectionForRuntimeStaleTileConflicts(
        cachedTileKeys: workTargetSelectionCache.get(humanPlayerId, workTarget),
        game: game,
        currentOrders: currentOrders,
        playerId: humanPlayerId,
        selectedUnitId: selectedUnitId,
        workTarget: workTarget,
      );
    }
    return getValidWorkOrderTileKeysWithVisibility(
      game: game,
      topology: topology,
      view: playerView,
      unitId: selectedUnitId,
      workTarget: workTarget,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
    );
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
    final pendingByUnitId = <String, String>{};
    final pending = orders.workOrdersByPlayerId[humanPlayerId] ?? const [];
    for (final order in pending) {
      final target = order.targetTileKey;
      if (target.isEmpty) continue;
      pendingByUnitId[order.unitId] = target;
    }

    final civilianUnitIdsToProject = <String>{
      ...pendingByUnitId.keys,
      for (final marker in region.civilianTileMarkers)
        for (final unitId in marker.unitIds) unitId,
    };
    if (civilianUnitIdsToProject.isEmpty) {
      return region;
    }

    final unitsById = <String, ct_models.Unit>{
      for (final u in game.worldState.oldWorld.units)
        if (u.ownerId == humanPlayerId && _isCivilianUnitType(u.type)) u.id: u,
      for (final u in game.worldState.newWorld.units)
        if (u.ownerId == humanPlayerId && _isCivilianUnitType(u.type)) u.id: u,
    };
    if (unitsById.isEmpty) {
      return region;
    }
    final visibilityByTile =
        game.worldState.playerVisibilityByTile[humanPlayerId] ??
        const <String, String>{};

    final projectedByTile = <String, List<_ProjectedCivilianUnit>>{};
    for (final unitId in civilianUnitIdsToProject) {
      final unit = unitsById[unitId];
      if (unit == null) continue;
      final projectedTile =
          projectedCivilianTileKey(
            unit: unit,
            playerId: humanPlayerId,
            orders: orders,
          ) ??
          unit.tileKey;
      if (projectedTile == null || projectedTile.isEmpty) continue;
      final parsed = tryParseTileKey(projectedTile);
      if (parsed == null || parsed.regionId != region.regionId) continue;
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
    if (projectedByTile.isEmpty) {
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
        civilianTileMarkers: const [],
        fleetTileMarkers: region.fleetTileMarkers,
        warpMarkers: region.warpMarkers,
        townMarkers: region.townMarkers,
        provinceUnitPresenceByProvinceId:
            region.provinceUnitPresenceByProvinceId,
        provincePoliticalOwnerByPrefixedProvinceId:
            region.provincePoliticalOwnerByPrefixedProvinceId,
        seaZoneDisplayNameByPrefixedId: region.seaZoneDisplayNameByPrefixedId,
      );
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
      final parsed = tryParseTileKey(tileKey);
      if (parsed == null) continue;
      final x = parsed.x;
      final y = parsed.y;
      final representative = units.first;
      final representativeIsAssigned =
          representative.pendingTargetTileKey == tileKey ||
          (representative.assignedTileKey == tileKey &&
              representative.status == ct_models.UnitStatus.working);
      final applyCivilianRevealHalo = units.any((u) {
        final isAssignedToTile =
            u.pendingTargetTileKey == tileKey ||
            (u.assignedTileKey == tileKey &&
                u.status == ct_models.UnitStatus.working);
        if (!isAssignedToTile) return false;
        return visibilityByTile[tileKey] == VisibilityLevel.fogged.name;
      });
      projectedMarkers.add(
        CivilianTileMarkerView(
          tileKey: tileKey,
          x: x,
          y: y,
          localProvinceId: parsed.provinceLocalId,
          unitIds: units.map((u) => u.unitId).toList(),
          unitTypes: {for (final u in units) u.unitId: u.unitType},
          representativeUnitType: representative.unitType,
          stackCount: units.length,
          representativeIsAssigned: representativeIsAssigned,
          applyCivilianRevealHalo: applyCivilianRevealHalo,
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

    ct_models.Fleet? lookupFleet(String fleetId) => game.fleetById(fleetId);

    String seaZoneLocalId(String seaZoneId) => prefixedIdLocalSegment(seaZoneId);

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
        final zoneKey = prefixedIdHasDelimiter(z) ? z : '${f.regionId}|$z';
        final local = prefixedIdLocalSegment(zoneKey);
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
      final fleet = lookupFleet(fleetId);
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
      if (!isTileKeyInRegion(tileKey, region.regionId)) {
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
      final parsed = tryParseTileKey(tk);
      if (parsed == null) {
        continue;
      }
      final x = parsed.x;
      final y = parsed.y;
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

  /// Civilian and fleet draft marker projection for one [RegionMapViewData].
  static RegionMapViewData projectHumanDraftMarkersForRegion({
    required RegionMapViewData baseRegion,
    required ct_models.Game game,
    required ct_models.Orders orders,
    required String humanPlayerId,
    Map<String, TileMapResult>? tileMapByRegion,
    Map<String, MapTopology>? topologyByRegion,
    MapTopology? combinedTopology,
  }) {
    var projected = projectCivilianMarkersForHumanDraft(
      region: baseRegion,
      game: game,
      orders: orders,
      humanPlayerId: humanPlayerId,
    );
    if (tileMapByRegion != null &&
        topologyByRegion != null &&
        combinedTopology != null) {
      projected = projectFleetMarkersForHumanDraft(
        region: projected,
        game: game,
        orders: orders,
        humanPlayerId: humanPlayerId,
        tileMapByRegion: tileMapByRegion,
        topologyByRegion: topologyByRegion,
        combinedTopology: combinedTopology,
      );
    }
    return projected;
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
    final parsed = tryParseTileKey(selectedTileKey);
    if (parsed == null) {
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }
    final tileVisibility = playerView.visibilityForTile(selectedTileKey);
    if (tileVisibility == VisibilityLevel.unknown) {
      return (showIcon: false, enabled: false, hasExplorerUnits: false);
    }
    final prefixedProvinceId = parsed.prefixedProvinceId;
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

  static Set<String> buildExploreEligibleTileKeyCache({
    required ct_models.Game game,
    required String humanPlayerId,
    required PlayerView playerView,
    required MapTopology topology,
    required Map<String, TileMapResult>? tileMapByRegion,
    required ct_models.Orders currentOrders,
  }) {
    final cache = PerPlayerWorkTargetSelectionCache();
    cache.refresh(
      WorkTargetSelectionSnapshot(
        game: game,
        playerId: humanPlayerId,
        playerView: playerView,
        topology: topology,
        currentOrders: currentOrders,
        tileMapByRegion: tileMapByRegion,
      ),
    );
    return cache.get(humanPlayerId, kWorkTargetExplore);
  }

  static ({bool showIcon, bool enabled, bool hasExplorerUnits})
  provinceExploreActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required RegionMapViewData selectedRegion,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    Set<String>? cachedExploreEligibleTileKeys,
  }) {
    final parsed = tryParseTileKey(selectedTileKey);
    if (parsed == null || parsed.regionId != selectedRegion.regionId) {
      return kHiddenExplorerInlineActionState;
    }
    final tileProvinceId = parsed.provinceLocalId;
    final prefixedProvinceId = parsed.prefixedProvinceId;
    final province = tryGetProvince(game.worldState, prefixedProvinceId);
    if (province == null) {
      return kHiddenExplorerInlineActionState;
    }

    final x = parsed.x;
    final y = parsed.y;
    if (x < 0 ||
        y < 0 ||
        x >= selectedRegion.width ||
        y >= selectedRegion.height) {
      return kHiddenExplorerInlineActionState;
    }
    final selectedCell = selectedRegion.cellAt(x, y);
    if (selectedCell.visibility == TileVisibility.unrevealed) {
      return kHiddenExplorerInlineActionState;
    }

    final provinceCells = selectedRegion.cells
        .where((cell) => !cell.isSea && cell.regionCellId == tileProvinceId)
        .toList();
    if (provinceCells.isEmpty) {
      return kHiddenExplorerInlineActionState;
    }
    final hasUnrevealed = provinceCells.any(
      (cell) => cell.visibility == TileVisibility.unrevealed,
    );
    final hasRevealed = provinceCells.any(
      (cell) => cell.visibility != TileVisibility.unrevealed,
    );
    if (!hasUnrevealed || !hasRevealed) {
      return kHiddenExplorerInlineActionState;
    }

    final eligibleTileKeys =
        cachedExploreEligibleTileKeys ??
        workTargetSelectionCache?.get(humanPlayerId, kWorkTargetExplore) ??
        const <String>{};
    final hasEligibleExploreTarget = eligibleTileKeys.any((tileKey) {
      final p = tryParseTileKey(tileKey);
      return p != null &&
          p.regionId == selectedRegion.regionId &&
          p.provinceLocalId == tileProvinceId;
    });
    if (!hasEligibleExploreTarget) {
      return kHiddenExplorerInlineActionState;
    }

    final allUnits = <ct_models.Unit>[
      ...game.worldState.oldWorld.units,
      ...game.worldState.newWorld.units,
    ];
    final hasExplorerUnits = allUnits
        .where((unit) => unit.ownerId == humanPlayerId)
        .any(
          (unit) =>
              workOrderTargetsByUnitType[unit.type]?.contains(
                kWorkTargetExplore,
              ) ??
              false,
        );
    return (
      showIcon: true,
      enabled: hasExplorerUnits,
      hasExplorerUnits: hasExplorerUnits,
    );
  }

  static ({bool showIcon, bool enabled, bool hasBuilderUnits})
  provinceBuildImprovementActionState({
    required ct_models.Game game,
    required String humanPlayerId,
    required String selectedTileKey,
    required PlayerView playerView,
    PerPlayerWorkTargetSelectionCache? workTargetSelectionCache,
    MapTopology? topology,
    ct_models.Orders currentOrders = const ct_models.Orders(),
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final parsed = tryParseTileKey(selectedTileKey);
    if (parsed == null) {
      return kHiddenBuilderInlineActionState;
    }
    final tileVisibility = playerView.visibilityForTile(selectedTileKey);
    if (tileVisibility == VisibilityLevel.unknown) {
      return kHiddenBuilderInlineActionState;
    }
    final tileProvinceId = parsed.provinceLocalId;
    final prefixedProvinceId = parsed.prefixedProvinceId;
    final isProvinceTile =
        tryGetProvince(game.worldState, prefixedProvinceId) != null;
    if (!isProvinceTile) {
      return kHiddenBuilderInlineActionState;
    }
    ct_models.Player? player;
    for (final p in game.players) {
      if (p.id == humanPlayerId) {
        player = p;
        break;
      }
    }
    if (player == null) {
      return kHiddenBuilderInlineActionState;
    }

    final resourceId = game.worldState.resourceByTileKey[selectedTileKey];
    if (resourceId == null || resourceId.isEmpty) {
      return kHiddenBuilderInlineActionState;
    }
    final currentLevel = game.worldState.tileState.improvementLevel(
      selectedTileKey,
    );
    final techCap = extractionCapForResourceForUnlocked(
      player.techUnlocked,
      resourceId,
    );
    if (currentLevel >= techCap) {
      return kHiddenBuilderInlineActionState;
    }

    final allUnits = <ct_models.Unit>[
      ...game.worldState.oldWorld.units,
      ...game.worldState.newWorld.units,
    ];
    final builderUnits = allUnits
        .where((unit) => unit.ownerId == humanPlayerId)
        .where(
          (unit) =>
              workOrderTargetsByUnitType[unit.type]?.contains(
                kWorkTargetBuildImprovement,
              ) ??
              false,
        )
        .toList();
    if (builderUnits.isEmpty) {
      return (showIcon: true, enabled: false, hasBuilderUnits: false);
    }
    final anyAssignable =
        workTargetSelectionCache?.contains(
          humanPlayerId,
          kWorkTargetBuildImprovement,
          selectedTileKey,
        ) ??
        (topology == null
            ? false
            : builderUnits.any((builder) {
                final valid = getValidWorkOrderTileKeysWithVisibility(
                  game: game,
                  topology: topology,
                  view: playerView,
                  unitId: builder.id,
                  workTarget: kWorkTargetBuildImprovement,
                  currentOrders: currentOrders,
                  tileMapByRegion: tileMapByRegion,
                );
                return valid.contains(selectedTileKey);
              }));
    return (showIcon: true, enabled: anyAssignable, hasBuilderUnits: true);
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
