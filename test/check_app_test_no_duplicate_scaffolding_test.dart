import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_test_no_duplicate_scaffolding.dart';

const _kConsolidatedMinViewport = '''
import 'support/min_viewport_harness.dart';

const _kMinViewport = Size(320, 640);

Future<void> _pumpScreen(WidgetTester tester) async {
  await pumpAtMinViewport(
    tester,
    size: _kMinViewport,
    child: const Placeholder(),
  );
}

void main() {
  testWidgets('renders at 320 dp', (tester) async {
    await _pumpScreen(tester);
  });
}
''';

const _kReintroducedHelper = '''
const _kMinViewport = Size(320, 640);

Future<void> _pumpFooScreenAtSize(WidgetTester tester, Size size) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: const Placeholder(),
        ),
      ),
    ),
  );
  await tester.pump();
}
''';

const _kConsolidatedTradeHost = '''
import 'support/trade_screen_test_support.dart';

void main() {
  testWidgets('renders trade', (tester) async {
    await pumpTradeScreen(tester, game: buildTradeTestGame());
  });
}
''';

const _kReintroducedTradeHosts = '''
Game _buildGame() => throw UnimplementedError();

Future<void> _pumpTradeScreen(WidgetTester tester) async {}
''';

void _writeGovernedFile(Directory temp, String name, String contents) {
  File('${temp.path}/app/test/$name')
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}

