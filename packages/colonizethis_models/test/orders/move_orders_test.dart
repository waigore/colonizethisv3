import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('MoveOrder', () {
    test('toJson/fromJson round-trips by tile key', () {
      const order = MoveOrder(unitId: 'u1', destinationTileKey: 'r1|p1|2|3');
      final restored = MoveOrder.fromJson(order.toJson());
      expect(restored, order);
      expect(restored.destinationTileKey, 'r1|p1|2|3');
    });

    test('fromJson converts a legacy prefixed destinationProvinceId', () {
      final restored = MoveOrder.fromJson({
        'unitId': 'u1',
        'destinationProvinceId': 'r1|p7',
      });
      expect(restored.destinationTileKey, 'r1|p7|0|0');
    });

    test('fromJson rejects a legacy unprefixed destinationProvinceId', () {
      expect(
        () => MoveOrder.fromJson({
          'unitId': 'u1',
          'destinationProvinceId': 'p7',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson throws when no destination is provided', () {
      expect(
        () => MoveOrder.fromJson({'unitId': 'u1'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('equality and hashCode', () {
      const a = MoveOrder(unitId: 'u1', destinationTileKey: 'r1|p1|0|0');
      const b = MoveOrder(unitId: 'u1', destinationTileKey: 'r1|p1|0|0');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == const MoveOrder(unitId: 'u2', destinationTileKey: 'r1|p1|0|0'),
          isFalse);
    });
  });

  group('ArmyMoveOrder', () {
    test('toJson/fromJson round-trips', () {
      const order = ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'r1|p1');
      final restored = ArmyMoveOrder.fromJson(order.toJson());
      expect(restored, order);
    });

    test('fromJson requires a prefixed destination province id', () {
      expect(
        () => ArmyMoveOrder.fromJson({
          'armyId': 'a1',
          'destinationProvinceId': 'p1',
        }),
        throwsA(anything),
      );
    });

    test('equality and hashCode', () {
      const a = ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'r1|p1');
      expect(a.hashCode,
          const ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'r1|p1')
              .hashCode);
      expect(
          a ==
              const ArmyMoveOrder(
                  armyId: 'a1', destinationProvinceId: 'r1|p2'),
          isFalse);
    });
  });

  group('NavalMoveOrder', () {
    test('move-to-sea round-trips and is not a dock', () {
      const order = NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sz1');
      final restored = NavalMoveOrder.fromJson(order.toJson());
      expect(restored.destinationSeaZoneId, 'sz1');
      expect(restored.destinationPortProvinceId, isNull);
      expect(restored.isDock, isFalse);
      expect(restored, order);
    });

    test('dock order round-trips and clears sea zone', () {
      const order = NavalMoveOrder(
        fleetId: 'f1',
        destinationPortProvinceId: 'r1|p1',
      );
      final restored = NavalMoveOrder.fromJson(order.toJson());
      expect(restored.isDock, isTrue);
      expect(restored.destinationPortProvinceId, 'r1|p1');
      expect(restored.destinationSeaZoneId, isNull);
    });

    test('fromJson throws when neither destination is set', () {
      expect(
        () => NavalMoveOrder.fromJson({'fleetId': 'f1'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('equality and hashCode', () {
      const a = NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sz1');
      const b = NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sz1');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('NavalMissionOrder', () {
    test('toJson omits null targets and round-trips', () {
      const order = NavalMissionOrder(fleetId: 'f1', mission: 'patrol');
      final json = order.toJson();
      expect(json.containsKey('targetPortId'), isFalse);
      expect(json.containsKey('targetProvinceId'), isFalse);
      expect(NavalMissionOrder.fromJson(json), order);
    });

    test('fromJson defaults mission to none when absent', () {
      final restored = NavalMissionOrder.fromJson({'fleetId': 'f1'});
      expect(restored.mission, 'none');
    });

    test('round-trips with targets and equality', () {
      const order = NavalMissionOrder(
        fleetId: 'f1',
        mission: 'blockade',
        targetPortId: 'r1|p1',
        targetProvinceId: 'r1|p2',
      );
      final restored = NavalMissionOrder.fromJson(order.toJson());
      expect(restored, order);
      expect(restored.hashCode, order.hashCode);
    });
  });
}
