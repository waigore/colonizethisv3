part of 'map_view_serialization.dart';

Rgb _rgbFromJson(Object? value) {
  final list = (value as List<dynamic>).cast<num>();
  return (list[0].toInt(), list[1].toInt(), list[2].toInt());
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

CapitalMarkerView _capitalMarkerFromJson(Map<String, dynamic> json) =>
    CapitalMarkerView(
      factionId: json['factionId'] as String,
      displayName: json['displayName'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
    );

UnitMarkerView _unitMarkerFromJson(Map<String, dynamic> json) => UnitMarkerView(
  x: json['x'] as int,
  y: json['y'] as int,
  ownerFactionId: json['ownerFactionId'] as String,
);

CivilianTileMarkerView _civilianMarkerFromJson(
  Map<String, dynamic> json,
) => CivilianTileMarkerView(
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
  representativeIsAssigned: json['representativeIsAssigned'] as bool? ?? false,
  applyCivilianRevealHalo: json['applyCivilianRevealHalo'] as bool? ?? false,
);

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

ArmyTileMarkerView _armyMarkerFromJson(Map<String, dynamic> json) =>
    ArmyTileMarkerView(
      tileKey: json['tileKey'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
      provinceId: json['provinceId'] as String,
      armyIds: (json['armyIds'] as List<dynamic>).cast<String>(),
      fieldArmyIds: (json['fieldArmyIds'] as List<dynamic>).cast<String>(),
      stackCount: json['stackCount'] as int,
      hasHomeArmy: json['hasHomeArmy'] as bool? ?? false,
      renderGrayscale: json['renderGrayscale'] as bool? ?? false,
    );

ProvinceUnitPresenceView _presenceFromJson(Map<String, dynamic> json) =>
    ProvinceUnitPresenceView(
      civilianCount: json['civilianCount'] as int,
      regimentCount: json['regimentCount'] as int,
      shipCount: json['shipCount'] as int,
      intelVisible: json['intelVisible'] as bool,
    );

PortMarkerView _portMarkerFromJson(Map<String, dynamic> json) => PortMarkerView(
  x: json['x'] as int,
  y: json['y'] as int,
  provinceId: json['provinceId'] as String,
  seaZoneId: json['seaZoneId'] as String,
  seaboardKey: json['seaboardKey'] as String?,
);

TownMarkerView _townMarkerFromJson(Map<String, dynamic> json) => TownMarkerView(
  x: json['x'] as int,
  y: json['y'] as int,
  provinceId: json['provinceId'] as String,
  isCoastal: json['isCoastal'] as bool,
  isPort: json['isPort'] as bool,
  touchesSea: json['touchesSea'] as bool,
  townDevelopmentLevel:
      (json['townDevelopmentLevel'] as int?) ?? kTownDevelopmentLevelMin,
  townIconStyle: json['townIconStyle'] as String? ?? kTownIconStyleEuro,
  portIconX: json['portIconX'] as int?,
  portIconY: json['portIconY'] as int?,
  worldFortLevel: json['worldFortLevel'] as int? ?? 0,
  mapVisibleFortLevel: json['mapVisibleFortLevel'] as int?,
);

WarpMarkerView _warpMarkerFromJson(Map<String, dynamic> json) => WarpMarkerView(
  x: json['x'] as int,
  y: json['y'] as int,
  seaZoneId: json['seaZoneId'] as String,
  otherRegionId: json['otherRegionId'] as String,
  otherSeaZoneId: json['otherSeaZoneId'] as String,
);

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
    armyTileMarkers: (json['armyTileMarkers'] as List<dynamic>? ?? const [])
        .map((e) => _armyMarkerFromJson(e as Map<String, dynamic>))
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
      Map<String, dynamic>.from(
        json['combinedTopology'] as Map<String, dynamic>,
      ),
    ),
    seed: json['seed'] as int?,
    configSummary: json['configSummary'] as String?,
  );
}
