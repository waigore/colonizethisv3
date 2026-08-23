// Extracted from e2e_shared_lib_topic_split_test.dart (#4598 Slice C).
library;

import 'dart:io';

import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

import 'e2e_support_package_root.dart';

void registerE2eSharedLibTopicSplitPanelsGuardGroup() {
  final libDir = Directory(p.join(e2eSupportPackageRoot().path, 'lib'));

  group('e2e_test_shared_panels topic split (Refs #4075 AC1 / AC2)', () {
    test(
      'panels umbrella exports production/fleet/explore topic libraries',
      () {
        final barrel = File(
          p.join(libDir.path, 'e2e_test_shared_panels.dart'),
        ).readAsStringSync();
        for (final export in <String>[
          "export 'e2e_test_shared_production_panel.dart';",
          "export 'e2e_test_shared_split_home_fleet.dart';",
          "export 'e2e_test_shared_explore_assign.dart';",
        ]) {
          expect(barrel, contains(export));
        }
      },
    );

    test('panels umbrella stays under the former god-file physical size', () {
      final lines = File(
        p.join(libDir.path, 'e2e_test_shared_panels.dart'),
      ).readAsLinesSync().length;
      expect(lines, lessThanOrEqualTo(300));
    });

    test('negative: panels topic libraries exist as distinct files', () {
      for (final name in <String>[
        'e2e_test_shared_production_panel.dart',
        'e2e_test_shared_split_home_fleet.dart',
        'e2e_test_shared_explore_assign.dart',
      ]) {
        final file = File(p.join(libDir.path, name));
        expect(file.existsSync(), isTrue, reason: '$name missing');
        expect(file.readAsLinesSync(), isNotEmpty);
      }
    });

    test('naval move topic split exports sibling modules (Refs #4195)', () {
      final barrel = File(
        p.join(libDir.path, 'e2e_test_shared_naval_move.dart'),
      ).readAsStringSync();
      for (final export in <String>[
        "export 'e2e_test_shared_naval_move_tap.dart';",
        "export 'e2e_test_shared_naval_move_pick.dart';",
        "export 'e2e_test_shared_naval_move_segment.dart';",
      ]) {
        expect(barrel, contains(export));
      }
      for (final name in <String>[
        'e2e_test_shared_naval_move_tap.dart',
        'e2e_test_shared_naval_move_pick.dart',
        'e2e_test_shared_naval_move_segment.dart',
      ]) {
        final file = File(p.join(libDir.path, name));
        expect(file.existsSync(), isTrue, reason: '$name missing');
        final lines = file.readAsLinesSync().length;
        expect(
          lines,
          lessThanOrEqualTo(300),
          reason: '$name still over wave-3 300 cap',
        );
      }
    });

    test(
      'slice B residual lib files stay under 300 physical lines (Refs #4195)',
      () {
        for (final name in <String>[
          'e2e_test_shared.dart',
          'e2e_test_shared_adaptive_polling.dart',
          'e2e_test_shared_explore_assign.dart',
          'e2e_test_shared_explore_assign_sweep.dart',
          'e2e_test_shared_explore_assign_bundled.dart',
          'test_support/civilian_units_panel_e2e_expected_lines.dart',
          'test_support/civilian_units_panel_e2e_expected_lines_assigned.dart',
          'test_support/civilian_units_panel_e2e_expected_lines_rows.dart',
        ]) {
          final file = File(p.join(libDir.path, name));
          expect(file.existsSync(), isTrue, reason: '$name missing');
          final lines = file.readAsLinesSync().length;
          expect(
            lines,
            lessThanOrEqualTo(300),
            reason: '$name still over wave-3 300 cap',
          );
        }
      },
    );

    test(
      'explore assign topic split exports sibling modules (Refs #4195 slice B)',
      () {
        final barrel = File(
          p.join(libDir.path, 'e2e_test_shared_explore_assign.dart'),
        ).readAsStringSync();
        for (final export in <String>[
          "export 'e2e_test_shared_explore_assign_sweep.dart';",
          "export 'e2e_test_shared_explore_assign_bundled.dart';",
        ]) {
          expect(barrel, contains(export));
        }
      },
    );

    test(
      'shared umbrella exports adaptive polling sibling (Refs #4195 slice B)',
      () {
        final barrel = File(
          p.join(libDir.path, 'e2e_test_shared.dart'),
        ).readAsStringSync();
        expect(
          barrel,
          contains("export 'e2e_test_shared_adaptive_polling.dart';"),
        );
      },
    );

    test(
      'slice D test mirror files stay under 400 physical lines (Refs #4344)',
      () {
        final testDir = Directory(p.join(e2eSupportPackageRoot().path, 'test'));
        final oversized = <String>[];
        for (final file
            in testDir.listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) continue;
          final lines = file.readAsLinesSync().length;
          if (lines > 400) {
            oversized.add(
              '${p.relative(file.path, from: testDir.path)} ($lines)',
            );
          }
        }
        expect(oversized, isEmpty, reason: 'All test files must be ≤500 lines');
      },
    );

    test('wave-3 Slice B hit_testable_scroll topic split (Refs #4344 AC3)', () {
      final barrel = File(
        p.join(libDir.path, 'e2e_test_shared_hit_testable_scroll.dart'),
      ).readAsStringSync();
      for (final export in <String>[
        "export 'e2e_test_shared_hit_testable_tap.dart';",
        "export 'e2e_test_shared_hit_testable_civilian_menu.dart';",
        "export 'e2e_test_shared_hit_testable_scroll_gestures.dart';",
      ]) {
        expect(barrel, contains(export));
      }
      for (final name in <String>[
        'e2e_test_shared_hit_testable_tap.dart',
        'e2e_test_shared_hit_testable_civilian_menu.dart',
        'e2e_test_shared_hit_testable_scroll_gestures.dart',
      ]) {
        final file = File(p.join(libDir.path, name));
        expect(file.existsSync(), isTrue, reason: '$name missing');
        expect(
          file.readAsLinesSync().length,
          lessThanOrEqualTo(300),
          reason: '$name over Slice B lib cap',
        );
      }
    });

    test(
      'wave-3 Slice B standard_scenario_opener topic split (Refs #4344 AC3)',
      () {
        final barrel = File(
          p.join(libDir.path, 'e2e_test_shared_standard_scenario_opener.dart'),
        ).readAsStringSync();
        for (final export in <String>[
          "export 'e2e_test_shared_standard_scenario_opener_constants.dart';",
          "export 'e2e_test_shared_standard_scenario_opener_result.dart';",
          "export 'e2e_test_shared_standard_scenario_opener_enter.dart';",
        ]) {
          expect(barrel, contains(export));
        }
      },
    );

    test('wave-3 Slice B naval_move_pick topic split (Refs #4344 AC3)', () {
      final barrel = File(
        p.join(libDir.path, 'e2e_test_shared_naval_move_pick.dart'),
      ).readAsStringSync();
      for (final export in <String>[
        "export 'e2e_test_shared_naval_move_pick_confirm.dart';",
        "export 'e2e_test_shared_naval_move_pick_sea.dart';",
      ]) {
        expect(barrel, contains(export));
      }
    });

    test('wave-3 Slice B residual target libs stay ≤300 (Refs #4344)', () {
      for (final name in <String>[
        'e2e_test_shared_hit_testable_scroll.dart',
        'e2e_test_shared_standard_scenario_opener.dart',
        'e2e_test_shared_naval_move_pick.dart',
        'e2e_helpers_aliases_ui.dart',
        'e2e_helpers_aliases_ui_wait.dart',
        'e2e_helpers_aliases_ui_panels.dart',
        'e2e_test_shared_fleet_reach_scenario_preamble.dart',
        'e2e_test_shared_fleet_reach_scenario_preamble_constants.dart',
        'e2e_test_shared_fleet_reach_scenario_preamble_enter.dart',
        'e2e_test_shared_fleet_reach_scenario_preamble_result.dart',
        'e2e_test_shared_standard_scenario_opener_constants.dart',
        'e2e_test_shared_standard_scenario_opener_enter.dart',
        'e2e_test_shared_standard_scenario_opener_result.dart',
        'e2e_test_shared_naval_move_pick_confirm.dart',
        'e2e_test_shared_naval_move_pick_sea.dart',
      ]) {
        final file = File(p.join(libDir.path, name));
        expect(file.existsSync(), isTrue, reason: '$name missing');
        final lines = file.readAsLinesSync().length;
        expect(lines, lessThanOrEqualTo(300), reason: '$name still over 300');
      }
    });

    test('wave-4 Slice A topic splits stay ≤250 (Refs #4598)', () {
      final barrel = File(
        p.join(libDir.path, 'e2e_test_shared_adaptive_polling.dart'),
      ).readAsStringSync();
      expect(
        barrel,
        contains("export 'e2e_test_shared_adaptive_polling_core.dart';"),
      );
      expect(
        barrel,
        contains("export 'e2e_test_shared_adaptive_polling_waits.dart';"),
      );
      for (final name in <String>[
        'e2e_test_shared_adaptive_polling.dart',
        'e2e_test_shared_adaptive_polling_core.dart',
        'e2e_test_shared_adaptive_polling_waits.dart',
        'e2e_test_shared_fleet_reach_loop.dart',
        'e2e_test_shared_fleet_reach_loop_types.dart',
        'e2e_test_shared_first_fleet_move.dart',
        'e2e_test_shared_first_fleet_move_types.dart',
        'e2e_test_shared_fleet_reach_nw_snapshot.dart',
        'e2e_test_shared_fleet_reach_nw_coastal.dart',
        'e2e_test_shared_panel_open_outer_loop.dart',
        'e2e_test_shared_panel_open_outer_loop_body.dart',
        'e2e_helpers_aliases_orders.dart',
        'test_support/production_panel_e2e_expected_lines.dart',
        'test_support/production_panel_e2e_expected_lines_available.dart',
        'test_support/production_panel_e2e_expected_lines_allocation.dart',
        'test_support/province_panel_e2e_expected_lines_ctx.dart',
        'test_support/province_panel_e2e_expected_lines_road.dart',
      ]) {
        final file = File(p.join(libDir.path, name));
        expect(file.existsSync(), isTrue, reason: '$name missing');
        final lines = file.readAsLinesSync().length;
        expect(lines, lessThanOrEqualTo(250), reason: '$name still over 250');
      }
    });
  });
}
