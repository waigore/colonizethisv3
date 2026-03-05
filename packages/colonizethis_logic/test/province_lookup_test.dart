import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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

    test('resolves short id (legacy) by searching oldWorld first', () {
      final p = getProvince(world, 'p1');
      expect(p.displayName, 'Alpha');
    });
  });

  group('resolveToFullProvinceId', () {
    test('returns as-is when prefixed', () {
      expect(resolveToFullProvinceId(world, 'oldWorld|p1'), 'oldWorld|p1');
      expect(resolveToFullProvinceId(world, 'newWorld|n1'), 'newWorld|n1');
    });

    test('resolves short id to full (oldWorld first)', () {
      expect(resolveToFullProvinceId(world, 'p1'), 'oldWorld|p1');
    });

    test('when same local id in both regions, short id resolves to first match (oldWorld)', () {
      final worldBoth = WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', displayName: 'OW p1'),
        ]),
        newWorld: RegionData(provinces: [
          Province(id: 'newWorld|p1', regionId: 'newWorld', displayName: 'NW p1'),
        ]),
      );
      expect(resolveToFullProvinceId(worldBoth, 'p1'), 'oldWorld|p1');
      expect(tryGetProvince(worldBoth, 'p1')!.displayName, 'OW p1');
    });
  });

  group('tryGetProvince short id', () {
    test('resolves short id (legacy)', () {
      expect(tryGetProvince(world, 'p1'), isNotNull);
      expect(tryGetProvince(world, 'p1')!.displayName, 'Alpha');
    });
  });

  group('getProvinceByRegion / tryGetProvinceByRegion (region-scoped)', () {
    test('getProvinceByRegion finds province only in given region', () {
      expect(getProvinceByRegion(world, 'oldWorld', 'p1').displayName, 'Alpha');
      expect(getProvinceByRegion(world, 'newWorld', 'n1').displayName, 'Gamma');
    });
    test('getProvinceByRegion throws for wrong region', () {
      expect(
        () => getProvinceByRegion(world, 'newWorld', 'p1'),
        throwsStateError,
      );
    });
    test('tryGetProvinceByRegion returns null for missing in region', () {
      expect(tryGetProvinceByRegion(world, 'oldWorld', 'missing'), isNull);
      expect(tryGetProvinceByRegion(world, 'unknownRegion', 'p1'), isNull);
    });
    test('getProvince(fullId) delegates to region-scoped lookup', () {
      expect(getProvince(world, 'oldWorld|p1').displayName, 'Alpha');
      expect(getProvince(world, 'newWorld|n1').displayName, 'Gamma');
    });
  });
}
