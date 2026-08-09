import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_test_no_duplicate_scaffolding.dart';

void _writeGovernedFile(Directory temp, String name, String contents) {
  File('${temp.path}/app/test/$name')
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}

void main() {
  test('fails when production labour step-surface suite '
      'reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_prod_step_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(
      temp,
      'production_labour_section_step_surface_test.dart',
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
  });

  test('fails when production labour expected-lines suite '
      'reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_prod_lines_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(
      temp,
      'production_labour_controls_expected_lines_test.dart',
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
  });

  test('fails when production allocation-row buttons suite '
      'reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_prod_alloc_btn_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'production_allocation_row_buttons_test.dart', '''
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
  });

  test('fails when production allocation-row chrome suite '
      'reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_prod_alloc_chrome_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'production_allocation_row_chrome_test.dart', '''
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
  });

  test(
    'passes when production labour step-surface suite uses buildAppShell',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_prod_step_ok_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'production_labour_section_step_surface_test.dart',
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

      final code = runCheckAppTestNoDuplicateScaffolding(temp.path);
      expect(code, 0);
    },
  );

  test('fails when train naval dialog suite reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_train_naval_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'train_naval_dialog_test.dart', '''
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
  });

  test(
    'fails when train military dialog suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_train_mil_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'train_military_dialog_test.dart', '''
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
    'fails when train civilians dialog suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_train_civ_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'train_civilians_dialog_test.dart', '''
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
    'fails when train dialog chrome suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_train_chrome_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'train_dialog_chrome_test.dart', '''
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

  test('passes when train naval dialog suite uses buildAppShell only', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_train_naval_ok_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'train_naval_dialog_test.dart', '''
import 'app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');

    final code = runCheckAppTestNoDuplicateScaffolding(temp.path);
    expect(code, 0);
  });

  test('fails when split army dialog suite reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_split_army_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'split_army_dialog_test.dart', '''
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
  });

  test('fails when split fleet dialog suite reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_split_fleet_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'split_fleet_dialog_test.dart', '''
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
  });

  test('fails when move fleet dialog suite reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_move_fleet_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'move_fleet_dialog_test.dart', '''
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
  });

  test(
    'fails when commodity breakdown dialog spec suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_commodity_spec_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'production_commodity_breakdown_dialog_spec_test.dart',
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
    'fails when commodity breakdown wide-full-width suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_commodity_wide_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'production_commodity_breakdown_dialog_wide_full_width_test.dart',
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
    'passes when commodity breakdown dialog suite uses buildAppShell only',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_commodity_ok_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'production_commodity_breakdown_dialog_spec_test.dart',
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

      final code = runCheckAppTestNoDuplicateScaffolding(temp.path);
      expect(code, 0);
    },
  );

  test(
    'fails when transfer-to-home-fleet dialog suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_transfer_home_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'transfer_to_home_fleet_dialog_spec_test.dart',
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
    'fails when move_dialogs_specs part suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_move_dialogs_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'move_dialogs_specs_part1_test.dart', '''
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
    'fails when game_map_options dialog suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_map_options_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'game_map_options_dialog_test.dart', '''
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
    'fails when next_turn_confirmation dialog suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_next_turn_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'next_turn_confirmation_dialog_test.dart', '''
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

  test('fails when turn_news dialog suite reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_turn_news_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'turn_news_dialog_test.dart', '''
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
  });

  test('fails when pause_menu_panel suite reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_pause_menu_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'pause_menu_panel_test.dart', '''
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
  });

  test(
    'fails when pause_menu_side_menu_specs suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_pause_side_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'pause_menu_side_menu_specs_test.dart', '''
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
    'fails when save_game_name dialog suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_save_name_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'save_game_name_dialog_test.dart', '''
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
    'fails when load_game_list dialog suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_load_list_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'load_game_list_dialog_test.dart', '''
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
    'fails when exit_confirm dialog suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_exit_confirm_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'exit_confirm_dialog_test.dart', '''
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
    'fails when turn_resolution_processing dialog suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_turn_res_proc_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'turn_resolution_processing_dialog_test.dart',
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

  test('fails when diplomacy_dialogs suite reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_diplomacy_dialogs_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'diplomacy_dialogs_test.dart', '''
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
  });

  test(
    'fails when tribe_first_contact overlay suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_tribe_fc_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'tribe_first_contact_overlay_test.dart', '''
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
    'fails when call_to_arms dark-chrome suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_cta_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'call_to_arms_dialogue_overlay_dark_chrome_test.dart',
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
    'fails when overture_dialogue_overlay suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_overture_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'overture_dialogue_overlay_test.dart', '''
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
    'fails when intervention_dialogue_overlay suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_intervention_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'intervention_dialogue_overlay_test.dart', '''
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
    'fails when dialogue_overlays_specs part suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_dlg_specs_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'dialogue_overlays_specs_part2_test.dart', '''
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
    'fails when governed 320 dp suite reintroduces Center-host dialog clone',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_dialogs320_center_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'choose_tech_dialog_320dp_min_viewport_test.dart',
        '''
Future<void> _pumpDialog(WidgetTester tester, Widget dialog) async {
  await pumpAtMinViewport(
    tester,
    child: Scaffold(body: Center(child: dialog)),
  );
}
''',
      );

      final logs = <String>[];
      final code = runCheckAppTestNoDuplicateScaffolding(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('Scaffold(body: Center(...))'));
      expect(logs.join('\n'), contains('pumpDialogs320At'));
    },
  );

  test('passes when governed 320 dp suite calls pumpDialogs320At', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_dialogs320_ok_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(
      temp,
      'choose_tech_dialog_320dp_min_viewport_test.dart',
      '''
import 'dialogs_320dp_min_viewport_support.dart';

void main() {
  testWidgets('ok', (tester) async {
    await pumpDialogs320At(tester, const Placeholder(), size: Size.zero);
  });
}
''',
    );

    expect(runCheckAppTestNoDuplicateScaffolding(temp.path), 0);
  });

  test(
    'passes when production commodity 320 suite uses showDialog Builder host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_prod_commodity_ok_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'production_commodity_breakdown_dialog_320dp_min_viewport_test.dart',
        '''
Future<void> _pumpDialog(WidgetTester tester) async {
  await pumpAtMinViewport(
    tester,
    child: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const Placeholder(),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
}
''',
      );

      expect(runCheckAppTestNoDuplicateScaffolding(temp.path), 0);
    },
  );
}
