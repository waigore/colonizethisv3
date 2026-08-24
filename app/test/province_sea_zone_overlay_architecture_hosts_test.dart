/// Pins Flame-map / panel-host wiring for MAP20001 (Refs #2865, #4018, #4642).
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_sea_zone_overlay_architecture_support.dart';

void main() {
  suppressLogsForTests();

  group('CtRegionMap does not import ProvinceSeaZoneDetailOverlay', () {
    test('$kCtRegionMapRelativePath contains no import of '
        'province_sea_zone_detail_overlay.dart', () {
      expectNoImportMatches(
        relativePath: kCtRegionMapRelativePath,
        pattern: overlayImportPattern,
        reason:
            '$kCtRegionMapRelativePath must not import '
            '`province_sea_zone_detail_overlay.dart`. SPEC/ui/province-sea-'
            'zone-detail-overlay.md § Architecture and wiring keeps the '
            'Flame map widget and the overlay decoupled in both directions '
            '(Refs #2865 S1).',
      );
    });
  });

  group('Panel hosts bridge mapProvincePanelProvider → overlay', () {
    test('$kSidePanelHostRelativePath imports map_province_panel_provider and '
        'calls buildProvinceSeaZoneDetailOverlayForPanel', () {
      final code = stripOverlayArchitectureComments(
        readOverlayArchitectureSource(kSidePanelHostRelativePath),
      );
      final providerMatches = mapProvincePanelProviderImportPattern
          .allMatches(code)
          .map((m) => m.group(0)?.trim())
          .toList(growable: false);
      expect(
        providerMatches,
        isNotEmpty,
        reason:
            '$kSidePanelHostRelativePath must import '
            '`map_province_panel_provider.dart` so the wide-layout host '
            'reads the provider and projects it into constructor '
            'parameters for the overlay (SPEC § Architecture and wiring, '
            'Refs #2865 S1).',
      );
      expect(
        code.contains('buildProvinceSeaZoneDetailOverlayForPanel'),
        isTrue,
        reason:
            '$kSidePanelHostRelativePath must use the shared host factory '
            '(Refs #4018) so overlay wiring is not duplicated.',
      );
    });

    test(
      '$kNarrowOverlayHostRelativePath imports map_province_panel_provider and '
      'calls buildProvinceSeaZoneDetailOverlayForPanel',
      () {
        final code = stripOverlayArchitectureComments(
          readOverlayArchitectureSource(kNarrowOverlayHostRelativePath),
        );
        final providerMatches = mapProvincePanelProviderImportPattern
            .allMatches(code)
            .map((m) => m.group(0)?.trim())
            .toList(growable: false);
        expect(
          providerMatches,
          isNotEmpty,
          reason:
              '$kNarrowOverlayHostRelativePath must import '
              '`map_province_panel_provider.dart` so the narrow-shell host '
              'reads the provider and projects it into constructor '
              'parameters for the overlay (SPEC § Architecture and wiring, '
              'Refs #2865 S1).',
        );
        expect(
          code.contains('buildProvinceSeaZoneDetailOverlayForPanel'),
          isTrue,
          reason:
              '$kNarrowOverlayHostRelativePath must use the shared host factory '
              '(Refs #4018) so overlay wiring is not duplicated.',
        );
      },
    );
  });
}
