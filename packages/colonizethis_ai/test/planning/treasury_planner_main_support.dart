// Shared fixtures for treasury_planner pin cases (Refs #3997 Phase 8).
library;

import 'package:colonizethis_models/colonizethis_models.dart';
Game treasuryPlannerTestGameWithStockpile({
  required Stockpile stockpile,
  required int treasury,
  List<OvertureState> overtures = const [],
  int turnNumber = 1,
  List<Player>? extraPlayers,
}) {
  const ow = 'oldWorld';
  final players = [
    Player(
      id: 'gp1',
      displayName: 'GP1',
      isHuman: false,
      capitalProvinceId: '$ow|p1',
      stockpile: stockpile,
      treasury: treasury,
    ),
    ...?extraPlayers,
  ];
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: players,
    overtureStates: overtures,
    worldMarketState: WorldMarketState.withDefaultPrices(const {
      'timber': 20,
      'iron': 20,
      'fabric': 40,
      'castIron': 60,
    }),
  );
}

/// Builds a single-GP game where `gp1` is a below-quota zero-NW lock-recovery
/// seller (`oldWorldProvincesOwned == owProvinces` in `[2, 10)`, no NW
/// provinces) for the F17 food-surplus-release tests (Refs #2924).
Game treasuryPlannerTestLockRecoverySellerGame({
  required Stockpile stockpile,
  required int treasury,
  int owProvinces = 3,
}) {
  const ow = 'oldWorld';
  return Game(
    id: 'g-lock-recovery-seller-f17',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < owProvinces; i++)
            Province(id: '$ow|p1_$i', regionId: ow, ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: '$ow|p1_0',
        stockpile: stockpile,
        treasury: treasury,
      ),
    ],
    worldMarketState: WorldMarketState.withDefaultPrices(const {
      'grain': 10,
      'timber': 20,
    }),
  );
}
