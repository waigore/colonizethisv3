part of 'init_game_map_view_builder.dart';

List<CellViewData> _buildCellViewDataList({
  required String regionId,
  required TileMapResult tileMap,
  required Set<String> seaZoneIds,
  required TileMapState tileState,
  required Map<String, String> ownerByProvinceId,
  required Map<String, String> provinceDisplayNameById,
  required Map<String, TileVisibility>? visibilityByTile,
  required Map<String, int>? resourceExtractionUnitsByTile,
  required Map<String, int>? resourceExtractionEffectiveUnitsByTile,
  required Map<String, int>? resourceExtractionBlockedUnitsByTile,
}) {
  final cells = <CellViewData>[];
  for (var y = 0; y < tileMap.height; y++) {
    for (var x = 0; x < tileMap.width; x++) {
      final localId = tileMap.cell(x, y);
      final isSea = seaZoneIds.contains(localId);
      final terrain = tileMap.terrainAt(x, y);
      final resource = tileMap.resourceAt(x, y);
      final tileKey = '$regionId|$localId|$x|$y';
      final improvement = isSea ? null : tileState.improvementLevel(tileKey);
      final road = isSea ? null : tileState.roadLevel(tileKey);
      final visibility = visibilityByTile != null
          ? (visibilityByTile[tileKey] ?? TileVisibility.visible)
          : TileVisibility.visible;
      final extractionUnits = isSea
          ? null
          : resourceExtractionUnitsByTile?[tileKey];
      final extractionEffectiveUnits = isSea
          ? null
          : resourceExtractionEffectiveUnitsByTile?[tileKey];
      final extractionBlockedUnits = isSea
          ? null
          : resourceExtractionBlockedUnitsByTile?[tileKey];
      final fullProvinceId = isSea ? null : ProvinceId.full(regionId, localId);
      cells.add(
        CellViewData(
          x: x,
          y: y,
          regionCellId: localId,
          isSea: isSea,
          terrainTypeId: terrain?.name,
          terrainType: terrain,
          resourceId: resource?.name,
          ownerFactionId: fullProvinceId != null
              ? ownerByProvinceId[fullProvinceId]
              : null,
          provinceDisplayName: isSea
              ? null
              : (fullProvinceId != null
                    ? provinceDisplayNameById[fullProvinceId]
                    : null),
          improvementLevel: isSea ? null : improvement,
          roadLevel: isSea ? null : road,
          resourceExtractionUnits: extractionUnits,
          resourceExtractionEffectiveUnits: extractionEffectiveUnits,
          resourceExtractionBlockedUnits: extractionBlockedUnits,
          visibility: visibility,
        ),
      );
    }
  }
  return cells;
}

List<CapitalMarkerView> _buildCapitalMarkers({
  required Game game,
  required String regionId,
}) {
  final capitals = <CapitalMarkerView>[];
  for (final p in game.players) {
    final cap = p.capitalTile;
    if (cap != null && cap.regionId == regionId) {
      capitals.add(
        CapitalMarkerView(
          factionId: p.id,
          displayName: p.displayName,
          x: cap.x,
          y: cap.y,
        ),
      );
    }
  }
  for (final m in game.minorNations) {
    final cap = m.capitalTile;
    if (cap != null && cap.regionId == regionId) {
      capitals.add(
        CapitalMarkerView(
          factionId: m.id,
          displayName: m.displayName ?? m.id,
          x: cap.x,
          y: cap.y,
        ),
      );
    }
  }
  for (final t in game.tribes) {
    final cap = t.capitalTile;
    if (cap != null && cap.regionId == regionId) {
      capitals.add(
        CapitalMarkerView(
          factionId: t.id,
          displayName: t.displayName ?? t.id,
          x: cap.x,
          y: cap.y,
        ),
      );
    }
  }
  return capitals;
}

Map<String, (int x, int y)> _buildProvinceToRepresentativeTile({
  required TileMapResult tileMap,
  required String regionId,
  required Set<String> seaZoneIds,
}) {
  final provinceToTile = <String, (int x, int y)>{};
  for (var y = 0; y < tileMap.height; y++) {
    for (var x = 0; x < tileMap.width; x++) {
      final localId = tileMap.cell(x, y);
      if (seaZoneIds.contains(localId)) {
        continue;
      }
      final fullProvinceId = ProvinceId.full(regionId, localId);
      provinceToTile.putIfAbsent(fullProvinceId, () => (x, y));
    }
  }
  return provinceToTile;
}

