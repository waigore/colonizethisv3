import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('applyBuildAndWorkOrders work order application (part 4)', () {
    const ow = 'oldWorld';
    const provinceId = 'oldWorld|P1';
    const tileKey = 'oldWorld|P1|0|0';

    test('unknown work target is skipped and unit stays idle', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: 'unknown_target',
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      final u = next.worldState.oldWorld.units.single;
      expect(u.status, UnitStatus.idle);
      expect(u.currentWork, isNull);
    });

    test(
      'build_road with insufficient materials does not set currentWork or deduct stockpile',
      () {
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeEngineer,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            const Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              stockpile: Stockpile(),
            ),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'u1',
                target: kWorkTargetBuildRoad,
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        final u = next.worldState.oldWorld.units.single;
        expect(u.currentWork, isNull);
        expect(u.status, UnitStatus.idle);
        expect(
          next.players.single.stockpile.quantityOf(CommodityCatalog.lumber.id),
          0,
        );
      },
    );

    test(
      'build_road with sufficient materials deducts materials and sets currentWork',
      () {
        final unit = Unit(
          id: 'u1',
          type: kUnitTypeEngineer,
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        );
        final cost = workOrderCostBuildRoad;
        var stockpile = const Stockpile();
        for (final e in cost.entries) {
          stockpile = stockpile.applyDelta(e.key, e.value);
        }
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              stockpile: stockpile,
            ),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'u1',
                target: kWorkTargetBuildRoad,
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        final u = next.worldState.oldWorld.units.single;
        // build_road totalTurns=1, so work completes in same phase; unit idle and road level 1.
        expect(u.currentWork, isNull);
        expect(u.status, UnitStatus.idle);
        expect(next.worldState.tileState.roadLevel(tileKey), 1);
        for (final e in cost.entries) {
          expect(
            next.players.single.stockpile.quantityOf(e.key),
            game.players.single.stockpile.quantityOf(e.key) - e.value,
          );
        }
      },
    );
  });
}
