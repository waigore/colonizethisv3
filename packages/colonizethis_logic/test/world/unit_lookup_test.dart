import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('WorldStateUnitLookup.tryGetUnitById', () {
    const turn = TurnState(phase: TurnPhase.orders, turnNumber: 0);
    final uOld = Unit(
      id: 'u-old',
      type: kUnitTypeExplorer,
      ownerId: 'p1',
      locationProvinceId: 'oldWorld|P1',
      tileKey: 'oldWorld|P1|0|0',
    );
    final uNew = Unit(
      id: 'u-new',
      type: kUnitTypeExplorer,
      ownerId: 'p1',
      locationProvinceId: 'newWorld|P2',
      tileKey: 'newWorld|P2|0|0',
    );

    test('returns unit from old world when present', () {
      final ws = WorldState(
        turnState: turn,
        oldWorld: RegionData(units: [uOld]),
        newWorld: const RegionData(),
      );
      expect(ws.tryGetUnitById('u-old'), uOld);
    });

    test('returns unit from new world when not in old world', () {
      final ws = WorldState(
        turnState: turn,
        oldWorld: const RegionData(),
        newWorld: RegionData(units: [uNew]),
      );
      expect(ws.tryGetUnitById('u-new'), uNew);
    });

    test('returns null when id is absent', () {
      final ws = WorldState(
        turnState: turn,
        oldWorld: RegionData(units: [uOld]),
        newWorld: RegionData(units: [uNew]),
      );
      expect(ws.tryGetUnitById('none'), isNull);
    });

    test('prefers old world when both lists contain the same id', () {
      final inOld = Unit(
        id: 'dup',
        type: kUnitTypeExplorer,
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|P1',
        tileKey: 'oldWorld|P1|0|0',
      );
      final inNew = Unit(
        id: 'dup',
        type: kUnitTypeBuilder,
        ownerId: 'p2',
        locationProvinceId: 'newWorld|P2',
        tileKey: 'newWorld|P2|0|0',
      );
      final ws = WorldState(
        turnState: turn,
        oldWorld: RegionData(units: [inOld]),
        newWorld: RegionData(units: [inNew]),
      );
      expect(ws.tryGetUnitById('dup')!.type, kUnitTypeExplorer);
    });
  });
}
