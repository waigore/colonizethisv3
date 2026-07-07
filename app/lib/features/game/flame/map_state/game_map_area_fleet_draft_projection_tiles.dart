part of 'game_map_area_fleet_draft_projection.dart';

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
