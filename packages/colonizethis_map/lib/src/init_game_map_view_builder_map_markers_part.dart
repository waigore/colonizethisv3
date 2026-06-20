part of 'init_game_map_view_builder.dart';

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
  for (var y = 0; y < tileMap.height; y++) {
    for (var x = 0; x < tileMap.width; x++) {
      final localId = tileMap.cell(x, y);
      if (!seaZoneIds.contains(localId)) {
        continue;
      }
      seaZoneToTile.putIfAbsent(localId, () => (x, y));
    }
  }
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
