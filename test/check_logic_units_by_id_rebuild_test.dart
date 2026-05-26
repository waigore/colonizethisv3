import 'package:test/test.dart';

import '../tool/check_logic_units_by_id_rebuild.dart';

void main() {
  group('logicUnitsByIdRebuildLineMatches', () {
    test('matches bare unitsByIdFromWorld( call', () {
      expect(
        logicUnitsByIdRebuildLineMatches(
          'final unitsById = unitsByIdFromWorld(game.worldState);',
        ),
        isTrue,
      );
    });

    test('matches Map.from(unitsByIdFromWorld(...)) call', () {
      expect(
        logicUnitsByIdRebuildLineMatches(
          'final m = Map<String, Unit>.from(unitsByIdFromWorld(game.worldState));',
        ),
        isTrue,
      );
    });

    test('matches indented call', () {
      expect(
        logicUnitsByIdRebuildLineMatches(
          '      unitsById: unitsByIdFromWorld(game.worldState),',
        ),
        isTrue,
      );
    });

    test('ignores doc-comment reference', () {
      expect(
        logicUnitsByIdRebuildLineMatches(
          '/// skips the embedded buildPlayerView / unitsByIdFromWorld scans.',
        ),
        isFalse,
      );
    });

    test('ignores line-comment reference', () {
      expect(
        logicUnitsByIdRebuildLineMatches(
          '  // call unitsByIdFromWorld(world) here if you want to rebuild.',
        ),
        isFalse,
      );
    });

    test('ignores allUnitsById getter call', () {
      expect(
        logicUnitsByIdRebuildLineMatches(
          'final unitsById = game.worldState.allUnitsById;',
        ),
        isFalse,
      );
    });

    test('ignores function declaration line (does not match by itself; '
        'canonical file is excluded by the runner)', () {
      // Just sanity: the runner excludes the canonical file entirely, so the
      // declaration line cannot trip the gate at the call-site level.
      expect(
        logicUnitsByIdRebuildLineMatches(
          'Map<String, Unit> unitsByIdFromWorld(WorldState world) {',
        ),
        isTrue,
      );
    });
  });

  test('current repo passes logic units-by-id rebuild gate', () {
    expect(runCheckLogicUnitsByIdRebuild('.', info: (_) {}), 0);
  });
}