void main() {
  test('passes on a consolidated 320dp file that uses the shared harness', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(
      temp,
      'technology_screen_320dp_min_viewport_test.dart',
      _kConsolidatedMinViewport,
    );

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateScaffolding(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 0);
    expect(
      logs.join('\n'),
      contains(
        'no duplicated min-viewport, widgetbook use-case, trade-screen host, '
        'units-panel Game, naval/military/technology pump, or panel MaterialApp scaffolding found',
      ),
    );
  });

  test('fails when a per-file _pump*AtSize helper is reintroduced', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_helper_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(
      temp,
      'foo_screen_320dp_min_viewport_test.dart',
      _kReintroducedHelper,
    );

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateScaffolding(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    final joined = logs.join('\n');
    expect(
      joined,
      contains(
        'foo_screen_320dp_min_viewport_test.dart:3: function '
        '"_pumpFooScreenAtSize" re-declares a per-file min-viewport pump '
        'helper',
      ),
    );
    expect(joined, contains('direct "setSurfaceSize" call'));
    expect(joined, contains('AppThemes.editorialMonocle'));
  });

  test('does not fire on the shared harness under app/test/support/', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_support_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    // The harness itself owns the viewport shell; it must never be flagged
    // even though its file name does not match the governed family.
    File('${temp.path}/app/test/support/min_viewport_harness.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
Future<void> pumpAtMinViewport(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    MaterialApp(theme: AppThemes.editorialMonocle),
  );
}
''');

    final code = runCheckAppTestNoDuplicateScaffolding(temp.path);
    expect(code, 0);
  });

  test('ignores legitimately distinct helpers outside the 320dp family', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_distinct_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    // A goldens/mockup test that legitimately forces a surface size and uses
    // the editorial theme, but is not part of the min-viewport pump family.
    _writeGovernedFile(
      temp,
      'diplomacy_panel_goldens_test.dart',
      _kReintroducedHelper,
    );

    final code = runCheckAppTestNoDuplicateScaffolding(temp.path);
    expect(code, 0);
  });

  test('reports violations from multiple governed files, sorted', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_multi_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(
      temp,
      'a_screen_320dp_min_viewport_test.dart',
      _kReintroducedHelper,
    );
    _writeGovernedFile(
      temp,
      'b_screen_320dp_min_viewport_test.dart',
      _kReintroducedHelper,
    );

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateScaffolding(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    final joined = logs.join('\n');
    expect(joined, contains('a_screen_320dp_min_viewport_test.dart:'));
    expect(joined, contains('b_screen_320dp_min_viewport_test.dart:'));
  });

  test('fails when widgetbook _useCase helper is reintroduced', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_widgetbook_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'widgetbook_foo_stories_test.dart', '''
import 'package:widgetbook/widgetbook.dart';

WidgetbookUseCase _useCase(
  List<WidgetbookNode> directories, {
  required String folderName,
  required String useCaseName,
}) {
  throw UnimplementedError();
}
''');

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateScaffolding(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(
      logs.join('\n'),
      contains('function "_useCase" duplicates widgetbook_test_harness.dart'),
    );
  });

  test('passes when a trade-screen test uses the shared trade host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_trade_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(
      temp,
      'trade_screen_foo_test.dart',
      _kConsolidatedTradeHost,
    );

    final code = runCheckAppTestNoDuplicateScaffolding(temp.path);
    expect(code, 0);
  });

  test('fails when private trade-screen hosts are reintroduced', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_trade_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(
      temp,
      'trade_screen_foo_test.dart',
      _kReintroducedTradeHosts,
    );

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateScaffolding(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    final joined = logs.join('\n');
    expect(
      joined,
      contains(
        'trade_screen_foo_test.dart:1: function "_buildGame" duplicates '
        'trade_screen_test_support.dart',
      ),
    );
    expect(
      joined,
      contains(
        'trade_screen_foo_test.dart:3: function "_pumpTradeScreen" duplicates '
        'trade_screen_test_support.dart',
      ),
    );
  });

  test('fails when civilian row-card suite inlines Game(', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_civ_row_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(
      temp,
      'civilian_units_panel_row_card_r30_test.dart',
      'Game g() => Game(id: "x", worldState: WorldState(), players: const []);\n',
    );

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateScaffolding(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('inline Game( construction'));
  });

  test('fails when naval mockup-fidelity suite inlines Game(', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_naval_fid_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(
      temp,
      'naval_units_panel_mockup_fidelity_test.dart',
      'Game g() => Game(id: "x", worldState: WorldState(), players: const []);\n',
    );

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateScaffolding(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('inline Game( construction'));
  });

  test('fails when military army suite inlines Game(', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_mil_army_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(
      temp,
      'military_units_panel_army_test.dart',
      'Game g() => Game(id: "x", worldState: WorldState(), players: const []);\n',
    );

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateScaffolding(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('inline Game( construction'));
  });

  test('fails when military display suite inlines Game(', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_mil_display_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(
      temp,
      'military_units_panel_display_test.dart',
      'Game g() => Game(id: "x", worldState: WorldState(), players: const []);\n',
    );

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateScaffolding(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('inline Game( construction'));
  });

  test(
    'passes when naval mockup-fidelity uses shared OwFleets factory only',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_naval_ok_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'naval_units_panel_mockup_fidelity_test.dart',
        '''
import 'support/naval_units_panel_test_support.dart';

Game g() => buildNavalPanelOwFleetsGame(
  gameId: 't',
  humanId: 'h',
  displayName: 'H',
  oldWorldProvinces: const [],
  fleets: const [],
);
''',
      );

      final code = runCheckAppTestNoDuplicateScaffolding(temp.path);
      expect(code, 0);
    },
  );

  test('fails when naval part suite re-declares local _pumpNaval', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_naval_pump_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'naval_units_panel_part1_test.dart', '''
Future<void> _pumpNaval(WidgetTester tester) async {}
''');

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateScaffolding(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(
      logs.join('\n'),
      contains(
        'function "_pumpNaval" duplicates pumpNavalPanel in '
        'naval_units_panel_test_support.dart',
      ),
    );
  });

  test('fails when military panel suite re-declares local _pumpMilitary', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_mil_pump_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'military_units_panel_test.dart', '''
Future<void> _pumpMilitary(WidgetTester tester) async {}
''');

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateScaffolding(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(
      logs.join('\n'),
      contains(
        'function "_pumpMilitary" duplicates pumpMilitaryPanel in '
        'military_units_panel_test_support.dart',
      ),
    );
  });

  test('passes when military panel suite calls pumpMilitaryPanel only', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_mil_pump_ok_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'military_units_panel_display_test.dart', '''
import 'support/military_units_panel_test_support.dart';

Future<void> example(WidgetTester tester) async {
  await pumpMilitaryPanel(
    tester,
    game: buildMilitaryPanelTestGame(),
    humanPlayerId: 'gp1',
  );
}
''');

    final code = runCheckAppTestNoDuplicateScaffolding(temp.path);
    expect(code, 0);
  });

  test('fails when technology panel suite re-declares local pumpPanel', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_tech_pump_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'technology_panel_test.dart', '''
Future<void> pumpPanel(WidgetTester tester) async {}
''');

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateScaffolding(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(
      logs.join('\n'),
      contains(
        'function "pumpPanel" duplicates pumpTechnologyPanel in '
        'technology_panel_test_support.dart',
      ),
    );
  });

  test('fails when technology panel suite reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_tech_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'technology_panel_interaction_test.dart', '''
Widget host() => MaterialApp(home: const Placeholder());
''');

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateScaffolding(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('inline MaterialApp'));
  });

  test('passes when technology panel suite calls pumpTechnologyPanel only', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_tech_pump_ok_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'technology_panel_funding_toggles_test.dart', '''
import 'support/technology_panel_test_support.dart';

Future<void> example(WidgetTester tester) async {
  await pumpTechnologyPanel(
    tester,
    game: game,
    player: player,
  );
}
''');

    final code = runCheckAppTestNoDuplicateScaffolding(temp.path);
    expect(code, 0);
  });

  test('fails when production labour suite reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_labour_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'production_labour_section_test.dart', '''
Widget host() => MaterialApp(home: const Placeholder());
''');

    final logs = <String>[];
    final code = runCheckAppTestNoDuplicateScaffolding(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('inline MaterialApp'));
  });

  test('fails when production part suite reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_prod_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'production_panel_part2_test.dart', '''
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

  test('passes when production part suite uses buildProductionPanel only', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_prod_ok_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'production_panel_part1_test.dart', '''
import 'support/production_panel_test_support.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(buildProductionPanel(player: productionPanelTestFullPlayer()));
  });
}
''');

    final code = runCheckAppTestNoDuplicateScaffolding(temp.path);
    expect(code, 0);
  });

  test('fails when civilian part suite reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_civ_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'civilian_units_panel_part2_test.dart', '''
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

  test('passes when civilian part suite uses buildCivilianPanel only', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_civ_ok_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'civilian_units_panel_part1_test.dart', '''
import 'support/civilian_units_panel_test_support.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildCivilianPanel(
        game: buildCivilianPanelTestGame(),
        humanPlayerId: 'h1',
      ),
    );
  });
}
''');

    final code = runCheckAppTestNoDuplicateScaffolding(temp.path);
    expect(code, 0);
  });

  test(
    'fails when narrow-detail overlay suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_narrow_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'game_map_narrow_detail_overlay_test.dart', '''
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
    'passes when narrow-detail overlay suite uses buildAppShellWithContainer',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_narrow_ok_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'game_map_narrow_detail_overlay_test.dart', '''
import 'support/app_shell_harness.dart';

Widget host(ProviderContainer c) => buildAppShellWithContainer(
  container: c,
  child: const Scaffold(body: Placeholder()),
);
''');

      final code = runCheckAppTestNoDuplicateScaffolding(temp.path);
      expect(code, 0);
    },
  );

  test(
    'fails when production available-grid suite reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_prod_grid_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'production_panel_available_grid_test.dart', '''
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
    'passes when production cotton-weaving suite uses buildProductionPanel only',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_prod_cotton_ok_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'production_panel_cotton_weaving_lock_test.dart',
        '''
import 'support/production_panel_test_support.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildProductionPanel(player: productionPanelTestFullPlayer()),
    );
  });
}
''',
      );

      final code = runCheckAppTestNoDuplicateScaffolding(temp.path);
      expect(code, 0);
    },
  );

  test('fails when military panel suite reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_mil_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'military_units_panel_test.dart', '''
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

  test('passes when military panel suite uses buildMilitaryPanel only', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_mil_ok_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'military_units_panel_display_test.dart', '''
import 'support/military_units_panel_test_support.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildMilitaryPanel(game: buildMilitaryPanelTestGame(), humanPlayerId: 'h1'),
    );
  });
}
''');

    final code = runCheckAppTestNoDuplicateScaffolding(temp.path);
    expect(code, 0);
  });

  test('fails when production icons suite reintroduces MaterialApp host', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_prod_icons_mat_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'production_panel_icons_test.dart', '''
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

  test('passes when production icons suite uses buildAppShell only', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_test_no_dup_scaffolding_prod_icons_ok_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    _writeGovernedFile(temp, 'production_panel_icons_test.dart', '''
import 'support/app_shell_harness.dart';

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

  test(
    'fails when catalog widget unit host suites reintroduce MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_catalog_units_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      for (final name in <String>[
        'base_units_panel_test.dart',
        'units_combine_header_actions_test.dart',
        'units_panel_shared_widgets_test.dart',
        'unit_panels_viewport_sizing_test.dart',
        'unit_panels_widgetbook_dark_chrome_test.dart',
        'units_panel_sheet_surface_test.dart',
        'units_entity_card_test.dart',
        'ct_action_text_button_test.dart',
        'relation_meter_test.dart',
        'game_top_bar_test.dart',
        'game_tab_bar_test.dart',
        'player_turn_event_feed_chrome_test.dart',
        'game_side_menu_test.dart',
        'ct_dark_scaffold_test.dart',
        'ct_screen_shell_test.dart',
        'ct_dialog_shell_test.dart',
        'ct_full_screen_dialogue_shell_test.dart',
        'ct_game_feature_screen_shell_test.dart',
        'ct_back_button_test.dart',
        'ct_slider_test.dart',
        'ct_tab_strip_test.dart',
        'ct_confirm_dialog_test.dart',
        'ct_nine_patch_button_test.dart',
        'ct_resource_cell_test.dart',
        'game_map_controls_test.dart',
        'players_bar_toggle_test.dart',
        'game_map_corner_controls_dark_chrome_test.dart',
        'game_map_corner_controls_narrow_test.dart',
        'game_map_players_bar_test.dart',
        'game_map_empire_left_rail_test.dart',
        'game_map_empire_left_rail_chrome_test.dart',
        'game_map_empire_left_rail_narrow_test.dart',
        'game_region_minimap_widget_test.dart',
        'game_region_minimap_narrow_test.dart',
        'game_map_area_background_test.dart',
        'game_map_area_event_feed_test.dart',
        'game_map_area_region_minimap_test.dart',
        'game_map_area_selection_mode_test.dart',
        'game_map_area_selection_mode_lightweight_test.dart',
        'game_map_area_shell_entry_center_test.dart',
        'ct_choice_chip_test.dart',
        'ct_transfer_list_test.dart',
        'gp_default_map_color_swatch_test.dart',
        'diplomacy_standing_chips_test.dart',
        'diplomacy_relative_power_line_test.dart',
        'tech_gp_pennant_widget_test.dart',
        'quick_battle_screen_test.dart',
        'quick_battle_deployment_view_dark_tokens_test.dart',
        'quick_battle_action_selector_dark_tokens_test.dart',
        'tech_tree_widget_core_test.dart',
        'tech_tree_widget_palette_test.dart',
        'tech_tree_widget_description_batches_test.dart',
        'player_turn_event_feed_narrow_width_test.dart',
        'player_turn_event_feed_narrow_inset_test.dart',
        'game_map_selection_prompt_dark_tokens_test.dart',
        'diplomacy_panel_mockup_fidelity_test.dart',
        'ct_radius_adoption_test.dart',
        'grant_or_subsidy_listener_test.dart',
        'province_detail_panel_slide_transition_test.dart',
        'dialogue_acceptance_test.dart',
        'production_screen_integration_test.dart',
        'shell_screen_test.dart',
        'shell_screen_pixelart_chrome_test.dart',
        'main_menu_quit_chip_fidelity_test.dart',
        'new_game_leader_dialog_builder_test.dart',
        'shell_player_guarded_body_test.dart',
        'map_diplomacy_panel_specs_test.dart',
        'combat_ui_specs_part1_test.dart',
        'combat_ui_specs_part2_test.dart',
        'game_to_ui_bus_listener_test.dart',
        'app_event_handler_scope_diplomacy_test.dart',
        'app_event_handler_scope_civilian_work_test.dart',
        'turn_resolution_event_blocking_test.dart',
        'app_event_handler_test.dart',
        'game_session_clear_ui_path_test.dart',
        'new_game_setup_flow_test.dart',
        'app_wave5_shared_helpers_test.dart',
        'screen_spec_acceptance_part2_test.dart',
        'widgetbook_dlg60001_shel30001_stories_test.dart',
        'widgetbook_main_menu_stories_editorial_monocle_test.dart',
        'widgetbook_diplomacy_standing_chips_stories_test.dart',
        'widgetbook_diplomacy_detail_screen_stories_test.dart',
        'widgetbook_diplomacy_panel_empty_state_test.dart',
        'widgetbook_technology_slots_variants_test.dart',
        'widgetbook_technology_funding_preview_story_test.dart',
        'widgetbook_production_panel_mobile_viewport_test.dart',
        'widgetbook_leader_selection_dialog_mobile_viewport_test.dart',
        'widgetbook_map_widget_mobile_viewport_test.dart',
        'widgetbook_province_overlay_mobile_viewport_test.dart',
        'widgetbook_game_top_bar_mobile_viewport_test.dart',
        'widgetbook_shell_mobile_viewport_test.dart',
        'widgetbook_main_menu_mobile_viewport_test.dart',
        'widgetbook_diplomacy_panel_mobile_viewport_test.dart',
        'widgetbook_player_turn_event_feed_mobile_viewport_test.dart',
        'widgetbook_technology_screen_mobile_viewport_test.dart',
        'widgetbook_turn_news_mobile_viewport_test.dart',
        'tech_gp_pennant_goldens_test.dart',
        'themes_and_widgetbook_test.dart',
        'game_screen_branches_test.dart',
        'game_screen_narrow_part1_test.dart',
        'game_screen_narrow_part2_test.dart',
        'game_screen_s13_mockup_fidelity_test.dart',
        'game_screen_side_menu_toggle_test.dart',
        'game_screen_overture_pending_test.dart',
        'game_screen_turn_resolution_branches_test.dart',
        'game_screen_intervention_flow_test.dart',
        'shell_game_screen_specs_test.dart',
        'debug_log_viewer_test.dart',
        'ct_region_map_test_support.dart',
        'ct_region_map_widget_part2_test.dart',
        'ct_region_map_widget_part3_test.dart',
        'region_map_zoom_fit_test.dart',
        'plains_plantation_terrain_goldens_test.dart',
        'region_map_extraction_disc_indicators_test.dart',
        'region_map_resource_transport_readability_test.dart',
      ]) {
        _writeGovernedFile(temp, name, '''
Widget host() => MaterialApp(home: const Placeholder());
''');
      }

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
    'passes when catalog widget unit host suites use buildAppShell only',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_catalog_units_ok_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      for (final name in <String>[
        'base_units_panel_test.dart',
        'units_combine_header_actions_test.dart',
        'units_panel_shared_widgets_test.dart',
        'unit_panels_viewport_sizing_test.dart',
        'unit_panels_widgetbook_dark_chrome_test.dart',
        'units_panel_sheet_surface_test.dart',
        'units_entity_card_test.dart',
        'ct_action_text_button_test.dart',
        'relation_meter_test.dart',
        'game_top_bar_test.dart',
        'game_tab_bar_test.dart',
        'player_turn_event_feed_chrome_test.dart',
        'game_side_menu_test.dart',
        'ct_dark_scaffold_test.dart',
        'ct_screen_shell_test.dart',
        'ct_dialog_shell_test.dart',
        'ct_full_screen_dialogue_shell_test.dart',
        'ct_game_feature_screen_shell_test.dart',
        'ct_back_button_test.dart',
        'ct_slider_test.dart',
        'ct_tab_strip_test.dart',
        'ct_confirm_dialog_test.dart',
        'ct_nine_patch_button_test.dart',
        'ct_resource_cell_test.dart',
        'game_map_controls_test.dart',
        'players_bar_toggle_test.dart',
        'game_map_corner_controls_dark_chrome_test.dart',
        'game_map_corner_controls_narrow_test.dart',
        'game_map_players_bar_test.dart',
        'game_map_empire_left_rail_test.dart',
        'game_map_empire_left_rail_chrome_test.dart',
        'game_map_empire_left_rail_narrow_test.dart',
        'game_region_minimap_widget_test.dart',
        'game_region_minimap_narrow_test.dart',
        'game_map_area_background_test.dart',
        'game_map_area_event_feed_test.dart',
        'game_map_area_region_minimap_test.dart',
        'game_map_area_selection_mode_test.dart',
        'game_map_area_selection_mode_lightweight_test.dart',
        'game_map_area_shell_entry_center_test.dart',
        'ct_choice_chip_test.dart',
        'ct_transfer_list_test.dart',
        'gp_default_map_color_swatch_test.dart',
        'diplomacy_standing_chips_test.dart',
        'diplomacy_relative_power_line_test.dart',
        'tech_gp_pennant_widget_test.dart',
        'quick_battle_screen_test.dart',
        'quick_battle_deployment_view_dark_tokens_test.dart',
        'quick_battle_action_selector_dark_tokens_test.dart',
        'tech_tree_widget_core_test.dart',
        'tech_tree_widget_palette_test.dart',
        'tech_tree_widget_description_batches_test.dart',
        'player_turn_event_feed_narrow_width_test.dart',
        'player_turn_event_feed_narrow_inset_test.dart',
        'game_map_selection_prompt_dark_tokens_test.dart',
        'diplomacy_panel_mockup_fidelity_test.dart',
        'ct_radius_adoption_test.dart',
        'grant_or_subsidy_listener_test.dart',
        'province_detail_panel_slide_transition_test.dart',
        'dialogue_acceptance_test.dart',
        'production_screen_integration_test.dart',
        'shell_screen_test.dart',
        'shell_screen_pixelart_chrome_test.dart',
        'main_menu_quit_chip_fidelity_test.dart',
        'new_game_leader_dialog_builder_test.dart',
        'shell_player_guarded_body_test.dart',
        'map_diplomacy_panel_specs_test.dart',
        'combat_ui_specs_part1_test.dart',
        'combat_ui_specs_part2_test.dart',
        'game_to_ui_bus_listener_test.dart',
        'app_event_handler_scope_diplomacy_test.dart',
        'app_event_handler_scope_civilian_work_test.dart',
        'turn_resolution_event_blocking_test.dart',
        'app_event_handler_test.dart',
        'game_session_clear_ui_path_test.dart',
        'new_game_setup_flow_test.dart',
        'app_wave5_shared_helpers_test.dart',
        'screen_spec_acceptance_part2_test.dart',
        'widgetbook_dlg60001_shel30001_stories_test.dart',
        'widgetbook_main_menu_stories_editorial_monocle_test.dart',
        'widgetbook_diplomacy_standing_chips_stories_test.dart',
        'widgetbook_diplomacy_detail_screen_stories_test.dart',
        'widgetbook_diplomacy_panel_empty_state_test.dart',
        'widgetbook_technology_slots_variants_test.dart',
        'widgetbook_technology_funding_preview_story_test.dart',
        'widgetbook_production_panel_mobile_viewport_test.dart',
        'widgetbook_leader_selection_dialog_mobile_viewport_test.dart',
        'widgetbook_map_widget_mobile_viewport_test.dart',
        'widgetbook_province_overlay_mobile_viewport_test.dart',
        'widgetbook_game_top_bar_mobile_viewport_test.dart',
        'widgetbook_shell_mobile_viewport_test.dart',
        'widgetbook_main_menu_mobile_viewport_test.dart',
        'widgetbook_diplomacy_panel_mobile_viewport_test.dart',
        'widgetbook_player_turn_event_feed_mobile_viewport_test.dart',
        'widgetbook_technology_screen_mobile_viewport_test.dart',
        'widgetbook_turn_news_mobile_viewport_test.dart',
        'tech_gp_pennant_goldens_test.dart',
        'themes_and_widgetbook_test.dart',
        'game_screen_branches_test.dart',
        'game_screen_narrow_part1_test.dart',
        'game_screen_narrow_part2_test.dart',
        'game_screen_s13_mockup_fidelity_test.dart',
        'game_screen_side_menu_toggle_test.dart',
        'game_screen_overture_pending_test.dart',
        'game_screen_turn_resolution_branches_test.dart',
        'game_screen_intervention_flow_test.dart',
        'shell_game_screen_specs_test.dart',
        'debug_log_viewer_test.dart',
        'ct_region_map_test_support.dart',
        'ct_region_map_widget_part2_test.dart',
        'ct_region_map_widget_part3_test.dart',
        'region_map_zoom_fit_test.dart',
        'plains_plantation_terrain_goldens_test.dart',
        'region_map_extraction_disc_indicators_test.dart',
        'region_map_resource_transport_readability_test.dart',
      ]) {
        _writeGovernedFile(temp, name, '''
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      }

      final code = runCheckAppTestNoDuplicateScaffolding(temp.path);
      expect(code, 0);
    },
  );
}
