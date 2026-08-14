// Shared fixtures for world_market_phase_first_right_credit_test
// (Refs #4342 Slice C).
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import '../support/world_market_test_support.dart';

const frrCreditTileA = '$frrCreditTestOw|M1|0|0';
const frrCreditTileB = '$frrCreditTestOw|M1|1|0';

Game frrMultiOwnerTilesGame() {
  return TestFixtures.minimalGame(
    players: const [
      Player(id: 'gpA', displayName: 'GP A', isHuman: true, treasury: 100),
      Player(id: 'gpB', displayName: 'GP B', isHuman: false, treasury: 50),
      Player(
        id: 'gpC',
        displayName: 'GP C',
        isHuman: false,
        treasury: 1000,
        stockpile: Stockpile.empty,
      ),
    ],
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: frrCreditTestMinorProvinceId,
          regionId: frrCreditTestOw,
          ownerId: 'M1',
        ),
      ],
    ),
    tileKeysByRegionAndProvince: const {
      frrCreditTestOw: {
        frrCreditTestMinorProvinceId: [frrCreditTileA, frrCreditTileB],
      },
    },
    minorNations: const [MinorNation(id: 'M1', displayName: 'M1')],
    purchasedTilesByTileKey: const {
      frrCreditTileA: 'gpA',
      frrCreditTileB: 'gpB',
    },
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: 'gpA', factionId2: 'M1', score: 100),
      DiplomacyRelation(factionId1: 'gpB', factionId2: 'M1', score: 50),
    ],
  ).copyWith(
    worldMarketState: WorldMarketState.empty.copyWith(
      prices: const {'timber': 10},
    ),
  );
}

Game frrEmbassyKickbackGame() {
  return TestFixtures.minimalGame(
    players: const [
      Player(id: 'gpA', displayName: 'GP A', isHuman: true, treasury: 100),
      Player(
        id: 'gpB',
        displayName: 'GP B',
        isHuman: false,
        treasury: 1000,
        stockpile: Stockpile.empty,
      ),
      Player(id: 'gpC', displayName: 'GP C', isHuman: false, treasury: 100),
    ],
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: frrCreditTestMinorProvinceId,
          regionId: frrCreditTestOw,
          ownerId: 'M1',
        ),
      ],
    ),
    tileKeysByRegionAndProvince: const {
      frrCreditTestOw: {
        frrCreditTestMinorProvinceId: [frrCreditTestTileKey],
      },
    },
    minorNations: const [MinorNation(id: 'M1', displayName: 'M1')],
    purchasedTilesByTileKey: const {frrCreditTestTileKey: 'gpA'},
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: 'gpA', factionId2: 'M1', score: 100),
      DiplomacyRelation(factionId1: 'gpC', factionId2: 'M1', score: 50),
    ],
    overtureStates: const [
      OvertureState(gpId: 'gpA', targetId: 'M1', stage: OvertureStage.embassy),
      OvertureState(gpId: 'gpC', targetId: 'M1', stage: OvertureStage.embassy),
    ],
  ).copyWith(
    worldMarketState: WorldMarketState.empty.copyWith(
      prices: const {'timber': 20},
    ),
  );
}
