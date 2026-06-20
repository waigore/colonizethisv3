// Map marker helpers for [init_game_map_view_builder.dart]:
// fleet tile markers plus capital/port/town/warp/sea-zone markers.

part of 'init_game_map_view_builder.dart';

String _homeFleetIdForMapMarker(String playerId) => 'fleet_$playerId';

bool _fleetAtHumanCapital(Game game, String playerId, Fleet fleet) {
  if (!fleet.isInPort || fleet.inPortAtProvinceId == null) {
    return false;
  }
  final player = game.players.firstWhere(
    (p) => p.id == playerId,
    orElse: () => game.players.first,
  );
  if (!player.isHuman) {
    return false;
  }
  final cap = player.capitalTile;
  if (cap == null) {
    return false;
  }
  final parsed = tryParseMapTileKey(cap.toTileKey());
  if (parsed == null) {
    return false;
  }
  final capReg = parsed.regionId;
  final capProvLocal = parsed.localId;
  if (fleet.regionId != capReg) {
    return false;
  }
  final port = fleet.inPortAtProvinceId!;
  return port == capProvLocal || port == '$capReg|$capProvLocal';
}

bool _includeFleetForTileMarker(
  Game game,
  Fleet f,
  String regionId,
  Set<String> humanIds,
) {
  if (!humanIds.contains(f.ownerId) || f.regionId != regionId) {
    return false;
  }
  if (f.shipTypeIds.isNotEmpty) {
    return true;
  }
  return f.id == _homeFleetIdForMapMarker(f.ownerId) &&
      _fleetAtHumanCapital(game, f.ownerId, f);
}

String? _inPortFleetMarkerTileKey({
  required Game game,
  required String regionId,
  required Province province,
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
}) {
  final localProvinceId = ProvinceId.localIdFrom(province.id);
  final tileKey = harborDrawableSeaTileKeyForPortProvince(
    game: game,
    regionId: regionId,
    localProvinceId: localProvinceId,
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
    contextLabel: 'fleet marker region=$regionId province=$localProvinceId',
  );
  if (tileKey == null) {
    _log.w(
      'map: in-port fleet marker skipped: no portsByProvinceSeaboard entry '
      'for region=$regionId province=$localProvinceId',
    );
  }
  return tileKey;
}

(int?, int?) _xyFromMapTileKey(String tileKey) {
  final parsed = tryParseMapTileKeySuffixXY(tileKey);
  if (parsed == null) {
    return (null, null);
  }
  return (parsed.x, parsed.y);
}

String? _fleetMarkerTileKeyForLocationScope({
  required String scopeKey,
  required String regionId,
  required Game game,
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
  required Map<String, Province> provinceMap,
}) {
  if (scopeKey.startsWith('sea:')) {
    final zoneKey = scopeKey.substring(4);
    final local = mapPipeLastSegmentOrWhole(zoneKey);
    return seaZoneCentroidTileKey(
      tileMap: tileMap,
      regionId: regionId,
      localSeaZoneId: local,
      seaZoneNodeIds: seaZoneIds,
    );
  }
  if (!scopeKey.startsWith('port:')) return null;
  final fullProv = scopeKey.substring(5);
  final province = provinceMap[fullProv];
  if (province == null) return null;
  return _inPortFleetMarkerTileKey(
    game: game,
    regionId: regionId,
    province: province,
    tileMap: tileMap,
    seaZoneIds: seaZoneIds,
  );
}

void _addFleetToLocationBuckets({
  required Fleet f,
  required String regionId,
  required Map<String, Province> provinceMap,
  required Map<String, List<Fleet>> byLocation,
}) {
  if (f.isAtSea && f.seaZoneId != null) {
    final z = f.seaZoneId!;
    final zoneKey = z.contains('|') ? z : '$regionId|$z';
    byLocation.putIfAbsent('sea:$zoneKey', () => []).add(f);
    return;
  }
  if (f.inPortAtProvinceId == null) return;
  final province =
      provinceMap['$regionId|${f.inPortAtProvinceId}'] ??
      provinceMap[f.inPortAtProvinceId!];
  if (province == null) return;
  byLocation
      .putIfAbsent('port:${province.regionId}|${province.id}', () => [])
      .add(f);
}

