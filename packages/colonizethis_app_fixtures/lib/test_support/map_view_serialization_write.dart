part of 'map_view_serialization.dart';

List<int> _rgbToJson(Rgb rgb) => <int>[rgb.$1, rgb.$2, rgb.$3];

Map<String, dynamic> _cellToJson(CellViewData cell) {
  final json = <String, dynamic>{
    'x': cell.x,
    'y': cell.y,
    'regionCellId': cell.regionCellId,
    'isSea': cell.isSea,
  };
  if (cell.terrainTypeId != null) json['terrainTypeId'] = cell.terrainTypeId;
  if (cell.terrainType != null) json['terrainType'] = cell.terrainType!.name;
  if (cell.resourceId != null) json['resourceId'] = cell.resourceId;
  if (cell.ownerFactionId != null) json['ownerFactionId'] = cell.ownerFactionId;
  if (cell.provinceDisplayName != null) {
    json['provinceDisplayName'] = cell.provinceDisplayName;
  }
  if (cell.improvementLevel != null) {
    json['improvementLevel'] = cell.improvementLevel;
  }
  if (cell.improvementTechCap != null) {
    json['improvementTechCap'] = cell.improvementTechCap;
  }
  if (cell.roadLevel != null) json['roadLevel'] = cell.roadLevel;
  if (cell.resourceExtractionUnits != null) {
    json['resourceExtractionUnits'] = cell.resourceExtractionUnits;
  }
  if (cell.resourceExtractionEffectiveUnits != null) {
    json['resourceExtractionEffectiveUnits'] =
        cell.resourceExtractionEffectiveUnits;
  }
  if (cell.resourceExtractionBlockedUnits != null) {
    json['resourceExtractionBlockedUnits'] =
        cell.resourceExtractionBlockedUnits;
  }
  if (cell.visibility != TileVisibility.visible) {
    json['visibility'] = cell.visibility.name;
  }
  return json;
}

Map<String, dynamic> _capitalMarkerToJson(CapitalMarkerView m) => {
  'factionId': m.factionId,
  'displayName': m.displayName,
  'x': m.x,
  'y': m.y,
};

Map<String, dynamic> _unitMarkerToJson(UnitMarkerView m) => {
  'x': m.x,
  'y': m.y,
  'ownerFactionId': m.ownerFactionId,
};

Map<String, dynamic> _civilianMarkerToJson(CivilianTileMarkerView m) {
  final json = <String, dynamic>{
    'tileKey': m.tileKey,
    'x': m.x,
    'y': m.y,
    'localProvinceId': m.localProvinceId,
    'unitIds': m.unitIds,
    'unitTypes': m.unitTypes,
    'representativeUnitType': m.representativeUnitType,
    'stackCount': m.stackCount,
  };
  if (m.representativeIsAssigned) json['representativeIsAssigned'] = true;
  if (m.applyCivilianRevealHalo) json['applyCivilianRevealHalo'] = true;
  return json;
}

Map<String, dynamic> _fleetMarkerToJson(FleetTileMarkerView m) {
  final json = <String, dynamic>{
    'tileKey': m.tileKey,
    'x': m.x,
    'y': m.y,
    'locationScopeKey': m.locationScopeKey,
    'fleetIds': m.fleetIds,
    'stackCount': m.stackCount,
  };
  if (m.renderGrayscale) json['renderGrayscale'] = true;
  if (m.applyFleetRevealHalo) json['applyFleetRevealHalo'] = true;
  return json;
}

Map<String, dynamic> _armyMarkerToJson(ArmyTileMarkerView m) {
  final json = <String, dynamic>{
    'tileKey': m.tileKey,
    'x': m.x,
    'y': m.y,
    'provinceId': m.provinceId,
    'armyIds': m.armyIds,
    'fieldArmyIds': m.fieldArmyIds,
    'stackCount': m.stackCount,
    'hasHomeArmy': m.hasHomeArmy,
  };
  if (m.renderGrayscale) json['renderGrayscale'] = true;
  return json;
}

