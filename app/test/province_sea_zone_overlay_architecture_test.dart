/// Pins the SPEC `Architecture and wiring` overlay-import contracts for
/// `ProvinceSeaZoneDetailOverlay`
/// (`SPEC/ui/province-sea-zone-detail-overlay.md` § Architecture and wiring).
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_sea_zone_overlay_architecture_support.dart';

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay does not import the Flame map widget', () {
    test('$kOverlayRelativePath contains no import of ct_region_map.dart', () {
      expectNoImportMatches(
        relativePath: kOverlayRelativePath,
        pattern: ctRegionMapImportPattern,
        reason:
            '$kOverlayRelativePath must not import `ct_region_map.dart`. '
            'SPEC/ui/province-sea-zone-detail-overlay.md § Architecture and '
            'wiring requires the overlay to remain decoupled from the '
            'Flame map widget; bridge via panel hosts and the '
            '`mapProvincePanelProvider` (Refs #2865 S1).',
      );
    });

    for (final partPath in kOverlaySectionsPartRelativePaths) {
      test('$partPath contains no import of ct_region_map.dart', () {
        expectNoImportMatches(
          relativePath: partPath,
          pattern: ctRegionMapImportPattern,
          reason:
              '$partPath must not import `ct_region_map.dart`. Even if this '
              'file is converted from a part-of fragment into a stand-alone '
              'library, the SPEC no-cross-import contract remains in force '
              '(Refs #2865 S1).',
        );
      });
    }

    for (final partPath in kOverlayEconomicUnitPartRelativePaths) {
      test('$partPath contains no import of ct_region_map.dart', () {
        expectNoImportMatches(
          relativePath: partPath,
          pattern: ctRegionMapImportPattern,
          reason:
              '$partPath must not import `ct_region_map.dart`. Even if this '
              'file is converted from a part-of fragment into a stand-alone '
              'library, the SPEC no-cross-import contract remains in force '
              '(Refs #2865 S1).',
        );
      });
    }
  });

  group('ProvinceSeaZoneDetailOverlay does not import mapProvincePanelProvider', () {
    test(
      '$kOverlayRelativePath contains no import of map_province_panel_provider.dart',
      () {
        expectNoImportMatches(
          relativePath: kOverlayRelativePath,
          pattern: mapProvincePanelProviderImportPattern,
          reason:
              '$kOverlayRelativePath must not import '
              '`map_province_panel_provider.dart`. SPEC/ui/province-sea-zone-'
              'detail-overlay.md § Architecture and wiring requires the '
              'overlay to read `displayId`, `selectedTileKey`, `playerView`, '
              'and `draftOrders` from constructor parameters supplied by the '
              'panel hosts (Refs #2865 S1).',
        );
      },
    );

    for (final partPath in kOverlaySectionsPartRelativePaths) {
      test(
        '$partPath contains no import of map_province_panel_provider.dart',
        () {
          expectNoImportMatches(
            relativePath: partPath,
            pattern: mapProvincePanelProviderImportPattern,
            reason:
                '$partPath must not import `map_province_panel_provider.dart`. '
                'The provider belongs to panel hosts only (Refs #2865 S1).',
          );
        },
      );
    }

    for (final partPath in kOverlayEconomicUnitPartRelativePaths) {
      test(
        '$partPath contains no import of map_province_panel_provider.dart',
        () {
          expectNoImportMatches(
            relativePath: partPath,
            pattern: mapProvincePanelProviderImportPattern,
            reason:
                '$partPath must not import `map_province_panel_provider.dart`. '
                'The provider belongs to panel hosts only (Refs #2865 S1).',
          );
        },
      );
    }
  });
}