({
  List<UnitMarkerView> unitMarkers,
  List<CivilianTileMarkerView> civilianTileMarkers,
  Map<String, ProvinceUnitPresenceView> provincePresenceById,
})
_buildUnitAndCivilianMarkerData({
  required Game game,
  required String regionId,
  required bool isOldWorld,
  required List<Province> provinces,
  required List<CellViewData> cells,
  required Map<String, (int x, int y)> provinceToTile,
}) {
  final unitMarkers = <UnitMarkerView>[];
  final civilianUnitsByTileKey = <String, List<Unit>>{};
  final playerOwnedCivilianTileMarkers = <CivilianTileMarkerView>[];
  final humanPlayerIds = game.players
      .where((player) => player.isHuman)
      .map((player) => player.id)
      .toSet();
  final provincePresenceById = <String, ProvinceUnitPresenceView>{};
  for (final p in provinces) {
    provincePresenceById[p.id] = const ProvinceUnitPresenceView(
      civilianCount: 0,
      regimentCount: 0,
      shipCount: 0,
      intelVisible: false,
    );
  }

  for (final cell in cells) {
    if (cell.isSea || cell.visibility != TileVisibility.visible) {
      continue;
    }
    final fullProvinceId = ProvinceId.full(regionId, cell.regionCellId);
    final current = provincePresenceById[fullProvinceId];
    if (current == null) {
      continue;
    }
    provincePresenceById[fullProvinceId] = ProvinceUnitPresenceView(
      civilianCount: current.civilianCount,
      regimentCount: current.regimentCount,
      shipCount: current.shipCount,
      intelVisible: true,
    );
  }

  final regionUnits = isOldWorld
      ? game.worldState.oldWorld.units
      : game.worldState.newWorld.units;
  for (final u in regionUnits) {
    final isPlayerOwnedCivilian =
        humanPlayerIds.contains(u.ownerId) && _isCivilianUnitType(u.type);
    if (isPlayerOwnedCivilian) {
      _addCivilianUnitToTileKeyBucket(
        unit: u,
        regionId: regionId,
        civilianUnitsByTileKey: civilianUnitsByTileKey,
      );
    }

    final tile = provinceToTile[u.locationProvinceId];
    if (tile != null) {
      unitMarkers.add(
        UnitMarkerView(x: tile.$1, y: tile.$2, ownerFactionId: u.ownerId),
      );
    }

    final current = provincePresenceById[u.locationProvinceId];
    if (current == null) {
      continue;
    }
    final isRegiment = isMilitaryUnit(u.type);
    provincePresenceById[u.locationProvinceId] = ProvinceUnitPresenceView(
      civilianCount: current.civilianCount + (isRegiment ? 0 : 1),
      regimentCount: current.regimentCount + (isRegiment ? 1 : 0),
      shipCount: current.shipCount,
      intelVisible: current.intelVisible,
    );
  }

  for (final entry in civilianUnitsByTileKey.entries) {
    final tileKey = entry.key;
    final units = entry.value.toList()
      ..sort((a, b) {
        final priorityCompare = _civilianIconPriorityForType(
          a.type,
        ).compareTo(_civilianIconPriorityForType(b.type));
        if (priorityCompare != 0) {
          return priorityCompare;
        }
        return a.id.compareTo(b.id);
      });
    final parts = tileKey.split('|');
    if (parts.length < 4) {
      continue;
    }
    final x = int.tryParse(parts[2]);
    final y = int.tryParse(parts[3]);
    if (x == null || y == null) {
      continue;
    }
    final representativeUnit = units.first;
    final representativeIsAssigned =
        representativeUnit.assignedTileKey == tileKey &&
        representativeUnit.status == UnitStatus.working;
    playerOwnedCivilianTileMarkers.add(
      CivilianTileMarkerView(
        tileKey: tileKey,
        x: x,
        y: y,
        localProvinceId: parts[1],
        unitIds: units.map((unit) => unit.id).toList(),
        unitTypes: {for (final unit in units) unit.id: unit.type},
        representativeUnitType: representativeUnit.type,
        stackCount: units.length,
        representativeIsAssigned: representativeIsAssigned,
      ),
    );
  }
  playerOwnedCivilianTileMarkers.sort((a, b) {
    final yCompare = a.y.compareTo(b.y);
    if (yCompare != 0) {
      return yCompare;
    }
    final xCompare = a.x.compareTo(b.x);
    if (xCompare != 0) {
      return xCompare;
    }
    return a.tileKey.compareTo(b.tileKey);
  });

  return (
    unitMarkers: unitMarkers,
    civilianTileMarkers: playerOwnedCivilianTileMarkers,
    provincePresenceById: provincePresenceById,
  );
}

void _addCivilianUnitToTileKeyBucket({
  required Unit unit,
  required String regionId,
  required Map<String, List<Unit>> civilianUnitsByTileKey,
}) {
  final tileKey = unit.tileKey;
  if (tileKey == null || tileKey.isEmpty) {
    return;
  }
  final parts = tileKey.split('|');
  if (parts.length < 4 || parts[0] != regionId) {
    return;
  }
  civilianUnitsByTileKey.putIfAbsent(tileKey, () => []).add(unit);
}

List<PortMarkerView> _buildPortMarkers({
  required String regionId,
  required Map<String, String> portsByProvinceSeaboard,
}) {
  final ports = <PortMarkerView>[];
  portsByProvinceSeaboard.forEach((key, tileKey) {
    final parts = tileKey.split('|');
    if (parts.length < 4 || parts[0] != regionId) {
      return;
    }
    final fromKey = localProvinceIdFromPortsSeaboardKey(key, regionId);
    final provinceIdForMarker = fromKey ?? parts[1];
    final x = int.tryParse(parts[2]);
    final y = int.tryParse(parts[3]);
    if (x == null || y == null) {
      return;
    }
    ports.add(
      PortMarkerView(
        x: x,
        y: y,
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
    final parts = townTileKey.split('|');
    if (parts.length < 4 || parts[0] != regionId) {
      continue;
    }
    final x = int.tryParse(parts[2]);
    final y = int.tryParse(parts[3]);
    if (x == null || y == null) {
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
        x: x,
        y: y,
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