List<FleetTileMarkerView> _buildFleetTileMarkersForRegion({
  required Game game,
  required String regionId,
  required List<Province> provinces,
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
}) {
  final humanIds = game.players
      .where((p) => p.isHuman)
      .map((p) => p.id)
      .toSet();
  if (humanIds.isEmpty) {
    return const [];
  }

  final provinceMap = <String, Province>{
    for (final p in provinces) ...{'${p.regionId}|${p.id}': p, p.id: p},
  };

  final byLocation = <String, List<Fleet>>{};

  for (final f in game.worldState.fleets) {
    if (!_includeFleetForTileMarker(game, f, regionId, humanIds)) {
      continue;
    }
    _addFleetToLocationBuckets(
      f: f,
      regionId: regionId,
      provinceMap: provinceMap,
      byLocation: byLocation,
    );
  }

  final markers = <FleetTileMarkerView>[];
  for (final entry in byLocation.entries) {
    final scopeKey = entry.key;
    final fleets = entry.value.toList()..sort((a, b) => a.id.compareTo(b.id));
    final fleetIds = fleets.map((fl) => fl.id).toList();

    final tileKey = _fleetMarkerTileKeyForLocationScope(
      scopeKey: scopeKey,
      regionId: regionId,
      game: game,
      tileMap: tileMap,
      seaZoneIds: seaZoneIds,
      provinceMap: provinceMap,
    );
    if (tileKey == null) {
      continue;
    }
    final xy = _xyFromMapTileKey(tileKey);
    final x = xy.$1;
    final y = xy.$2;
    if (x == null || y == null) {
      continue;
    }
    markers.add(
      FleetTileMarkerView(
        tileKey: tileKey,
        x: x,
        y: y,
        locationScopeKey: scopeKey,
        fleetIds: fleetIds,
        stackCount: fleetIds.length,
      ),
    );
  }
  markers.sort((a, b) {
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
  return markers;
}

List<CapitalMarkerView> _buildCapitalMarkers({
  required Game game,
  required String regionId,
}) {
  return [
    for (final marker in collectCapitalMarkersForRegion(
      game: game,
      regionId: regionId,
      scope: TileMapCapitalMarkerScope.allFactions,
    ))
      CapitalMarkerView(
        factionId: marker.factionId,
        displayName: marker.displayName,
        x: marker.x,
        y: marker.y,
      ),
  ];
}

List<PortMarkerView> _buildPortMarkers({
  required String regionId,
  required Map<String, String> portsByProvinceSeaboard,
}) {
  final ports = <PortMarkerView>[];
  portsByProvinceSeaboard.forEach((key, tileKey) {
    final parsed = tryParseMapTileKey(tileKey);
    if (parsed == null || parsed.regionId != regionId) {
      return;
    }
    final fromKey = localProvinceIdFromPortsSeaboardKey(key, regionId);
    final provinceIdForMarker = fromKey ?? parsed.localId;
    ports.add(
      PortMarkerView(
        x: parsed.x,
        y: parsed.y,
        provinceId: provinceIdForMarker,
        seaZoneId: '',
        seaboardKey: key,
      ),
    );
  });
  return ports;
}

Set<String> _buildCoastalProvinceIds({
  required MapTopology topology,
  required Set<String> seaZoneIds,
}) {
  final coastalProvinceIds = <String>{};
  for (final edge in topology.edges) {
    final id1Sea = seaZoneIds.contains(edge.id1);
    final id2Sea = seaZoneIds.contains(edge.id2);
    if ((id1Sea && !id2Sea) || (!id1Sea && id2Sea)) {
      coastalProvinceIds.add(id1Sea ? edge.id2 : edge.id1);
    }
  }
  return coastalProvinceIds;
}

List<TownMarkerView> _buildTownMarkers({
  required Game game,
  required String regionId,
  required List<Province> provinces,
  required List<PortMarkerView> ports,
  required Set<String> coastalProvinceIds,
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
}) {
  final towns = <TownMarkerView>[];
  final portProvinceIds = ports.map((p) => p.provinceId).toSet();
  for (final p in provinces) {
    final townTileKey = p.townTileKey;
    if (townTileKey == null || townTileKey.isEmpty) {
      continue;
    }
    final parsed = tryParseMapTileKey(townTileKey);
    if (parsed == null || parsed.regionId != regionId) {
      continue;
    }
    final localProvinceId = ProvinceId.localIdFrom(p.id);
    final hasPort = portProvinceIds.contains(localProvinceId);
    final portTileKey = hasPort
        ? portLandTileKeyForProvinceInRegion(game, regionId, localProvinceId)
        : null;
    int? portIconX;
    int? portIconY;
    if (hasPort && portTileKey != null) {
      final placed = computePortDrawableSeaCellForMap(
        tileMap: tileMap,
        seaZoneIds: seaZoneIds,
        portTileKey: portTileKey,
        contextLabel:
            'region=$regionId province=$localProvinceId harbor sprite',
      );
      portIconX = placed.x;
      portIconY = placed.y;
    }
    final touchesSea = coastalProvinceIds.contains(localProvinceId);
    towns.add(
      TownMarkerView(
        x: parsed.x,
        y: parsed.y,
        provinceId: localProvinceId,
        isCoastal: touchesSea && !hasPort,
        isPort: hasPort,
        touchesSea: touchesSea,
        portIconX: portIconX,
        portIconY: portIconY,
      ),
    );
  }
  return towns;
}

Map<String, (int x, int y)> _buildSeaZoneToRepresentativeTile({
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
}) {
  final seaZoneToTile = <String, (int x, int y)>{};
  TileMapGrid.forEachIndex(tileMap.height, tileMap.width, (y, x) {
    final localId = tileMap.cell(x, y);
    if (!seaZoneIds.contains(localId)) {
      return;
    }
    seaZoneToTile.putIfAbsent(localId, () => (x, y));
  });
  return seaZoneToTile;
}

List<WarpMarkerView> _buildWarpMarkers({
  required String regionId,
  required Map<String, (int x, int y)> seaZoneToTile,
  required List<WarpLink>? warpLinks,
}) {
  final warpMarkers = <WarpMarkerView>[];
  if (warpLinks == null) {
    return warpMarkers;
  }
  for (final link in warpLinks) {
    if (link.regionId == regionId) {
      final tile = seaZoneToTile[link.seaZoneId];
      if (tile == null) {
        continue;
      }
      warpMarkers.add(
        WarpMarkerView(
          x: tile.$1,
          y: tile.$2,
          seaZoneId: link.seaZoneId,
          otherRegionId: link.otherRegionId,
          otherSeaZoneId: link.otherSeaZoneId,
        ),
      );
      continue;
    }
    if (link.otherRegionId != regionId) {
      continue;
    }
    final tile = seaZoneToTile[link.otherSeaZoneId];
    if (tile == null) {
      continue;
    }
    warpMarkers.add(
      WarpMarkerView(
        x: tile.$1,
        y: tile.$2,
        seaZoneId: link.otherSeaZoneId,
        otherRegionId: link.regionId,
        otherSeaZoneId: link.seaZoneId,
      ),
    );
  }
  return warpMarkers;
}

void _applyInPortFleetShipCounts({
  required List<Fleet> fleets,
  required String regionId,
  required Map<String, ProvinceUnitPresenceView> provincePresenceById,
}) {
  for (final fleet in fleets) {
    if (fleet.regionId != regionId || !fleet.isInPort) {
      continue;
    }
    final provinceId = fleet.inPortAtProvinceId;
    if (provinceId == null) {
      continue;
    }
    final current = provincePresenceById[provinceId];
    if (current == null) {
      continue;
    }
    provincePresenceById[provinceId] = ProvinceUnitPresenceView(
      civilianCount: current.civilianCount,
      regimentCount: current.regimentCount,
      shipCount: current.shipCount + fleet.ships.length,
      intelVisible: current.intelVisible,
    );
  }
}
