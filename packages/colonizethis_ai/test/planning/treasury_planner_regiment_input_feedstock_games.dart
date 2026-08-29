// Feedstock-specific regiment-input Game builders (Refs #4669 Slice D densify).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'treasury_planner_regiment_input_support.dart';

/// Population-bound peasant-recruit fabric feedstock seller (Refs #2847).
Game populationBoundSellerRegimentInputGame({
  required int fabricHeld,
  int woolHeld = 20,
}) {
  const ow = 'oldWorld';
  const tileIron = 'oldWorld|p0|2|0';
  var stockpile = Stockpile.empty
      .applyDelta(CommodityCatalog.iron.id, 2)
      .applyDelta(CommodityCatalog.grain.id, 10);
  if (woolHeld > 0) {
    stockpile = stockpile.applyDelta(kRegimentInputWoolId, woolHeld);
  }
  if (fabricHeld > 0) {
    stockpile = stockpile.applyDelta(kRegimentInputFabricId, fabricHeld);
  }
  return Game(
    id: 'g-peasant-recruit-feedstock',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < 5; i++)
            Province(
              id: '$ow|p$i',
              regionId: ow,
              ownerId: kRegimentInputSingleGpId,
            ),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      resourceByTileKey: const {tileIron: 'iron'},
      tileKeysByRegionAndProvince: const {
        ow: {
          'oldWorld|p0': [tileIron],
        },
      },
    ),
    players: [
      Player(
        id: kRegimentInputSingleGpId,
        displayName: 'Seller',
        isHuman: false,
        capitalProvinceId: 'oldWorld|p0',
        stockpile: stockpile,
        treasury: regimentInputThreshold(),
        workerPool: const WorkerPool(peasants: 1),
      ),
    ],
    worldMarketState: WorldMarketState.withDefaultPrices(const {
      'grain': 10,
      kRegimentInputWoolId: 20,
      kRegimentInputFabricId: 40,
    }),
  );
}
