import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('selectFullAiCivilianWorkOrders colonial', () {
    test('Merchant prefers purchase_land in newWorld tribe province', () {
      const playerId = 'gp1';
      const nwTile = 'newWorld|tribeProv|2|3';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: [
              Province(
                id: 'newWorld|tribeProv',
                regionId: 'newWorld',
                ownerId: 'tribe1',
              ),
            ],
          ),
        ),
        players: const [
          Player(id: playerId, displayName: 'GP', isHuman: false),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'T')],
      );
      final view = PlayerView(
        playerId: playerId,
        player: game.players.single,
        ownUnitsById: {
          'm1': Unit(
            id: 'm1',
            type: kUnitTypeMerchant,
            ownerId: playerId,
            locationProvinceId: 'newWorld|tribeProv',
          ),
        },
        provincesById: const {},
        visibilityByTile: const {},
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          const WorkOrder(
            unitId: 'm1',
            target: kWorkTargetExplore,
            targetTileKey: 'newWorld|tribeProv|0|0',
          ),
          const WorkOrder(
            unitId: 'm1',
            target: kWorkTargetPurchaseLand,
            targetTileKey: nwTile,
          ),
        ],
        view: view,
        game: game,
      );
      expect(r.workOrders.single.target, kWorkTargetPurchaseLand);
      expect(r.workOrders.single.targetTileKey, nwTile);
    });

    test(
      'Builder prefers NW unimproved resource over OW unimproved resource',
      () {
        const playerId = 'gp1';
        const tileOw = 'oldWorld|p1|0|0';
        const tileNw = 'newWorld|p2|1|0';
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            resourceByTileKey: {tileOw: 'grain', tileNw: 'grain'},
          ),
          players: const [
            Player(id: playerId, displayName: 'GP', isHuman: false),
          ],
        );
        final view = PlayerView(
          playerId: playerId,
          player: game.players.single,
          ownUnitsById: {
            'b1': Unit(
              id: 'b1',
              type: kUnitTypeBuilder,
              ownerId: playerId,
              locationProvinceId: 'oldWorld|p1',
            ),
          },
          provincesById: const {},
          visibilityByTile: const {},
          prospectedTiles: const {},
          diplomacyByOtherId: const {},
        );
        final r = selectFullAiCivilianWorkOrders(
          workSuggestions: [
            const WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: tileOw,
            ),
            const WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: tileNw,
            ),
          ],
          view: view,
          game: game,
        );
        expect(r.workOrders.single.targetTileKey, tileNw);
      },
    );

    test(
      'Builder prefers owned NW unimproved resource over tribe NW resource',
      () {
        const playerId = 'gp1';
        const tileTribe = 'newWorld|tribeProv|0|0';
        const tileOwned = 'newWorld|gpProv|1|0';
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: RegionData(
              provinces: [
                Province(
                  id: 'newWorld|tribeProv',
                  regionId: 'newWorld',
                  ownerId: 'tribe1',
                ),
                Province(
                  id: 'newWorld|gpProv',
                  regionId: 'newWorld',
                  ownerId: playerId,
                ),
              ],
            ),
            resourceByTileKey: {tileTribe: 'grain', tileOwned: 'grain'},
          ),
          players: const [
            Player(id: playerId, displayName: 'GP', isHuman: false),
          ],
          tribes: const [Tribe(id: 'tribe1', displayName: 'T')],
        );
        final view = PlayerView(
          playerId: playerId,
          player: game.players.single,
          ownUnitsById: {
            'b1': Unit(
              id: 'b1',
              type: kUnitTypeBuilder,
              ownerId: playerId,
              locationProvinceId: 'newWorld|gpProv',
            ),
          },
          provincesById: const {},
          visibilityByTile: const {},
          prospectedTiles: const {},
          diplomacyByOtherId: const {},
        );
        final r = selectFullAiCivilianWorkOrders(
          workSuggestions: [
            const WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: tileTribe,
            ),
            const WorkOrder(
              unitId: 'b1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: tileOwned,
            ),
          ],
          view: view,
          game: game,
        );
        expect(r.workOrders.single.targetTileKey, tileOwned);
      },
    );
  });
}
