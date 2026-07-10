// Shared purchase-land work handler fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart'
    show kTechIdMerchantCompanies;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/orders_application_context.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

const purchaseLandOw = 'oldWorld';
const purchaseLandMinorProvinceId = '$purchaseLandOw|M1';
const purchaseLandTileKey = '$purchaseLandOw|M1|0|0';

Game purchaseLandTryApplyGame() {
  return TestFixtures.minimalGame(
    id: 'g1',
    turnNumber: 0,
    oldWorld: RegionData(
      provinces: [
        Province(
          id: '$purchaseLandOw|P1',
          regionId: purchaseLandOw,
          ownerId: 'p1',
        ),
        Province(
          id: purchaseLandMinorProvinceId,
          regionId: purchaseLandOw,
          ownerId: 'minor1',
        ),
      ],
      units: [
        Unit(
          id: 'merchant1',
          type: kUnitTypeMerchant,
          ownerId: 'p1',
          locationProvinceId: purchaseLandMinorProvinceId,
          tileKey: purchaseLandTileKey,
        ),
      ],
    ),
    resourceByTileKey: const {purchaseLandTileKey: 'grain'},
    playerVisibilityByTile: const {
      'p1': {purchaseLandTileKey: 'fullyVisible'},
    },
    tileKeysByRegionAndProvince: {
      purchaseLandOw: {
        purchaseLandMinorProvinceId: [purchaseLandTileKey],
        '$purchaseLandOw|P1': ['$purchaseLandOw|P1|0|0'],
      },
    },
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: '$purchaseLandOw|P1',
        stockpile: const Stockpile(),
        treasury: 500,
        techUnlocked: {kTechIdMerchantCompanies: true},
      ),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    overtureStates: [
      const OvertureState(
        gpId: 'p1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
    diplomacyRelations: const [],
  );
}

BuildWorkState purchaseLandMinimalBuildState(Game game) {
  return BuildWorkState(
    game: game,
    buildOrders: const {},
    workOrders: const {},
    work: WorkOrderState(
      unitsById: (oldWorld: const {}, newWorld: const {}),
      tileState: game.worldState.tileState,
      visibilityByTile: const {},
      portsByProvinceSeaboard: const {},
      purchasedTilesByTileKey: const {},
      oldProvinces: const [],
      newProvinces: const [],
    ),
  );
}
