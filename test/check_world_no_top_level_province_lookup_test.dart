import 'package:test/test.dart';

import '../tool/check_world_no_top_level_province_lookup.dart';

void main() {
  group('findWorldTopLevelProvinceLookupViolations', () {
    test('flags reintroduced wrapper definitions in province_lookup.dart', () {
      const src = r'''
Province getProvince(WorldState world, String fullProvinceId) =>
    world.getProvince(fullProvinceId);
''';
      final violations = findWorldTopLevelProvinceLookupViolations(
        relativePath: provinceLookupCanonicalPath,
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.kind, 'definition');
      expect(violations.single.symbol, 'getProvince');
    });

    test('ignores files outside the world lib tree', () {
      const src = r'''
void f(Game game, String id) {
  tryGetProvince(game.worldState, id);
}
''';
      final violations = findWorldTopLevelProvinceLookupViolations(
        relativePath: 'packages/colonizethis_turn/lib/src/turn/x.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('flags an unqualified top-level call inside the world layer', () {
      const src = r'''
String? f(Game game, String id) {
  return tryGetProvince(game.worldState, id)?.ownerId;
}
''';
      final violations = findWorldTopLevelProvinceLookupViolations(
        relativePath:
            'packages/colonizethis_world/lib/src/world/civilian_tile_occupancy.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.symbol, 'tryGetProvince');
      expect(violations.single.kind, 'call');
    });

    test('accepts the extension-method form (qualified call target)', () {
      const src = r'''
String? f(Game game, String id) {
  return game.worldState.tryGetProvince(id)?.ownerId;
}

bool g(WorldState ws, String id) => ws.getProvince(id).fortLevel > 0;
''';
      final violations = findWorldTopLevelProvinceLookupViolations(
        relativePath:
            'packages/colonizethis_world/lib/src/world/civilian_tile_occupancy.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('flags each of the four deprecated symbols as calls', () {
      const src = r'''
void f(WorldState ws) {
  getProvince(ws, 'ow|p1');
  tryGetProvince(ws, 'ow|p1');
  getProvinceByRegion(ws, 'ow', 'p1');
  tryGetProvinceByRegion(ws, 'ow', 'p1');
}
''';
      final violations = findWorldTopLevelProvinceLookupViolations(
        relativePath: 'packages/colonizethis_world/lib/src/world/player_view.dart',
        source: src,
      );
      expect(violations.map((v) => v.symbol).toSet(), {
        'getProvince',
        'tryGetProvince',
        'getProvinceByRegion',
        'tryGetProvinceByRegion',
      });
    });
  });
}