Map<String, dynamic> _presenceToJson(ProvinceUnitPresenceView p) => {
  'civilianCount': p.civilianCount,
  'regimentCount': p.regimentCount,
  'shipCount': p.shipCount,
  'intelVisible': p.intelVisible,
};

Map<String, dynamic> _portMarkerToJson(PortMarkerView m) {
  final json = <String, dynamic>{
    'x': m.x,
    'y': m.y,
    'provinceId': m.provinceId,
    'seaZoneId': m.seaZoneId,
  };
  if (m.seaboardKey != null) json['seaboardKey'] = m.seaboardKey;
  return json;
}

Map<String, dynamic> _townMarkerToJson(TownMarkerView m) {
  final json = <String, dynamic>{
    'x': m.x,
    'y': m.y,
    'provinceId': m.provinceId,
    'isCoastal': m.isCoastal,
    'isPort': m.isPort,
    'touchesSea': m.touchesSea,
  };
  if (m.portIconX != null) json['portIconX'] = m.portIconX;
  if (m.portIconY != null) json['portIconY'] = m.portIconY;
  json['townDevelopmentLevel'] = m.townDevelopmentLevel;
  json['townIconStyle'] = m.townIconStyle;
  return json;
}

Map<String, dynamic> _warpMarkerToJson(WarpMarkerView m) => {
  'x': m.x,
  'y': m.y,
  'seaZoneId': m.seaZoneId,
  'otherRegionId': m.otherRegionId,
  'otherSeaZoneId': m.otherSeaZoneId,
};

/// Serializes a single region's view data to a JSON-safe map.
Map<String, dynamic> regionMapViewDataToJson(RegionMapViewData region) => {
  'regionId': region.regionId,
  'width': region.width,
  'height': region.height,
  'cellSize': region.cellSize,
  'cells': region.cells.map(_cellToJson).toList(),
  'capitalMarkers': region.capitalMarkers.map(_capitalMarkerToJson).toList(),
  'portMarkers': region.portMarkers.map(_portMarkerToJson).toList(),
  'warpMarkers': region.warpMarkers.map(_warpMarkerToJson).toList(),
  'townMarkers': region.townMarkers.map(_townMarkerToJson).toList(),
  'factionColors': region.factionColors.map(
    (k, v) => MapEntry(k, _rgbToJson(v)),
  ),
  'greatPowerFactionIds': region.greatPowerFactionIds.toList(),
  'terrainColors': region.terrainColors.map(
    (k, v) => MapEntry(k.name, _rgbToJson(v)),
  ),
  'unitMarkers': region.unitMarkers.map(_unitMarkerToJson).toList(),
  'civilianTileMarkers': region.civilianTileMarkers
      .map(_civilianMarkerToJson)
      .toList(),
  'fleetTileMarkers': region.fleetTileMarkers.map(_fleetMarkerToJson).toList(),
  if (region.armyTileMarkers.isNotEmpty)
    'armyTileMarkers': region.armyTileMarkers.map(_armyMarkerToJson).toList(),
  'provinceUnitPresenceByProvinceId': region.provinceUnitPresenceByProvinceId
      .map((k, v) => MapEntry(k, _presenceToJson(v))),
  'provincePoliticalOwnerByPrefixedProvinceId':
      region.provincePoliticalOwnerByPrefixedProvinceId,
  'seaZoneDisplayNameByPrefixedId': region.seaZoneDisplayNameByPrefixedId,
};

/// Serializes the combined two-region map view data to a JSON-safe map.
Map<String, dynamic> initGameMapViewDataToJson(InitGameMapViewData data) {
  final json = <String, dynamic>{
    'version': kMapViewFixtureVersion,
    'oldWorld': regionMapViewDataToJson(data.oldWorld),
    'newWorld': regionMapViewDataToJson(data.newWorld),
    'combinedTopology': data.combinedTopology.toJson(),
  };
  if (data.seed != null) json['seed'] = data.seed;
  if (data.configSummary != null) json['configSummary'] = data.configSummary;
  return json;
}
