import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Fleet', () {
    Fleet atSeaFleet() => Fleet(
          id: 'f1',
          ownerId: 'p1',
          seaZoneId: 'sz1',
          regionId: 'r1',
          ships: const [
            ShipInstance(id: 'ship_1', typeId: 'carrack'),
            ShipInstance(id: 'ship_2', typeId: 'galleon'),
          ],
          mission: FleetMission.patrol,
          targetPortId: 'r1|p1',
          targetProvinceId: 'r1|p2',
        );

    test('toJson/fromJson round-trips an at-sea fleet', () {
      final fleet = atSeaFleet();
      final restored = Fleet.fromJson(fleet.toJson());
      expect(restored, fleet);
      expect(restored.isAtSea, isTrue);
      expect(restored.isInPort, isFalse);
      expect(restored.shipTypeIds, ['carrack', 'galleon']);
      expect(restored.mission, FleetMission.patrol);
      expect(restored.targetPortId, 'r1|p1');
    });

    test('toJson omits sea zone for in-port fleet and round-trips', () {
      final fleet = Fleet(
        id: 'f2',
        ownerId: 'p1',
        inPortAtProvinceId: 'r1|p1',
        regionId: 'r1',
        ships: const [ShipInstance(id: 'ship_3', typeId: 'cog')],
      );
      final json = fleet.toJson();
      expect(json.containsKey('seaZoneId'), isFalse);
      expect(json['inPortAtProvinceId'], 'r1|p1');

      final restored = Fleet.fromJson(json);
      expect(restored.isInPort, isTrue);
      expect(restored.isAtSea, isFalse);
      expect(restored, fleet);
    });

    test('fromJson reconstructs ships from legacy shipTypeIds payload', () {
      final restored = Fleet.fromJson({
        'id': 'f3',
        'ownerId': 'p1',
        'seaZoneId': 'sz1',
        'regionId': 'r1',
        'shipTypeIds': const ['carrack', 'carrack'],
      });
      expect(restored.ships, hasLength(2));
      expect(restored.ships.first.id, 'legacy|f3|0|carrack');
      expect(restored.shipTypeIds, ['carrack', 'carrack']);
    });

    test('fromJson falls back to none mission for unknown value', () {
      final restored = Fleet.fromJson({
        'id': 'f4',
        'ownerId': 'p1',
        'seaZoneId': 'sz1',
        'regionId': 'r1',
        'ships': const [],
        'mission': 'bogus-mission',
      });
      expect(restored.mission, FleetMission.none);
    });

    test('constructor rejects passing both ships and shipTypeIds', () {
      expect(
        () => Fleet(
          id: 'f5',
          ownerId: 'p1',
          seaZoneId: 'sz1',
          regionId: 'r1',
          ships: const [ShipInstance(id: 'ship_1', typeId: 'cog')],
          shipTypeIds: const ['cog'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('legacy shipTypeIds convenience builds deterministic instances', () {
      final fleet = Fleet(
        id: 'f6',
        ownerId: 'p1',
        seaZoneId: 'sz1',
        regionId: 'r1',
        shipTypeIds: const ['galleon'],
      );
      expect(fleet.ships.single.id, 'legacy|f6|0|galleon');
    });

    test('copyWith overrides only provided fields', () {
      final fleet = atSeaFleet();
      final updated = fleet.copyWith(mission: FleetMission.blockade);
      expect(updated.mission, FleetMission.blockade);
      expect(updated.id, 'f1');
      expect(updated.ships, fleet.ships);
    });

    test('equality distinguishes differing ship lists', () {
      final fleet = atSeaFleet();
      final fewerShips = fleet.copyWith(
        ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
      );
      expect(fleet == fewerShips, isFalse);
      expect(fleet.hashCode == fewerShips.hashCode, isFalse);
    });
  });

  group('inferNextShipInstanceSeqFromFleets', () {
    test('returns max ship_<n> across fleets plus one', () {
      final fleets = [
        Fleet(
          id: 'f1',
          ownerId: 'p1',
          seaZoneId: 'sz1',
          regionId: 'r1',
          ships: const [
            ShipInstance(id: 'ship_3', typeId: 'cog'),
            ShipInstance(id: 'legacy|f1|0|cog', typeId: 'cog'),
          ],
        ),
        Fleet(
          id: 'f2',
          ownerId: 'p1',
          seaZoneId: 'sz2',
          regionId: 'r1',
          ships: const [ShipInstance(id: 'ship_7', typeId: 'galleon')],
        ),
      ];
      expect(inferNextShipInstanceSeqFromFleets(fleets), 8);
    });

    test('returns 1 when no ship_<n> ids are present', () {
      expect(inferNextShipInstanceSeqFromFleets(const []), 1);
    });
  });
}
