// Scenario run tear-offs for order suggestion core family (Refs #3949 wave 3).
import 'order_suggestion_core_expectation_shorthand.dart';
import 'order_suggestion_core_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void oscRunSuggestNavalMoveOrdersReturnsList() {
  final navalMoveGame = oscGame(
    worldState: oscWorld(fleets: [oscFleetAtSea('sea1')]),
  );
  final navalMoveTopology = oscSeaTopology(
    ['sea1', 'sea2'],
    edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
  );
  expect(
    suggestNavalMoveOrders(
      oscView(navalMoveGame, navalMoveTopology),
      navalMoveGame,
      navalMoveTopology,
      const Orders(),
    ),
    isA<List<NavalMoveOrder>>(),
  );
}

void oscRunCounterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles() {
  final counterSpyTile = OscIds.tile('p1', 0, 0);
  oscExpectWorkTargetSuggestions(
    game: oscGame(
      worldState: oscWorld(
        oldWorld: RegionData(
          provinces: [oscProvince('p1', ownerId: OscIds.playerId)],
          units: [
            Unit(
              id: 'u1',
              type: kUnitTypeSpy,
              ownerId: OscIds.playerId,
              locationProvinceId: OscIds.prov('p1'),
            ),
          ],
        ),
        playerVisibilityByTile: oscVisibility({counterSpyTile: 'fullyVisible'}),
        tileKeysByRegionAndProvince: oscTilesByProvince({
          'p1': [counterSpyTile],
        }),
      ),
    ),
    topology: oscProvinceTopology(['p1']),
    target: kWorkTargetCounterSpy,
    expectNonEmpty: true,
  );
}

void
oscRunPurchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile() {
  final purchaseTile = OscIds.tile('minor1', 0, 0);
  oscExpectWorkTargetSuggestions(
    game: oscGame(
      worldState: oscWorld(
        oldWorld: RegionData(
          provinces: [
            oscProvince('p1', ownerId: OscIds.playerId),
            oscProvince('minor1', ownerId: 'minor1'),
          ],
          units: [
            Unit(
              id: 'u1',
              type: kUnitTypeMerchant,
              ownerId: OscIds.playerId,
              locationProvinceId: OscIds.prov('p1'),
            ),
          ],
        ),
        playerVisibilityByTile: oscVisibility({
          OscIds.tile('p1', 0, 0): 'fullyVisible',
          purchaseTile: 'fullyVisible',
        }),
        tileKeysByRegionAndProvince: oscTilesByProvince({
          'p1': [OscIds.tile('p1', 0, 0)],
          'minor1': [purchaseTile],
        }),
        resourceByTileKey: {purchaseTile: 'grain'},
      ),
      players: [oscPlayer(treasury: 500)],
      minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
      overtureStates: const [
        OvertureState(
          gpId: OscIds.playerId,
          targetId: 'minor1',
          stage: OvertureStage.embassy,
          sinceTurn: 0,
        ),
      ],
    ),
    topology: oscProvinceTopology(['p1', 'minor1']),
    target: kWorkTargetPurchaseLand,
    expectNonEmpty: true,
  );
}
