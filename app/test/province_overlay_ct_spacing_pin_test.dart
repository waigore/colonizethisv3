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
      final source = File(
        'lib/features/game/widgets/province_sea_zone_detail_overlay.dart',
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
      final source = File(
        'lib/features/game/widgets/province_sea_zone_detail_overlay_sections.dart',
      ).readAsStringSync();
      expect(source, contains('bottom: CtSpacing.ml'));
      expect(source, contains('left: CtSpacing.m / 2, top: CtSpacing.xs'));
      expect(
        source,
        isNot(contains('EdgeInsets.only(bottom: 12)')),
      );
      expect(
        source,
        isNot(contains('EdgeInsets.only(left: 4, top: 2)')),
      );
    });

    test('economic/military pending lines indent via CtSpacing.m / 2', () {
      final source = File(
        'lib/features/game/widgets/province_sea_zone_detail_overlay_economic_military_sections.dart',
      ).readAsStringSync();
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
      final source = File(
        'lib/features/game/widgets/province_sea_zone_detail_overlay.dart',
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
      final source = File(
        'lib/features/game/widgets/province_sea_zone_detail_overlay_sections.dart',
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
