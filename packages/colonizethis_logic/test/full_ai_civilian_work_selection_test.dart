import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('selectFullAiCivilianWorkOrders', () {
    test(
      'non-Explorer picks lexicographically smallest (target, targetTileKey)',
      () {
        const playerId = 'gp1';
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: playerId, displayName: 'GP', isHuman: false),
          ],
        );
        const topology = MapTopology(nodes: [], edges: []);
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
        final suggestions = [
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildRoad,
            targetTileKey: 'oldWorld|p1|1|0',
          ),
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: 'oldWorld|p1|0|0',
          ),
        ];
        final r = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions,
          view: view,
          game: game,
        );
        expect(r.workOrders, hasLength(1));
        expect(r.workOrders.single.target, kWorkTargetBuildImprovement);
        expect(r.idleEvents, isEmpty);
      },
    );

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

    test('Builder prefers unimproved resource tile over lexicographically smaller road', () {
      const playerId = 'gp1';
      const tileRoad = 'oldWorld|p1|0|0';
      const tileResource = 'oldWorld|p1|1|0';
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          resourceByTileKey: {tileResource: 'grain'},
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
            target: kWorkTargetBuildRoad,
            targetTileKey: tileRoad,
          ),
          const WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: tileResource,
          ),
        ],
        view: view,
        game: game,
      );
      expect(r.workOrders.single.targetTileKey, tileResource);
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

    test(
      'Explorer with two equal E_score explores picks lexicographically smaller tile',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const pA = '$ow|pA';
        const pB = '$ow|pB';
        const tileB = 'oldWorld|pB|0|0';
        const tileA = 'oldWorld|pA|0|0';
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(id: pA, regionId: ow, ownerId: 'tribe1'),
                Province(id: pB, regionId: ow, ownerId: 'tribe1'),
              ],
              units: const [],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              playerId: {tileA: 'unknown', tileB: 'unknown'},
            },
            tileKeysByRegionAndProvince: const {
              ow: {
                pA: [tileA],
                pB: [tileB],
              },
            },
          ),
          players: const [
            Player(id: playerId, displayName: 'GP', isHuman: false),
          ],
          tribes: const [Tribe(id: 'tribe1', displayName: 'T')],
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = PlayerView(
          playerId: playerId,
          player: game.players.single,
          ownUnitsById: {
            'e1': Unit(
              id: 'e1',
              type: kUnitTypeExplorer,
              ownerId: playerId,
              locationProvinceId: pA,
              tileKey: tileA,
            ),
          },
          provincesById: const {},
          visibilityByTile: const {
            tileA: VisibilityLevel.unknown,
            tileB: VisibilityLevel.unknown,
          },
          prospectedTiles: const {},
          diplomacyByOtherId: const {},
        );
        final suggestions = [
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetExplore,
            targetTileKey: tileB,
          ),
          WorkOrder(
            unitId: 'e1',
            target: kWorkTargetExplore,
            targetTileKey: tileA,
          ),
        ];
        final r = selectFullAiCivilianWorkOrders(
          workSuggestions: suggestions,
          view: view,
          game: game,
        );
        expect(r.workOrders.single.targetTileKey, tileA);
        expect(r.idleEvents, isEmpty);
      },
    );

    test(
      'idle Explorer with empty explore/prospect suggestions logs no_suggestions',
      () {
        const playerId = 'gp1';
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: playerId, displayName: 'GP', isHuman: false),
          ],
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = PlayerView(
          playerId: playerId,
          player: game.players.single,
          ownUnitsById: {
            'e1': Unit(
              id: 'e1',
              type: kUnitTypeExplorer,
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
          workSuggestions: const [],
          view: view,
          game: game,
        );
        expect(r.workOrders, isEmpty);
        expect(r.idleEvents, hasLength(1));
        expect(r.idleEvents.single.unitId, 'e1');
        expect(r.idleEvents.single.reason, 'no_suggestions');
      },
    );
  });
}
