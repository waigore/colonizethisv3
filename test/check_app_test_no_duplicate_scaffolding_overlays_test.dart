import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_test_no_duplicate_scaffolding.dart';

void _writeGovernedFile(Directory temp, String name, String contents) {
  File('${temp.path}/app/test/$name')
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}

void main() {
  test(
    'fails when victory_overlay suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_victory_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'victory_overlay_test.dart', '''
Widget host() => MaterialApp(home: const Placeholder());
''');

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when victory_overlay_narrow suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_victory_narrow_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'victory_overlay_narrow_test.dart', '''
Widget host() => MaterialApp(home: const Placeholder());
''');

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when debug_console_overlay_panel suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_debug_console_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'debug_console_overlay_panel_test.dart', '''
Widget host() => MaterialApp(home: const Placeholder());
''');

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_overlay suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_province_overlay_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'province_overlay_test.dart', '''
Widget host() => MaterialApp(home: const Placeholder());
''');

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_overlay_header_l10n suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_province_header_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'province_overlay_header_l10n_test.dart', '''
Widget host() => MaterialApp(home: const Placeholder());
''');

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_overlay_consulate_gate_tooltip suite '
    'reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_province_consulate_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'province_overlay_consulate_gate_tooltip_test.dart',
        '''
Widget host() => MaterialApp(home: const Placeholder());
''',
      );

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_overlay_fully_unrevealed_sea_zone_structure suite '
    'reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_province_unrevealed_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'province_overlay_fully_unrevealed_sea_zone_structure_test.dart',
        '''
Widget host() => MaterialApp(home: const Placeholder());
''',
      );

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_overlay_tile_inline_action_non_clickable suite '
    'reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_province_inline_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'province_overlay_tile_inline_action_non_clickable_test.dart',
        '''
Widget host() => MaterialApp(home: const Placeholder());
''',
      );

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_overlay_section_label_material_fallback_guard suite '
    'reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_province_fallback_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'province_overlay_section_label_material_fallback_guard_test.dart',
        '''
Widget host() => MaterialApp(home: const Placeholder());
''',
      );

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_overlay_tile_designation suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_province_designation_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'province_overlay_tile_designation_test.dart', '''
Widget host() => MaterialApp(home: const Placeholder());
''');

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_overlay_sea_zone_political_dark_tokens suite '
    'reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_province_political_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'province_overlay_sea_zone_political_dark_tokens_test.dart',
        '''
Widget host() => MaterialApp(home: const Placeholder());
''',
      );

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_overlay_obfuscated_body_dark_tokens suite '
    'reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_province_obfuscated_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'province_overlay_obfuscated_body_dark_tokens_test.dart',
        '''
Widget host() => MaterialApp(home: const Placeholder());
''',
      );

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_overlay_economic_row_order_coords suite '
    'reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_province_econ_order_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'province_overlay_economic_row_order_coords_test.dart',
        '''
Widget host() => MaterialApp(home: const Placeholder());
''',
      );

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_overlay_economic_hover suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_province_econ_hover_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'province_overlay_economic_hover_test.dart', '''
Widget host() => MaterialApp(home: const Placeholder());
''');

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_overlay_road_rail_transport suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_province_road_rail_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'province_overlay_road_rail_transport_test.dart', '''
Widget host() => MaterialApp(home: const Placeholder());
''');

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_overlay_narrow_side_rail_height_pin suite '
    'reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_province_narrow_rail_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'province_overlay_narrow_side_rail_height_pin_test.dart',
        '''
Widget host() => MaterialApp(home: const Placeholder());
''',
      );

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_overlay_tile_resource_row_label_inline_dark_token suite '
    'reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_province_res_label_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'province_overlay_tile_resource_row_label_inline_dark_token_test.dart',
        '''
Widget host() => MaterialApp(home: const Placeholder());
''',
      );

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_sea_zone_overlay_detail_paths suite '
    'reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_sea_zone_paths_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'province_sea_zone_overlay_detail_paths_test.dart',
        '''
Widget host() => MaterialApp(home: const Placeholder());
''',
      );

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_sea_zone_overlay_naval_port_pending_omission suite '
    'reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_sea_zone_naval_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'province_sea_zone_overlay_naval_port_pending_omission_test.dart',
        '''
Widget host() => MaterialApp(home: const Placeholder());
''',
      );

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when province_sea_zone_resource_labels suite '
    'reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_sea_zone_res_labels_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'province_sea_zone_resource_labels_test.dart', '''
Widget host() => MaterialApp(home: const Placeholder());
''');

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'fails when overture_dialogue_intro suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_overture_intro_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'overture_dialogue_intro_test.dart', '''
Widget host() => MaterialApp(home: const Placeholder());
''');

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('inline MaterialApp( host'));
    },
  );

  test(
    'passes when transfer/move/map-options/pause/save-load/exit/turn-res/diplo/dialogue-overlay suites use buildAppShell only',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_unit_order_ok_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'transfer_to_home_fleet_dialog_spec_test.dart',
        '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''',
      );
      _writeGovernedFile(temp, 'move_dialogs_specs_part2_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'game_map_options_dialog_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'next_turn_confirmation_dialog_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'pause_menu_side_menu_specs_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'save_game_name_dialog_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'load_game_list_dialog_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'exit_confirm_dialog_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'turn_resolution_processing_dialog_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'diplomacy_dialogs_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'tribe_first_contact_overlay_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(
        temp,
        'call_to_arms_dialogue_overlay_dark_chrome_test.dart',
        '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''',
      );
      _writeGovernedFile(temp, 'overture_dialogue_overlay_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'overture_dialogue_intro_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'intervention_dialogue_overlay_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'dialogue_overlays_specs_part2_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'victory_overlay_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'victory_overlay_narrow_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'debug_console_overlay_panel_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'province_overlay_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'province_overlay_header_l10n_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(
        temp,
        'province_overlay_consulate_gate_tooltip_test.dart',
        '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''',
      );
      _writeGovernedFile(
        temp,
        'province_overlay_fully_unrevealed_sea_zone_structure_test.dart',
        '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''',
      );
      _writeGovernedFile(
        temp,
        'province_overlay_tile_inline_action_non_clickable_test.dart',
        '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''',
      );
      _writeGovernedFile(
        temp,
        'province_overlay_section_label_material_fallback_guard_test.dart',
        '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''',
      );
      _writeGovernedFile(temp, 'province_overlay_tile_designation_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(
        temp,
        'province_overlay_sea_zone_political_dark_tokens_test.dart',
        '''
import 'province_overlay_test_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildProvinceOverlayDarkThemeShell(
        game: null as dynamic,
        displayId: 'x',
      ),
    );
  });
}
''',
      );
      _writeGovernedFile(
        temp,
        'province_overlay_obfuscated_body_dark_tokens_test.dart',
        '''
import 'province_overlay_test_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildProvinceOverlayDarkThemeShell(
        game: null as dynamic,
        displayId: 'x',
      ),
    );
  });
}
''',
      );
      _writeGovernedFile(
        temp,
        'province_overlay_economic_row_order_coords_test.dart',
        '''
import 'province_overlay_test_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildProvinceOverlayDarkThemeShell(
        game: null as dynamic,
        displayId: 'x',
      ),
    );
  });
}
''',
      );
      _writeGovernedFile(temp, 'province_overlay_economic_hover_test.dart', '''
import 'province_overlay_test_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildProvinceOverlayDarkThemeShell(
        game: null as dynamic,
        displayId: 'x',
      ),
    );
  });
}
''');
      _writeGovernedFile(temp, 'province_overlay_road_rail_transport_test.dart', '''
import 'province_overlay_test_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildProvinceOverlayDarkThemeShell(
        game: null as dynamic,
        displayId: 'x',
      ),
    );
  });
}
''');
      _writeGovernedFile(
        temp,
        'province_overlay_narrow_side_rail_height_pin_test.dart',
        '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await pumpAppShell(
      tester,
      child: const Scaffold(body: Placeholder()),
    );
  });
}
''',
      );
      _writeGovernedFile(
        temp,
        'province_overlay_tile_resource_row_label_inline_dark_token_test.dart',
        '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''',
      );
      _writeGovernedFile(
        temp,
        'province_sea_zone_overlay_detail_paths_test.dart',
        '''
import 'province_overlay_test_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildProvinceOverlayDarkThemeShell(
        game: null as dynamic,
        displayId: 'x',
      ),
    );
  });
}
''',
      );
      _writeGovernedFile(
        temp,
        'province_sea_zone_overlay_naval_port_pending_omission_test.dart',
        '''
import 'province_overlay_test_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildProvinceOverlayDarkThemeShell(
        game: null as dynamic,
        displayId: 'x',
      ),
    );
  });
}
''',
      );
      _writeGovernedFile(temp, 'province_sea_zone_resource_labels_test.dart', '''
import 'province_overlay_test_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildProvinceOverlayDarkThemeShell(
        game: null as dynamic,
        displayId: 'x',
      ),
    );
  });
}
''');

      final code = runCheckAppTestNoDuplicateScaffolding(temp.path);
      expect(code, 0);
    },
  );
}
