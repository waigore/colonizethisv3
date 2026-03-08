// Demo Game and region data for ProvinceSeaZoneDetailOverlay Widgetbook and tests.
// Aligns with buildDemoRegionMapViewData (regionId: demo, provinces p1–p4, sea s1–s2).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'package:colonizethis_app/widgets/region_map_demo_data.dart';

/// Builds a minimal Game for overlay demo. Region 'demo' with provinces p1–p4, units, fleets.
Game buildDemoGameForOverlay() {
  const regionId = 'demo';
  final provinces = [
    Province(
      id: '$regionId|p1',
      regionId: regionId,
      ownerId: 'gp1',
      displayName: 'Wessex',
    ),
    Province(
      id: '$regionId|p2',
      regionId: regionId,
      ownerId: 'gp1',
      displayName: 'Kent',
    ),
    Province(
      id: '$regionId|p3',
      regionId: regionId,
      ownerId: 'gp2',
      displayName: 'Northumbria',
    ),
    Province(
      id: '$regionId|p4',
      regionId: regionId,
      ownerId: 'gp2',
      displayName: 'Mercia',
    ),
  ];
  final units = [
    Unit(
      id: 'u1',
      type: 'pikemen',
      ownerId: 'gp1',
      provinceId: '$regionId|p1',
      status: UnitStatus.idle,
    ),
    Unit(
      id: 'u2',
      type: 'Builder',
      ownerId: 'gp1',
      provinceId: '$regionId|p2',
      status: UnitStatus.working,
      tileKey: '$regionId|p2|5|4',
    ),
    Unit(
      id: 'u3',
      type: 'Explorer',
      ownerId: 'gp1',
      provinceId: '$regionId|p1',
      status: UnitStatus.idle,
      tileKey: '$regionId|p1|2|3',
    ),
  ];
  final tileKeys = <String>[];
  for (var y = 1; y < 9; y++) {
    for (var x = 1; x < 13; x++) {
      String provId;
      if (x < 4) {
        provId = 'p1';
      } else if (x >= 10) {
        provId = 'p3';
      } else if (y >= 7) {
        provId = 'p4';
      } else {
        provId = 'p2';
      }
      tileKeys.add('$regionId|$provId|$x|$y');
    }
  }
  final byProvince = <String, List<String>>{};
  for (final tk in tileKeys) {
    final parts = tk.split('|');
    if (parts.length >= 2) {
      final fullId = '${parts[0]}|${parts[1]}';
      byProvince.putIfAbsent(fullId, () => []).add(tk);
    }
  }
  final resourceByTile = <String, String>{
    '$regionId|p1|1|1': 'grain',
    '$regionId|p2|5|3': 'timber',
    '$regionId|p2|7|4': 'iron',
  };
  final improvementByTile = <String, int>{
    '$regionId|p1|1|1': 1,
    '$regionId|p2|5|3': 2,
  };
  final player = Player(
    id: 'gp1',
    displayName: 'England',
    isHuman: true,
    stockpile: const Stockpile(),
    workerPool: const WorkerPool(),
    treasury: 5000,
  );
  return Game(
    id: 'demo_overlay',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: provinces,
        units: units,
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {regionId: byProvince},
      resourceByTileKey: resourceByTile,
      tileState: TileMapState(
        improvementByTile: improvementByTile,
        roadLevelByTile: {},
      ),
      portsByProvinceSeaboard: {'$regionId|p2|s1': '$regionId|p2|6|8'},
      fleets: [
        Fleet(
          id: 'f1',
          ownerId: 'gp1',
          seaZoneId: 's1',
          regionId: regionId,
          shipTypeIds: ['carrack', 'carrack'],
        ),
      ],
    ),
    players: [
      player,
      Player(
        id: 'gp2',
        displayName: 'Scotland',
        isHuman: false,
        stockpile: const Stockpile(),
        workerPool: const WorkerPool(),
        treasury: 3000,
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

/// Demo region (from buildDemoRegionMapViewData) for overlay.
RegionMapViewData get demoRegionForOverlay => buildDemoRegionMapViewData();
