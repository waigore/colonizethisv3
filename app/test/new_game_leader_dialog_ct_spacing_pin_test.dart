// Pins CtSpacing adoption for the New Game leader-selection dialog padding
// (Refs #2914 S5).
//
// SPEC: SPEC/ui/pixel-art-ui-catalog.md § Spacing tokens — the shell new-game
// leader-selection dialog (DLG10001) block gaps, header band, seed/terrain
// fields, footer button gap, slot rows, and the narrow/wide slot pickers body
// use the canonical scale (`l` = 16, `ml` = 12, `m` = 8, `s` = 6, `m/2` = 4)
// instead of raw magic-number `SizedBox` / `EdgeInsets.only` literals.

import 'dart:io';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  const path = 'lib/features/shell/new_game_leader_selection_dialog.dart';

  group('New game leader dialog CtSpacing pins (Refs #2914)', () {
    test('imports the CtSpacing token scale', () {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains("import 'package:colonizethis_app/widgets/ct_spacing.dart';"),
      );
    });

    test('dialog body block gaps use CtSpacing tokens', () {
      final source = File(path).readAsStringSync();
      expect(source, contains('const SizedBox(height: CtSpacing.l)'));
      expect(source, contains('const SizedBox(height: CtSpacing.ml)'));
      // No raw magic-number vertical gaps remain in the body column.
      expect(source, isNot(contains('SizedBox(height: 16)')));
      expect(source, isNot(contains('SizedBox(height: 12)')));
    });

    test('header, seed, and terrain field gaps use CtSpacing tokens', () {
      final source = File(path).readAsStringSync();
      expect(source, contains('const SizedBox(height: CtSpacing.m)'));
      expect(source, contains('const SizedBox(height: CtSpacing.s)'));
      expect(source, contains('const SizedBox(height: CtSpacing.m / 2)'));
      expect(source, isNot(contains('SizedBox(height: 8)')));
      expect(source, isNot(contains('SizedBox(height: 6)')));
      expect(source, isNot(contains('SizedBox(height: 4)')));
    });

    test('footer + slot picker horizontal gaps use CtSpacing.m', () {
      final source = File(path).readAsStringSync();
      expect(source, contains('const SizedBox(width: CtSpacing.m)'));
      expect(source, isNot(contains('SizedBox(width: 8)')));
    });

    test('slot row bottom inset uses CtSpacing.ml', () {
      final source = File(path).readAsStringSync();
      expect(source, contains('EdgeInsets.only(bottom: CtSpacing.ml)'));
      expect(source, isNot(contains('EdgeInsets.only(bottom: 12)')));
    });

    test('stacked slot picker gap derives from CtSpacing scale', () {
      final source = File(path).readAsStringSync();
      expect(source, contains('static const double stackedGap = CtSpacing.m / 2;'));
      expect(source, isNot(contains('static const double stackedGap = 4;')));
    });
  });
}
