// Pins CtSpacing adoption for province/sea-zone overlay padding (Refs #2914 S5).
//
// SPEC: SPEC/ui/pixel-art-ui-catalog.md § Spacing tokens — header band,
// section stack, economic hover rows, and pending military/naval lines use
// the canonical scale (`ml` = 12, `m` = 8, `xs` = 2, `m/2` = 4) instead
// of raw magic-number `EdgeInsets.only` literals.

import 'dart:io';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('Province overlay CtSpacing pins (Refs #2914)', () {
    test('main overlay header uses CtSpacing.ml/m insets', () {
      // Header chrome moved to a dedicated part during #3878 overlay split (#3927).
      final source = File(
        'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_chrome.dart',
      ).readAsStringSync();
      expect(source, contains('left: CtSpacing.ml'));
      expect(source, contains('right: CtSpacing.m'));
      expect(source, contains('top: CtSpacing.m'));
      expect(
        source,
        isNot(contains('EdgeInsets.only(left: 12, right: 8, top: 8)')),
      );
    });

    test('sections layer uses CtSpacing for section stack and hover rows', () {
      final chromeSource = File(
        'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_sections_chrome.dart',
      ).readAsStringSync();
      expect(chromeSource, contains('bottom: CtSpacing.ml'));
      expect(
        chromeSource,
        isNot(contains('EdgeInsets.only(bottom: 12)')),
      );
      final economicLabelsSource = File(
        'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_sections_economic_labels.dart',
      ).readAsStringSync();
      expect(
        economicLabelsSource,
        contains('left: CtSpacing.m / 2, top: CtSpacing.xs'),
      );
      expect(
        economicLabelsSource,
        isNot(contains('EdgeInsets.only(left: 4, top: 2)')),
      );
    });

    test('economic/unit pending lines indent via CtSpacing.m / 2', () {
      final economicSource = File(
        'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_economic_section.dart',
      ).readAsStringSync();
      final unitSource = File(
        'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_military_section.dart',
      ).readAsStringSync() +
          File(
            'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_civilian_naval_sections.dart',
          ).readAsStringSync();
      final source = '$economicSource\n$unitSource';
      expect(source, contains('left: CtSpacing.m / 2'));
      expect(source, contains('bottom: CtSpacing.m'));
      expect(source, contains('SizedBox(height: CtSpacing.m / 2)'));
      expect(source, contains('SizedBox(width: CtSpacing.m / 2)'));
      expect(source, isNot(contains('EdgeInsets.only(left: 4)')));
      expect(source, isNot(contains('EdgeInsets.only(bottom: 8)')));
      expect(source, isNot(contains('SizedBox(height: 4)')));
      expect(source, isNot(contains('SizedBox(width: 4)')));
    });

    test('close button vertical padding uses CtSpacing.m / 2', () {
      // `_OverlayCloseButton` lives in the close-button part file.
      final source = File(
        'lib/features/game/widgets/province_overlay/'
        'province_sea_zone_detail_overlay_close_button.dart',
      ).readAsStringSync();
      expect(source, contains('vertical: CtSpacing.m / 2'));
      expect(
        source,
        isNot(
          contains(
            'vertical: 4,',
          ),
        ),
      );
    });

    test('tile road caption uses labelSmall TextTheme slot', () {
      // Road/rail caption styling moved to the tile-section part during the
      // #3658 overlay refactor.
      final source = File(
        'lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_tile_section_labels.dart',
      ).readAsStringSync();
      expect(source, contains('textTheme.labelSmall'));
      expect(
        source,
        isNot(
          contains(
            'TextStyle(\n    fontSize: 11,',
          ),
        ),
      );
    });
  });
}
