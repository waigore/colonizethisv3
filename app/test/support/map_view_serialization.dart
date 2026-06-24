// Deterministic JSON serialization for [InitGameMapViewData] and its parts.
//
// `mapViewData` lives on `InitGameResult`, not on `Game`, so `Game.toJson()` /
// `Game.fromJson()` cannot reconstruct what the map-view widget suites read
// (Refs #3656). These helpers let the map-dependent suites load a committed,
// pre-generated seed-42 fixture (see `app/test/support/fixtures/`) instead of
// paying the ~7-11s procedural map generation per test isolate.
//
// Serialization is deterministic: optional/null fields and default-valued flags
// are omitted so that `serialize(deserialize(json)) == json` holds as a plain
// string comparison, which the round-trip guard test relies on
// (`map_view_fixture_roundtrip_test.dart`).

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TerrainType;
import 'package:colonizethis_map/colonizethis_map.dart';

/// Current fixture schema version. Bump when the serialized shape changes so a
/// stale committed fixture fails fast in the round-trip guard.
const int kMapViewFixtureVersion = 1;

List<int> _rgbToJson(Rgb rgb) => <int>[rgb.$1, rgb.$2, rgb.$3];

Rgb _rgbFromJson(Object? value) {
  final list = (value as List<dynamic>).cast<num>();
  return (list[0].toInt(), list[1].toInt(), list[2].toInt());
}

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

CellViewData _cellFromJson(Map<String, dynamic> json) {
  final terrainTypeName = json['terrainType'] as String?;
  final visibilityName = json['visibility'] as String?;
  return CellViewData(
    x: json['x'] as int,
    y: json['y'] as int,
    regionCellId: json['regionCellId'] as String,
    isSea: json['isSea'] as bool,
    terrainTypeId: json['terrainTypeId'] as String?,
    terrainType: terrainTypeName == null
        ? null
        : TerrainType.values.byName(terrainTypeName),
    resourceId: json['resourceId'] as String?,
    ownerFactionId: json['ownerFactionId'] as String?,
    provinceDisplayName: json['provinceDisplayName'] as String?,
    improvementLevel: json['improvementLevel'] as int?,
    roadLevel: json['roadLevel'] as int?,
    resourceExtractionUnits: json['resourceExtractionUnits'] as int?,
    resourceExtractionEffectiveUnits:
        json['resourceExtractionEffectiveUnits'] as int?,
    resourceExtractionBlockedUnits:
        json['resourceExtractionBlockedUnits'] as int?,
    visibility: visibilityName == null
        ? TileVisibility.visible
        : TileVisibility.values.byName(visibilityName),
  );
}

Map<String, dynamic> _capitalMarkerToJson(CapitalMarkerView m) => {
  'factionId': m.factionId,
  'displayName': m.displayName,
  'x': m.x,
  'y': m.y,
};

