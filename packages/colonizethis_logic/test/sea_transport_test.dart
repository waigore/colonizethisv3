import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('SeaTransport', () {
    group('allocateOverseasToStockpile', () {
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
    });
  });
}
