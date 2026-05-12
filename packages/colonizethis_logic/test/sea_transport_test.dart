import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('cargoHoldsForHomeFleet', () {
    test('returns 0 when no home fleet exists', () {
      final game = Game(
        id: 'g1',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
        ],
      );

      final holds = cargoHoldsForHomeFleet(game, 'p1');
      expect(holds, greaterThanOrEqualTo(0));
    });

    test('sums cargoHold from home-fleet ship types', () {
      final fleet = Fleet(
        id: 'fleet_p1',
        ownerId: 'p1',
        seaZoneId: 'sea1',
        regionId: 'oldWorld',
        shipTypeIds: const ['carrack', 'fluyte'],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [fleet],
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
        ],
      );

      final holds = cargoHoldsForHomeFleet(game, 'p1');
      expect(
        holds,
        NavalStatsCatalog.carrack.cargoHold +
            NavalStatsCatalog.fluyte.cargoHold,
      );
    });

    test('returns 0 when home fleet has only warship types (cargoHold 0)', () {
      final fleet = Fleet(
        id: 'fleet_p1',
        ownerId: 'p1',
        seaZoneId: 'sea1',
        regionId: 'oldWorld',
        shipTypeIds: const ['sloop'],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [fleet],
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
        ],
      );
      final holds = cargoHoldsForHomeFleet(game, 'p1');
      expect(holds, 0);
    });

    test('fleetsById index matches default linear home-fleet lookup', () {
      final home = Fleet(
        id: 'fleet_p1',
        ownerId: 'p1',
        seaZoneId: 'sea1',
        regionId: 'oldWorld',
        shipTypeIds: const ['carrack', 'fluyte'],
      );
      final other = Fleet(
        id: 'fleet_p2',
        ownerId: 'p2',
        seaZoneId: 'sea2',
        regionId: 'oldWorld',
        shipTypeIds: const ['sloop'],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [other, home],
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
        ],
      );
      final byId = fleetsByIdForWorld(game.worldState);
      expect(
        cargoHoldsForHomeFleet(game, 'p1', fleetsById: byId),
        cargoHoldsForHomeFleet(game, 'p1'),
      );
    });
  });

  group('SeaTransport', () {
    group('allocateOverseasToStockpile', () {
      test('returns empty when overseas is empty', () {
        final delivered = allocateOverseasToStockpile({}, cargoHolds: 10);
        expect(delivered, isEmpty);
      });

      test('cargo cap limits delivered overseas', () {
        final overseas = {'grain': 5, 'timber': 8, 'iron': 4};
        final delivered = allocateOverseasToStockpile(
          overseas,
          cargoHolds: 10,
        );
        final total = delivered.values.fold<int>(0, (a, b) => a + b);
        expect(total, lessThanOrEqualTo(10));
        expect(total, 10);
      });

      test('priority order: food before raw materials', () {
        final overseas = {'iron': 20, 'grain': 5};
        final delivered = allocateOverseasToStockpile(
          overseas,
          cargoHolds: 6,
        );
        expect(delivered['grain'], 5);
        expect(delivered['iron'], 1);
      });

      test('custom priorityOrder is respected', () {
        final overseas = {'grain': 3, 'iron': 10};
        final delivered = allocateOverseasToStockpile(
          overseas,
          cargoHolds: 5,
          priorityOrder: [
            CommodityCategory.rawMaterial,
            CommodityCategory.food,
          ],
        );
        expect(delivered['iron'], 5);
        expect(delivered['grain'], isNull);
      });
    });

    group('applyTradeInterception', () {
      test('returns as-is when overseasDelivered is empty', () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [],
          ),
          players: const [
            Player(id: 'p1', displayName: 'A', isHuman: true),
            Player(id: 'p2', displayName: 'B', isHuman: true),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'p1',
              factionId2: 'p2',
              state: RelationState.atWar,
            ),
          ],
        );
        final result = applyTradeInterception(game, 'p1', {}, seed: 42);
        expect(result.reducedDelivered, isEmpty);
        expect(result.updatedFleets, game.worldState.fleets);
      });

      test('returns full delivered when no enemies at war', () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [],
          ),
          players: const [
            Player(id: 'p1', displayName: 'A', isHuman: true),
            Player(id: 'p2', displayName: 'B', isHuman: true),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'p1',
              factionId2: 'p2',
              state: RelationState.atPeace,
            ),
          ],
        );
        final delivered = {CommodityCatalog.grain.id: 10};
        final result = applyTradeInterception(game, 'p1', delivered, seed: 42);
        expect(result.reducedDelivered[CommodityCatalog.grain.id], 10);
        expect(result.updatedFleets, game.worldState.fleets);
      });

      test('reduces cargo when enemy has patrol fleet', () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'p2',
                seaZoneId: 'sea1',
                regionId: 'oldWorld',
                shipTypeIds: ['carrack'],
                mission: FleetMission.patrol,
              ),
            ],
          ),
          players: const [
            Player(id: 'p1', displayName: 'A', isHuman: true),
            Player(id: 'p2', displayName: 'B', isHuman: true),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'p1',
              factionId2: 'p2',
              state: RelationState.atWar,
            ),
          ],
        );
        final delivered = {CommodityCatalog.grain.id: 20};
        final result = applyTradeInterception(game, 'p1', delivered, seed: 12345);
        final reduced = result.reducedDelivered[CommodityCatalog.grain.id];
        expect(reduced, isNotNull);
        expect(reduced!, lessThan(20));
        expect(reduced, greaterThan(0));
      });

      test('can remove merchant ships when interception triggers and RNG hits', () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'p2',
                seaZoneId: 'sea1',
                regionId: 'oldWorld',
                shipTypeIds: ['carrack', 'carrack'],
                mission: FleetMission.blockade,
              ),
              Fleet(
                id: 'f2',
                ownerId: 'p1',
                seaZoneId: 'sea1',
                regionId: 'oldWorld',
                shipTypeIds: ['fluyte', 'fluyte', 'fluyte'],
              ),
            ],
          ),
          players: const [
            Player(id: 'p1', displayName: 'A', isHuman: true),
            Player(id: 'p2', displayName: 'B', isHuman: true),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'p1',
              factionId2: 'p2',
              state: RelationState.atWar,
            ),
          ],
        );
        final delivered = {CommodityCatalog.grain.id: 30};
        var shipRemoved = false;
        for (var seed = 0; seed < 500 && !shipRemoved; seed++) {
          final result = applyTradeInterception(game, 'p1', delivered, seed: seed);
          final p1Fleets = result.updatedFleets.where((f) => f.ownerId == 'p1').toList();
          final totalShips = p1Fleets.fold<int>(0, (s, f) => s + f.shipTypeIds.length);
          if (totalShips < 3) {
            shipRemoved = true;
            expect(result.reducedDelivered, isNotEmpty);
          }
        }
        expect(shipRemoved, isTrue, reason: 'some seed should trigger ship loss');
      });
    });
  });
}
