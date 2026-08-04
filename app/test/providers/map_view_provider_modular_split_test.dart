import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/providers/map_view_provider.dart';

/// De-parted map-view-provider library seam checks (Refs #4117).
void main() {
  suppressLogsForTests();

  group('MapViewProvider modular split (Refs #4117)', () {
    test('barrel and submodule providers are importable', () {
      expect(mapViewDataProvider, isNotNull);
      expect(mapProvinceOverlayVisibleProvider, isNotNull);
      expect(mapProvinceOwnershipTintVisibleProvider, isNotNull);
      expect(mapProvinceNamesVisibleProvider, isNotNull);
      expect(MapResourceExtractionMaps.empty.unitsByTile, isEmpty);
      expect(mapViewBuildResourceExtractionMaps, isNotNull);
      expect(civilianMarkerOwnerIdsFor, isNotNull);
    });
  });
}
