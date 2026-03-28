import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('shipInstancesForTransferCounts', () {
    test('takes first N per type in fleet order', () {
      final fleet = Fleet(
        id: 'f1',
        ownerId: 'p1',
        regionId: 'oldWorld',
        inPortAtProvinceId: 'oldWorld|cap',
        shipTypeIds: ['carrack', 'carrack', 'carrack', 'fluyte'],
      );
      final moved = shipInstancesForTransferCounts(fleet.ships, {
        'carrack': 2,
        'fluyte': 1,
      });
      expect(moved.length, 3);
      expect(moved.where((s) => s.typeId == 'carrack').length, 2);
      expect(moved.where((s) => s.typeId == 'fluyte').length, 1);
      expect(moved.map((s) => s.id).toSet().length, 3);
    });
  });

  group('Fleet.fromJson', () {
    test('migrates legacy shipTypeIds to instances with stable ids', () {
      final f = Fleet.fromJson({
        'id': 'home',
        'ownerId': 'p1',
        'regionId': 'oldWorld',
        'inPortAtProvinceId': 'oldWorld|x',
        'shipTypeIds': ['carrack', 'carrack'],
        'mission': 'none',
      });
      expect(f.ships.length, 2);
      expect(f.ships[0].id, 'legacy|home|0|carrack');
      expect(f.ships[1].id, 'legacy|home|1|carrack');
      expect(f.shipTypeIds, ['carrack', 'carrack']);
    });

    test('reads canonical ships array', () {
      final f = Fleet.fromJson({
        'id': 'f2',
        'ownerId': 'p1',
        'regionId': 'oldWorld',
        'seaZoneId': 's1',
        'ships': [
          {'id': 'ship_1', 'typeId': 'carrack'},
          {'id': 'ship_2', 'typeId': 'carrack'},
        ],
        'mission': 'none',
      });
      expect(f.ships.map((s) => s.id).toList(), ['ship_1', 'ship_2']);
    });
  });

  group('inferNextShipInstanceSeqFromFleets', () {
    test('returns max ship_n plus one', () {
      final fleets = [
        Fleet(
          id: 'a',
          ownerId: 'p1',
          regionId: 'oldWorld',
          seaZoneId: 'z',
          ships: const [
            ShipInstance(id: 'ship_5', typeId: 'carrack'),
            ShipInstance(id: 'legacy|x|0|fluyte', typeId: 'fluyte'),
          ],
        ),
      ];
      expect(inferNextShipInstanceSeqFromFleets(fleets), 6);
    });
  });

  group('split and combine instance integrity', () {
    test('split by instance id leaves correct remainder and moving sets', () {
      final original = Fleet(
        id: 'fleet_p1',
        ownerId: 'p1',
        regionId: 'oldWorld',
        inPortAtProvinceId: 'oldWorld|c1',
        shipTypeIds: ['carrack', 'carrack', 'carrack'],
      );
      final toNewIds = original.ships.take(2).map((s) => s.id).toList();
      final idSet = toNewIds.toSet();
      final moving = original.ships.where((s) => idSet.contains(s.id)).toList();
      final remaining = original.ships.where((s) => !idSet.contains(s.id)).toList();
      expect(remaining.length, 1);
      expect(moving.length, 2);
      expect(remaining.single.typeId, 'carrack');
      final unionIds = {...moving.map((s) => s.id), ...remaining.map((s) => s.id)};
      expect(unionIds.length, 3);
    });

    test('combine concatenates instances without dropping ids', () {
      final a = Fleet(
        id: '1',
        ownerId: 'p1',
        regionId: 'oldWorld',
        inPortAtProvinceId: 'oldWorld|p',
        shipTypeIds: ['carrack'],
      );
      final b = Fleet(
        id: '2',
        ownerId: 'p1',
        regionId: 'oldWorld',
        inPortAtProvinceId: 'oldWorld|p',
        shipTypeIds: ['carrack', 'fluyte'],
      );
      final combined = [...a.ships, ...b.ships];
      expect(combined.length, 3);
      expect(combined.map((s) => s.id).toSet().length, 3);
    });
  });
}
