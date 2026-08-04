import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_region_map.dart';
import 'package:colonizethis_app/widgets/ct_region_map_state.dart';
import 'package:colonizethis_app/widgets/ct_region_map_state_handlers.dart';

/// De-parted [CtRegionMap] library seam checks (Refs #4117).
void main() {
  suppressLogsForTests();

  group('CtRegionMap modular split (Refs #4117)', () {
    test('widget and implementation libraries are importable', () {
      expect(CtRegionMap, isNotNull);
      expect(CtRegionMapState, isNotNull);
      expect(buildCtRegionMapGame, isNotNull);
      expect(attachCtRegionMapMinimapCameraBusSubscriptions, isNotNull);
      expect(handleCtRegionMapCivilianTileTapped, isNotNull);
    });
  });
}
