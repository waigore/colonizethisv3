import 'package:test/test.dart';

import '../tool/check_logic_dual_region_province_field_access.dart';

void main() {
  group('logicDualRegionProvinceFieldAccessLineMatches', () {
    test('matches oldWorld.provinces', () {
      expect(
        logicDualRegionProvinceFieldAccessLineMatches(
          'for (final p in game.worldState.oldWorld.provinces) {',
        ),
        isTrue,
      );
    });

    test('matches newWorld.provinces', () {
      expect(
        logicDualRegionProvinceFieldAccessLineMatches(
          'game.worldState.newWorld.provinces',
        ),
        isTrue,
      );
    });

    test('matches oldWorld.units', () {
      expect(
        logicDualRegionProvinceFieldAccessLineMatches(
          'for (final u in game.worldState.oldWorld.units) {',
        ),
        isTrue,
      );
    });

    test('matches newWorld.units', () {
      expect(
        logicDualRegionProvinceFieldAccessLineMatches(
          'game.worldState.newWorld.units',
        ),
        isTrue,
      );
    });

    test('matches manual regionId old-world branching', () {
      expect(
        logicDualRegionProvinceFieldAccessLineMatches(
          'if (regionId == kRegionOldWorld) {',
        ),
        isTrue,
      );
    });

    test('ignores allProvinces', () {
      expect(
        logicDualRegionProvinceFieldAccessLineMatches(
          'for (final p in allProvinces(game.worldState)) {',
        ),
        isFalse,
      );
    });

    test('ignores allUnits', () {
      expect(
        logicDualRegionProvinceFieldAccessLineMatches(
          'for (final u in allUnits(game.worldState)) {',
        ),
        isFalse,
      );
    });
  });

  test('current repo passes dual-region province field access gate', () {
    expect(runCheckLogicDualRegionProvinceFieldAccess('.', info: (_) {}), 0);
  });
}
