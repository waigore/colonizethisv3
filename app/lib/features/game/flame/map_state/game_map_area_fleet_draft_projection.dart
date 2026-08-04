import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart';

import 'game_map_area_draft_projection_shared.dart';

/// Fleet-marker draft projection for the human player.
///
/// Extracted from `GameMapAreaStateLogic` (#2575 work item 11) so the
/// fleet projection pipeline lives in a single, separately testable module.
/// `GameMapAreaStateLogic.projectFleetMarkersForHumanDraft` remains as a
/// thin forwarder for backward compatibility with call sites and existing
/// tests. Grayscale and halo flags follow issue #1745 / SPEC/ui/map-widget.md.
class GameMapAreaFleetDraftProjection {
  GameMapAreaFleetDraftProjection._();

  /// Projects fleet marker tiles using human naval move drafts.
  static RegionMapViewData project({
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
        tileKey = GameMapAreaFleetDraftProjectionTiles.destinationTileForMove(
          move: mv,
          fleetRegionId: fleet.regionId,
          game: game,
          tileMapByRegion: tileMapByRegion,
          topologyByRegion: topologyByRegion,
          combinedTopology: combinedTopology,
        );
        tileKey ??= GameMapAreaFleetDraftProjectionTiles.currentTileForFleet(
          fleet: fleet,
          game: game,
          tileMapByRegion: tileMapByRegion,
          topologyByRegion: topologyByRegion,
        );
        locationScopeKey = GameMapAreaFleetDraftProjectionScope.locationScopeForMove(
          move: mv,
          fleetRegionId: fleet.regionId,
          game: game,
          combinedTopology: combinedTopology,
          topologyByRegion: topologyByRegion,
        );
      } else {
        tileKey = GameMapAreaFleetDraftProjectionTiles.currentTileForFleet(
          fleet: fleet,
          game: game,
          tileMapByRegion: tileMapByRegion,
          topologyByRegion: topologyByRegion,
        );
        locationScopeKey =
            GameMapAreaFleetDraftProjectionScope.currentLocationScopeForFleet(
          fleet: fleet,
          game: game,
          combinedTopology: combinedTopology,
          topologyByRegion: topologyByRegion,
        );
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
    GameMapAreaDraftProjectionShared.sortFleetTileMarkersByMapPosition(out);

    return GameMapAreaDraftProjectionShared.copyRegionMapViewDataMarkerLayers(
      region: region,
      fleetTileMarkers: out,
    );
  }
}

class _FleetTileProj {
  _FleetTileProj();

  final Set<String> fleetIds = {};
  final Set<String> locationScopeKeys = {};
  bool anyNavalMoveDraft = false;
}

/// Sea-zone and port location scope keys for fleet draft projection.
abstract final class GameMapAreaFleetDraftProjectionScope {
  static String seaZoneLocalId(String seaZoneId) =>
      prefixedIdLocalSegment(seaZoneId);

  static String destinationRegionForSeaZone({
    required String seaZoneId,
    required String fallbackRegionId,
    required MapTopology combinedTopology,
    required Map<String, MapTopology> topologyByRegion,
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

  static String normalizedSeaScope({
    required String seaZoneId,
    required String fallbackRegionId,
    required MapTopology combinedTopology,
    required Map<String, MapTopology> topologyByRegion,
  }) {
    final regionId = destinationRegionForSeaZone(
      seaZoneId: seaZoneId,
      fallbackRegionId: fallbackRegionId,
      combinedTopology: combinedTopology,
      topologyByRegion: topologyByRegion,
    );
    final local = seaZoneLocalId(seaZoneId);
    return 'sea:$regionId|$local';
  }

  static String locationScopeForMove({
    required ct_models.NavalMoveOrder move,
    required String fleetRegionId,
    required ct_models.Game game,
    required MapTopology combinedTopology,
    required Map<String, MapTopology> topologyByRegion,
  }) {
    if (move.isDock) {
      final pid = move.destinationPortProvinceId!;
      final p = game.worldState.tryGetProvince(pid);
      if (p != null) {
        final localProvinceId = ct_models.ProvinceId.localIdFrom(p.id);
        return 'port:${p.regionId}|$localProvinceId';
      }
      return 'port:$pid';
    }
    return normalizedSeaScope(
      seaZoneId: move.destinationSeaZoneId!,
      fallbackRegionId: fleetRegionId,
      combinedTopology: combinedTopology,
      topologyByRegion: topologyByRegion,
    );
  }

  static String? currentLocationScopeForFleet({
    required ct_models.Fleet fleet,
    required ct_models.Game game,
    required MapTopology combinedTopology,
    required Map<String, MapTopology> topologyByRegion,
  }) {
    if (fleet.isAtSea && fleet.seaZoneId != null) {
      return normalizedSeaScope(
        seaZoneId: fleet.seaZoneId!,
        fallbackRegionId: fleet.regionId,
        combinedTopology: combinedTopology,
        topologyByRegion: topologyByRegion,
      );
    }
    if (fleet.inPortAtProvinceId != null) {
      final p = game.worldState.tryGetProvince(fleet.inPortAtProvinceId!);
      if (p != null) {
        final localProvinceId = ct_models.ProvinceId.localIdFrom(p.id);
        return 'port:${p.regionId}|$localProvinceId';
      }
      return 'port:${fleet.inPortAtProvinceId!}';
    }
    return null;
  }
}

/// Drawable tile keys for fleet draft projection (at-sea and in-port).
abstract final class GameMapAreaFleetDraftProjectionTiles {
  static String? destinationTileForMove({
    required ct_models.NavalMoveOrder move,
    required String fleetRegionId,
    required ct_models.Game game,
    required Map<String, TileMapResult> tileMapByRegion,
    required Map<String, MapTopology> topologyByRegion,
    required MapTopology combinedTopology,
  }) {
    if (move.isDock) {
      final pid = move.destinationPortProvinceId!;
      final p = game.worldState.tryGetProvince(pid);
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
    final destReg = GameMapAreaFleetDraftProjectionScope.destinationRegionForSeaZone(
      seaZoneId: seaId,
      fallbackRegionId: fleetRegionId,
      combinedTopology: combinedTopology,
      topologyByRegion: topologyByRegion,
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
    final local = GameMapAreaFleetDraftProjectionScope.seaZoneLocalId(seaId);
    return seaZoneCentroidTileKey(
      tileMap: tm,
      regionId: destReg,
      localSeaZoneId: local,
      seaZoneNodeIds: seaIds,
    );
  }

  static String? currentTileForFleet({
    required ct_models.Fleet fleet,
    required ct_models.Game game,
    required Map<String, TileMapResult> tileMapByRegion,
    required Map<String, MapTopology> topologyByRegion,
  }) {
    final tm = tileMapByRegion[fleet.regionId];
    final tp = topologyByRegion[fleet.regionId];
    if (tm == null || tp == null) {
      return null;
    }
    final seaIds = {
      for (final n in tp.nodes)
        if (n.type == TopologyNodeType.seaZone) n.id,
    };
    if (fleet.isAtSea && fleet.seaZoneId != null) {
      final z = fleet.seaZoneId!;
      final zoneKey = prefixedIdHasDelimiter(z) ? z : '${fleet.regionId}|$z';
      final local = prefixedIdLocalSegment(zoneKey);
      return seaZoneCentroidTileKey(
        tileMap: tm,
        regionId: fleet.regionId,
        localSeaZoneId: local,
        seaZoneNodeIds: seaIds,
      );
    }
    if (fleet.inPortAtProvinceId != null) {
      final p = game.worldState.tryGetProvince(fleet.inPortAtProvinceId!);
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
}
