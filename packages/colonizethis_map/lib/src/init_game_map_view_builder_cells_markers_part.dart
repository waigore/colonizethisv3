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
  Set<String>? civilianMarkerOwnerIds,
}) {
  final unitMarkers = <UnitMarkerView>[];
  final civilianUnitsByTileKey = <String, List<Unit>>{};
  final playerOwnedCivilianTileMarkers = <CivilianTileMarkerView>[];
  final markerOwnerIds = civilianMarkerOwnerIds ??
      game.players
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
        markerOwnerIds.contains(u.ownerId) && _isCivilianUnitType(u.type);
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
    final parsed = tryParseMapTileKey(tileKey);
    if (parsed == null) {
      continue;
    }
    final representativeUnit = units.first;
    final representativeIsAssigned =
        representativeUnit.assignedTileKey == tileKey &&
        representativeUnit.status == UnitStatus.working;
    playerOwnedCivilianTileMarkers.add(
      CivilianTileMarkerView(
        tileKey: tileKey,
        x: parsed.x,
        y: parsed.y,
        localProvinceId: parsed.localId,
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
  final parsed = tryParseMapTileKey(tileKey);
  if (parsed == null || parsed.regionId != regionId) {
    return;
  }
  civilianUnitsByTileKey.putIfAbsent(tileKey, () => []).add(unit);
}
