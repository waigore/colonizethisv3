// Compact civilian / New World spawn expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const cspOw = 'oldWorld';
const cspCapitalProvinceId = 'oldWorld|P1';
const cspCapitalTileKey = 'oldWorld|P1|0|1';

Stockpile cspStockpileCovering(Map<String, int> inputs) {
  var stockpile = const Stockpile();
  for (final e in inputs.entries) {
    stockpile = stockpile.applyDelta(e.key, e.value + 1);
  }
  return stockpile;
}

Game cspExplorerGame({
  required String capitalProvinceId,
  List<Province> provinces = const [],
  Map<String, List<String>>? tileKeysByProvince,
  CapitalTile? capitalTile,
  String? otherOwnedProvinceId,
  int extraTreasury = 100,
  int peasants = 1,
}) {
  final explorerEcon = CivilianEconomyCatalog.byId[kUnitTypeExplorer]!;
  final tileMap = tileKeysByProvince ??
      {
        capitalProvinceId: ['oldWorld|P1|0|0', cspCapitalTileKey],
        if (otherOwnedProvinceId != null)
          otherOwnedProvinceId: ['oldWorld|P2|0|0'],
      };
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: provinces.isNotEmpty
            ? provinces
            : [
                Province(id: capitalProvinceId, regionId: cspOw, ownerId: 'p1'),
                if (otherOwnedProvinceId != null)
                  Province(
                    id: otherOwnedProvinceId,
                    regionId: cspOw,
                    ownerId: 'p1',
                  ),
              ],
        units: [],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {cspOw: tileMap},
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: capitalProvinceId,
        capitalTile: capitalTile,
        stockpile: cspStockpileCovering(explorerEcon.buildInputs),
        workerPool: WorkerPool(peasants: peasants),
        treasury: explorerEcon.buildTreasuryCost + extraTreasury,
      ),
    ],
  );
}

Orders cspBuildOrders(
  String unitType, {
  required bool isMilitary,
  required String spawnProvinceId,
}) =>
    Orders(
      buildUnitOrdersByPlayerId: {
        'p1': [
          BuildUnitOrder(
            unitType: unitType,
            isMilitary: isMilitary,
            spawnProvinceId: spawnProvinceId,
          ),
        ],
      },
    );

