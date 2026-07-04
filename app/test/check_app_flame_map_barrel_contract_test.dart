import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/map_area/map_area.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart';

/// Barrel export contract for flame map submodules (Refs #3878 Phase 3).
void main() {
  suppressLogsForTests();

  test('map_area barrel exports GameMapArea stack', () {
    expect(GameMapArea, isNotNull);
    expect(GameMapAreaStateLogic, isNotNull);
    expect(GameMapAreaBackground, isNotNull);
  });

  test('region_map barrel exports CtRegionMapComponent stack', () {
    expect(CtRegionMapComponent, isNotNull);
    expect(RegionMapViewportSnapshot, isNotNull);
  });
}
