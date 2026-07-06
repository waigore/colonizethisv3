part of 'game_map_area_civilian_draft_projection.dart';

bool _isCivilianUnitType(String unitType) {
  final role = unitRoleForType(unitType);
  if (role == null) return false;
  return role != UnitRole.military && role != UnitRole.naval;
}

String _normalizeCivilianTypeForPriority(String type) {
  return type.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
}

int _civilianIconPriorityForType(String type) {
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

RegionMapViewData _regionWithEmptyCivilianMarkers(RegionMapViewData region) {
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
    provinceUnitPresenceByProvinceId: region.provinceUnitPresenceByProvinceId,
    provincePoliticalOwnerByPrefixedProvinceId:
        region.provincePoliticalOwnerByPrefixedProvinceId,
    seaZoneDisplayNameByPrefixedId: region.seaZoneDisplayNameByPrefixedId,
  );
}

List<CivilianTileMarkerView> _buildProjectedCivilianMarkers({
  required Map<String, List<_ProjectedCivilianUnit>> projectedByTile,
  required Map<String, String> visibilityByTile,
}) {
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
  return projectedMarkers;
}

RegionMapViewData _regionWithProjectedCivilianMarkers({
  required RegionMapViewData region,
  required List<CivilianTileMarkerView> projectedMarkers,
}) {
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
