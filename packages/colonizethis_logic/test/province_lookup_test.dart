import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  final world = WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [
      Province(id: 'oldWorld|p1', regionId: 'oldWorld', displayName: 'Alpha'),
      Province(id: 'oldWorld|p2', regionId: 'oldWorld', displayName: 'Beta'),
    ]),
    newWorld: RegionData(provinces: [
      Province(id: 'newWorld|n1', regionId: 'newWorld', displayName: 'Gamma'),
    ]),
  );

  group('tryGetProvince', () {
    test('finds OW province by full prefixed id', () {
      final p = tryGetProvince(world, 'oldWorld|p1');
      expect(p, isNotNull);
      expect(p!.displayName, 'Alpha');
    });

    test('finds NW province by full prefixed id', () {
      final p = tryGetProvince(world, 'newWorld|n1');
      expect(p, isNotNull);
      expect(p!.displayName, 'Gamma');
    });

    test('returns null for unknown province id', () {
      expect(tryGetProvince(world, 'oldWorld|missing'), isNull);
    });

    test('returns null for unknown region', () {
      expect(tryGetProvince(world, 'unknownRegion|p1'), isNull);
    });

    test('returns null for empty id', () {
      expect(tryGetProvince(world, ''), isNull);
    });
  });

  group('getProvince', () {
    test('finds OW province by full prefixed id', () {
      final p = getProvince(world, 'oldWorld|p1');
      expect(p.displayName, 'Alpha');
    });

    test('throws StateError for unknown province', () {
      expect(
        () => getProvince(world, 'oldWorld|missing'),
        throwsStateError,
      );
    });
  });
}