CapitalMarkerView _capitalMarkerFromJson(Map<String, dynamic> json) =>
    CapitalMarkerView(
      factionId: json['factionId'] as String,
      displayName: json['displayName'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
    );

Map<String, dynamic> _unitMarkerToJson(UnitMarkerView m) => {
  'x': m.x,
  'y': m.y,
  'ownerFactionId': m.ownerFactionId,
};

UnitMarkerView _unitMarkerFromJson(Map<String, dynamic> json) => UnitMarkerView(
  x: json['x'] as int,
  y: json['y'] as int,
  ownerFactionId: json['ownerFactionId'] as String,
);

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

CivilianTileMarkerView _civilianMarkerFromJson(Map<String, dynamic> json) =>
    CivilianTileMarkerView(
      tileKey: json['tileKey'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
      localProvinceId: json['localProvinceId'] as String,
      unitIds: (json['unitIds'] as List<dynamic>).cast<String>(),
      unitTypes: (json['unitTypes'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as String),
      ),
      representativeUnitType: json['representativeUnitType'] as String,
      stackCount: json['stackCount'] as int,
      representativeIsAssigned:
          json['representativeIsAssigned'] as bool? ?? false,
      applyCivilianRevealHalo: json['applyCivilianRevealHalo'] as bool? ?? false,
    );

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

FleetTileMarkerView _fleetMarkerFromJson(Map<String, dynamic> json) =>
    FleetTileMarkerView(
      tileKey: json['tileKey'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
      locationScopeKey: json['locationScopeKey'] as String,
      fleetIds: (json['fleetIds'] as List<dynamic>).cast<String>(),
      stackCount: json['stackCount'] as int,
      renderGrayscale: json['renderGrayscale'] as bool? ?? false,
      applyFleetRevealHalo: json['applyFleetRevealHalo'] as bool? ?? false,
    );

Map<String, dynamic> _presenceToJson(ProvinceUnitPresenceView p) => {
  'civilianCount': p.civilianCount,
  'regimentCount': p.regimentCount,
  'shipCount': p.shipCount,
  'intelVisible': p.intelVisible,
};

ProvinceUnitPresenceView _presenceFromJson(Map<String, dynamic> json) =>
    ProvinceUnitPresenceView(
      civilianCount: json['civilianCount'] as int,
      regimentCount: json['regimentCount'] as int,
      shipCount: json['shipCount'] as int,
      intelVisible: json['intelVisible'] as bool,
    );

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

PortMarkerView _portMarkerFromJson(Map<String, dynamic> json) => PortMarkerView(
  x: json['x'] as int,
  y: json['y'] as int,
  provinceId: json['provinceId'] as String,
  seaZoneId: json['seaZoneId'] as String,
  seaboardKey: json['seaboardKey'] as String?,
);

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
  return json;
}

TownMarkerView _townMarkerFromJson(Map<String, dynamic> json) => TownMarkerView(
  x: json['x'] as int,
  y: json['y'] as int,
  provinceId: json['provinceId'] as String,
  isCoastal: json['isCoastal'] as bool,
  isPort: json['isPort'] as bool,
  touchesSea: json['touchesSea'] as bool,
  portIconX: json['portIconX'] as int?,
  portIconY: json['portIconY'] as int?,
);

Map<String, dynamic> _warpMarkerToJson(WarpMarkerView m) => {
  'x': m.x,
  'y': m.y,
  'seaZoneId': m.seaZoneId,
  'otherRegionId': m.otherRegionId,
  'otherSeaZoneId': m.otherSeaZoneId,
};

WarpMarkerView _warpMarkerFromJson(Map<String, dynamic> json) => WarpMarkerView(
  x: json['x'] as int,
  y: json['y'] as int,
  seaZoneId: json['seaZoneId'] as String,
  otherRegionId: json['otherRegionId'] as String,
  otherSeaZoneId: json['otherSeaZoneId'] as String,
);

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
  'provinceUnitPresenceByProvinceId': region.provinceUnitPresenceByProvinceId
      .map((k, v) => MapEntry(k, _presenceToJson(v))),
  'provincePoliticalOwnerByPrefixedProvinceId':
      region.provincePoliticalOwnerByPrefixedProvinceId,
  'seaZoneDisplayNameByPrefixedId': region.seaZoneDisplayNameByPrefixedId,
};

/// Reconstructs a region's view data from [regionMapViewDataToJson] output.
RegionMapViewData regionMapViewDataFromJson(Map<String, dynamic> json) {
  return RegionMapViewData(
    regionId: json['regionId'] as String,
    width: json['width'] as int,
    height: json['height'] as int,
    cellSize: json['cellSize'] as int,
    cells: (json['cells'] as List<dynamic>)
        .map((e) => _cellFromJson(e as Map<String, dynamic>))
        .toList(),
    capitalMarkers: (json['capitalMarkers'] as List<dynamic>)
        .map((e) => _capitalMarkerFromJson(e as Map<String, dynamic>))
        .toList(),
    portMarkers: (json['portMarkers'] as List<dynamic>)
        .map((e) => _portMarkerFromJson(e as Map<String, dynamic>))
        .toList(),
    warpMarkers: (json['warpMarkers'] as List<dynamic>)
        .map((e) => _warpMarkerFromJson(e as Map<String, dynamic>))
        .toList(),
    townMarkers: (json['townMarkers'] as List<dynamic>)
        .map((e) => _townMarkerFromJson(e as Map<String, dynamic>))
        .toList(),
    factionColors: (json['factionColors'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, _rgbFromJson(v)),
    ),
    greatPowerFactionIds: (json['greatPowerFactionIds'] as List<dynamic>)
        .cast<String>()
        .toSet(),
    terrainColors: (json['terrainColors'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(TerrainType.values.byName(k), _rgbFromJson(v)),
    ),
    unitMarkers: (json['unitMarkers'] as List<dynamic>)
        .map((e) => _unitMarkerFromJson(e as Map<String, dynamic>))
        .toList(),
    civilianTileMarkers: (json['civilianTileMarkers'] as List<dynamic>)
        .map((e) => _civilianMarkerFromJson(e as Map<String, dynamic>))
        .toList(),
    fleetTileMarkers: (json['fleetTileMarkers'] as List<dynamic>)
        .map((e) => _fleetMarkerFromJson(e as Map<String, dynamic>))
        .toList(),
    provinceUnitPresenceByProvinceId:
        (json['provinceUnitPresenceByProvinceId'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, _presenceFromJson(v as Map<String, dynamic>)),
        ),
    provincePoliticalOwnerByPrefixedProvinceId:
        (json['provincePoliticalOwnerByPrefixedProvinceId']
                as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as String?)),
    seaZoneDisplayNameByPrefixedId:
        (json['seaZoneDisplayNameByPrefixedId'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as String),
        ),
  );
}

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

/// Reconstructs combined map view data from [initGameMapViewDataToJson] output.
InitGameMapViewData initGameMapViewDataFromJson(Map<String, dynamic> json) {
  return InitGameMapViewData(
    oldWorld: regionMapViewDataFromJson(
      json['oldWorld'] as Map<String, dynamic>,
    ),
    newWorld: regionMapViewDataFromJson(
      json['newWorld'] as Map<String, dynamic>,
    ),
    combinedTopology: MapTopology.fromJson(
      Map<String, dynamic>.from(json['combinedTopology'] as Map),
    ),
    seed: json['seed'] as int?,
    configSummary: json['configSummary'] as String?,
  );
}
