import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('TestFixtures world state', () {
    test('emptyWorldState yields empty regions and turn state', () {
      final ws = TestFixtures.emptyWorldState(
        phase: TurnPhase.production,
        turnNumber: 7,
      );
      expect(ws.oldWorld.provinces, isEmpty);
      expect(ws.newWorld.provinces, isEmpty);
      expect(ws.turnState.phase, TurnPhase.production);
      expect(ws.turnState.turnNumber, 7);
    });

    test('worldStateAtOrdersPhase respects turnNumber and regions', () {
      const ow = RegionData(
        provinces: [
          Province(id: 'oldWorld|x', regionId: 'oldWorld', ownerId: 'o'),
        ],
      );
      final ws = TestFixtures.worldStateAtOrdersPhase(
        turnNumber: 7,
        oldWorld: ow,
      );
      expect(ws.turnState.phase, TurnPhase.orders);
      expect(ws.turnState.turnNumber, 7);
      expect(ws.oldWorld.provinces.single.id, 'oldWorld|x');
      expect(ws.newWorld.provinces, isEmpty);
    });

    test('worldStateAtOrdersPhase passes armies fleets and tile keys', () {
      const armies = [
        Army(
          id: 'a1',
          ownerId: 'p1',
          regionId: 'oldWorld',
          stationedProvinceId: 'oldWorld|p1',
          regimentUnitIds: ['r1'],
        ),
      ];
      final fleets = [
        Fleet(
          id: 'f1',
          ownerId: 'p1',
          regionId: 'oldWorld',
          seaZoneId: 'oldWorld|sea1',
        ),
      ];
      const tileKeys = {
        'oldWorld': {'oldWorld|p1': ['oldWorld|p1|0|0']},
      };
      final ws = TestFixtures.worldStateAtOrdersPhase(
        armies: armies,
        fleets: fleets,
        nextArmySeq: 3,
        tileKeysByRegionAndProvince: tileKeys,
      );
      expect(ws.armies, armies);
      expect(ws.fleets, fleets);
      expect(ws.nextArmySeq, 3);
      expect(ws.tileKeysByRegionAndProvince, tileKeys);
    });

    test('worldStateAtOrdersPhase passes sea zone names and ship seq', () {
      const names = {'oldWorld|sea1': 'North Sea'};
      final ws = TestFixtures.worldStateAtOrdersPhase(
        seaZoneDisplayNameById: names,
        nextShipInstanceSeq: 9,
      );
      expect(ws.seaZoneDisplayNameById, names);
      expect(ws.nextShipInstanceSeq, 9);
    });
  });
}
