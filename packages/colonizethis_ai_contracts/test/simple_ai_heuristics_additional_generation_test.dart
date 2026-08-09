import 'package:colonizethis_ai_contracts/src/ai/simple_ai_heuristics.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/simple_ai_heuristics_fixture.dart';

void main() {
  group('generateOrdersWithSimpleHeuristics', () {
    test(
      'can generate research order when only research suggestions available',
      () {
        final game = simpleAiSingleOwProvinceGame(
          player: Player(
            id: simpleAiPlayerId,
            displayName: 'AI',
            isHuman: false,
            capitalProvinceId: '$simpleAiOw|P1',
            capitalTile: const CapitalTile(
              regionId: simpleAiOw,
              provinceId: 'P1',
              x: 0,
              y: 0,
            ),
          ),
          aiSeed: 123,
        );
        final orders = generateOrdersWithSimpleHeuristics(
          game,
          simpleAiSingleProvinceTopology(),
          simpleAiPlayerId,
          turnSeedForPlayer(game, simpleAiPlayerId, 1),
        );
        expect(orders.researchOrdersByPlayerId[simpleAiPlayerId], isNotNull);
      },
    );

    test('can generate work order when only work suggestions available', () {
      const knownTileKey = '$simpleAiOw|P1|0|0';
      const unknownTileKey = '$simpleAiOw|P1|1|0';
      final game = simpleAiSingleOwProvinceGame(
        units: [
          Unit(
            id: 'u1',
            type: kUnitTypeExplorer,
            ownerId: simpleAiPlayerId,
            locationProvinceId: '$simpleAiOw|P1',
          ),
        ],
        visibility: const {knownTileKey: 'fogged', unknownTileKey: 'unknown'},
        tileKeysByProvince: const {
          '$simpleAiOw|P1': [knownTileKey, unknownTileKey],
        },
      );
      final orders = generateOrdersWithSimpleHeuristics(
        game,
        simpleAiSingleProvinceTopology(),
        simpleAiPlayerId,
        turnSeedForPlayer(game, simpleAiPlayerId, 1),
      );
      expect(
        orders.workOrdersByPlayerId[simpleAiPlayerId] ?? const [],
        isNotEmpty,
      );
    });

    test('can generate build order when only build suggestions available', () {
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      var stockpile = const Stockpile();
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value + 1);
      }
      final game = simpleAiSingleOwProvinceGame(
        player: Player(
          id: simpleAiPlayerId,
          displayName: 'AI',
          isHuman: false,
          capitalProvinceId: '$simpleAiOw|P1',
          stockpile: stockpile,
          workerPool: const WorkerPool(peasants: 3),
          treasury: econ.buildTreasuryCost + 100,
        ),
        aiSeed: 7,
      );
      final orders = generateOrdersWithSimpleHeuristics(
        game,
        simpleAiSingleProvinceTopology(),
        simpleAiPlayerId,
        turnSeedForPlayer(game, simpleAiPlayerId, 1),
      );
      expect(
        orders.buildUnitOrdersByPlayerId[simpleAiPlayerId] ?? const [],
        isNotEmpty,
      );
    });

    test(
      'diplomacy filter works when Province has local id (full id used for lookup)',
      () {
        // Game state may store Province.id as local id (e.g. P2). Order suggestion
        // emits full province id (oldWorld|P2). Owner map must key by full id.
        final game = simpleAiMilitaryOwGame(
          peerLocal: 'P2',
          localProvinceIds: true,
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: simpleAiPlayerId,
              factionId2: simpleAiPeerId,
              state: RelationState.atPeace,
            ),
          ],
        );
        final orders = generateOrdersWithSimpleHeuristics(
          game,
          simpleAiAdjacentTopology(),
          simpleAiPlayerId,
          turnSeedForPlayer(game, simpleAiPlayerId, 1),
        );
        final moves = orders.moveOrdersByPlayerId[simpleAiPlayerId] ?? [];
        for (final m in moves) {
          expect(
            Unit.provinceIdFromTileKey(m.destinationTileKey),
            isNot('$simpleAiOw|P2'),
            reason: 'validator/occupancy should not target GP at peace here',
          );
        }
      },
    );

    test('does not mutate game', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 7),
          oldWorld: const RegionData(
            provinces: [
              Province(
                id: 'P1',
                regionId: simpleAiOw,
                ownerId: simpleAiPlayerId,
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            simpleAiPlayerId: {'$simpleAiOw|P1|0|0': 'fullyVisible'},
          },
        ),
        players: const [
          Player(id: simpleAiPlayerId, displayName: 'AI', isHuman: false),
        ],
        globalGameSeed: 0,
        aiSeedByGpId: const {simpleAiPlayerId: 1},
      );
      final turnBefore = game.worldState.turnState.turnNumber;
      final playersLengthBefore = game.players.length;
      generateOrdersWithSimpleHeuristics(
        game,
        simpleAiSingleProvinceTopology(),
        simpleAiPlayerId,
        turnSeedForPlayer(game, simpleAiPlayerId, 1),
      );
      expect(game.worldState.turnState.turnNumber, equals(turnBefore));
      expect(game.players.length, equals(playersLengthBefore));
    });

    test('includes newWorld provinces in province owner map', () {
      const nw = 'newWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: const [
              Province(id: '$nw|N1', regionId: nw, ownerId: simpleAiPlayerId),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: simpleAiPlayerId,
                locationProvinceId: '$nw|N1',
              ),
            ],
          ),
          playerVisibilityByTile: const {
            simpleAiPlayerId: {'$nw|N1|0|0': 'fullyVisible'},
          },
        ),
        players: const [
          Player(id: simpleAiPlayerId, displayName: 'AI', isHuman: false),
        ],
        globalGameSeed: 0,
        aiSeedByGpId: const {simpleAiPlayerId: 1},
      );
      final orders = generateOrdersWithSimpleHeuristics(
        game,
        simpleAiSingleProvinceTopology(localId: 'N1', regionId: nw),
        simpleAiPlayerId,
        turnSeedForPlayer(game, simpleAiPlayerId, 1),
      );
      expect(orders, isNotNull);
      expect(orders.diplomaticOrdersByPlayerId, isEmpty);
    });
  });
}
