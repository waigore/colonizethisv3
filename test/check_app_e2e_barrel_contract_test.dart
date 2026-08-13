// Static contract pins for the colonizethis_app_e2e_support public barrel.
// Flutter-level tear-off pins live in app/test/e2e_helpers_barrel_part1_test.dart.
// Refs #3878 Phase 1.
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final repoRoot = p.normalize(p.join(Directory.current.path));
  final supportLib = p.join(
    repoRoot,
    'packages/colonizethis_app_e2e_support/lib',
  );

  group('colonizethis_app_e2e_support barrel contract', () {
    test('e2e_helpers.dart exports AC1 public names', () {
      final barrel = File(p.join(supportLib, 'e2e_helpers.dart'));
      expect(barrel.existsSync(), isTrue, reason: 'AC1 barrel must exist');
      final text = barrel.readAsStringSync();
      // Shared re-exports stay in the facade; AC1 aliases live in topic
      // libraries re-exported from here (Refs #4075 AC3).
      for (final symbol in [
        'E2ePerfLog',
        'kE2eMaxWallClock',
        'kE2eNextTurnResolutionTimeout',
        "export 'e2e_helpers_aliases_ui.dart';",
        "export 'e2e_helpers_aliases_orders.dart';",
        "export 'e2e_helpers_aliases_scenario.dart';",
      ]) {
        expect(
          text,
          contains(symbol),
          reason: 'e2e_helpers.dart must expose $symbol for AC1 scenarios',
        );
      }
      final aliasSurface = [
        File(p.join(supportLib, 'e2e_helpers_aliases_ui.dart')),
        File(p.join(supportLib, 'e2e_helpers_aliases_ui_wait.dart')),
        File(p.join(supportLib, 'e2e_helpers_aliases_ui_panels.dart')),
        File(p.join(supportLib, 'e2e_helpers_aliases_orders.dart')),
        File(p.join(supportLib, 'e2e_helpers_aliases_scenario.dart')),
      ].map((f) => f.readAsStringSync()).join('\n');
      for (final symbol in [
        'Future<void> pumpFor',
        'Future<void> waitUntilFound',
        'bootstrapNewGameToMap',
        'openCivilianPanel',
        'openNavalPanel',
        'openProductionPanel',
        'advanceOneHumanTurn',
      ]) {
        expect(
          aliasSurface,
          contains(symbol),
          reason: 'AC1 alias libraries must define $symbol',
        );
      }
    });

    test('support package hosts shared implementation libraries', () {
      for (final name in [
        'e2e_test_shared.dart',
        'e2e_test_shared_bootstrap.dart',
        'e2e_test_shared_panels.dart',
      ]) {
        expect(
          File(p.join(supportLib, name)).existsSync(),
          isTrue,
          reason: '$name must live under colonizethis_app_e2e_support/lib',
        );
      }
    });

    test('panel expected-line fixtures live under support test_support/', () {
      final fixtureDir = p.join(supportLib, 'test_support');
      for (final name in [
        'civilian_units_panel_e2e_expected_lines.dart',
        'naval_units_panel_e2e_expected_lines.dart',
        'production_panel_e2e_expected_lines.dart',
        'province_panel_e2e_expected_lines.dart',
      ]) {
        expect(
          File(p.join(fixtureDir, name)).existsSync(),
          isTrue,
          reason: '$name must be relocated to the support package',
        );
      }
    });
  });
}
