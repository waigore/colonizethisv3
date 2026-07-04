import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_work_tile_prefilter.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';
import 'package:colonizethis_orders/src/orders/validators/work_order_target_prechecks.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('upgrade_town on Minor/Tribe towns (Refs #3872)', () {
    test('prefilter includes minor town tile when embassy and peace', () {
      const gpId = 'gp1';
      const minorId = 'minor1';
      const ow = 'oldWorld';
      const minorTown = '$ow|p2|0|0';
      final game = TestFixtures.minimalGame(
        id: 'g-minor-town-upgrade',
        oldWorld: RegionData(
          provinces: [
            Province(
              id: '$ow|p1',
              regionId: ow,
              ownerId: gpId,
              townTileKey: '$ow|p1|0|0',
            ),
            Province(
              id: '$ow|p2',
              regionId: ow,
              ownerId: minorId,
              townTileKey: minorTown,
              townDevelopmentLevel: 1,
            ),
          ],
        ),
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|p1': ['$ow|p1|0|0'],
            '$ow|p2': [minorTown],
          },
        },
        players: const [
          Player(id: gpId, displayName: 'GP', isHuman: true),
        ],
        minorNations: const [
          MinorNation(id: minorId, displayName: 'Minor'),
        ],
        overtureStates: const [
          OvertureState(
            gpId: gpId,
            targetId: minorId,
            stage: OvertureStage.embassy,
          ),
        ],
      );

      final tiles = rawCandidateTilesForWorkTarget(
        game: game,
        playerId: gpId,
        workTarget: kWorkTargetUpgradeTown,
        playerOwnedProvinceIds: {'$ow|p1'},
      );
      expect(tiles, contains(minorTown));
    });

    test('precheck rejects upgrade_town when at war with tribe', () {
      const gpId = 'gp1';
      const tribeId = 'tribe1';
      const ow = 'oldWorld';
      const townKey = '$ow|p2|0|0';
      final game = TestFixtures.minimalGame(
        id: 'g-war-town-upgrade',
        oldWorld: RegionData(
          provinces: [
            Province(
              id: '$ow|p2',
              regionId: ow,
              ownerId: tribeId,
              townTileKey: townKey,
            ),
          ],
        ),
        players: [
          Player(
            id: gpId,
            displayName: 'GP',
            isHuman: true,
            techUnlocked: {kTechIdNationalBureaucracy: true},
          ),
        ],
        tribes: const [Tribe(id: tribeId, displayName: 'Tribe')],
        overtureStates: const [
          OvertureState(
            gpId: gpId,
            targetId: tribeId,
            stage: OvertureStage.embassy,
          ),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: gpId,
            factionId2: tribeId,
            state: RelationState.atWar,
          ),
        ],
      );
      final ctx = WorkOrderTargetPrecheckContext(
        game: game,
        player: game.players.single,
        playerId: gpId,
        treasury: 1000,
        civilianEmbassyWorkAllowed: (_, _) => false,
        devExclusiveTiles: const {},
      );
      final result = precheckUpgradeTown(
        ctx,
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetUpgradeTown,
          targetTileKey: townKey,
        ),
        '$ow|p2',
        tribeId,
        kUnitTypeBuilder,
      );
      expect(result?.reason, contains('at war'));
    });
  });
}
