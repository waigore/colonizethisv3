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

  test(
    'fails when production icons suite reintroduces MaterialApp host',
    () {
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
    },
  );

  test(
    'passes when production icons suite uses buildAppShell only',
    () {
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
    },
  );

  test(
    'fails when production labour step-surface suite '
    'reintroduces MaterialApp host',
    () {
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
    },
  );

  test(
    'fails when production labour expected-lines suite '
    'reintroduces MaterialApp host',
    () {
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
    },
  );

  test(
    'fails when production allocation-row buttons suite '
    'reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_prod_alloc_btn_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'production_allocation_row_buttons_test.dart',
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
    'fails when production allocation-row chrome suite '
    'reintroduces MaterialApp host',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_prod_alloc_chrome_mat_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(
        temp,
        'production_allocation_row_chrome_test.dart',
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
import 'support/app_shell_harness.dart';

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
    'fails when train naval dialog suite reintroduces MaterialApp host',
    () {
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
    },
  );

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

  test(
    'passes when train naval dialog suite uses buildAppShell only',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_app_test_no_dup_scaffolding_train_naval_ok_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      _writeGovernedFile(temp, 'train_naval_dialog_test.dart', '''
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
    },
  );

  test(
    'fails when split army dialog suite reintroduces MaterialApp host',
    () {
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
    },
  );

  test(
    'fails when split fleet dialog suite reintroduces MaterialApp host',
    () {
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
    },
  );

  test(
    'fails when move fleet dialog suite reintroduces MaterialApp host',
    () {
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
    },
  );

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
import 'support/app_shell_harness.dart';

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
      _writeGovernedFile(temp, 'transfer_to_home_fleet_dialog_spec_test.dart', '''
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

  test(
    'fails when turn_news dialog suite reintroduces MaterialApp host',
    () {
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
    },
  );

  test(
    'fails when pause_menu_panel suite reintroduces MaterialApp host',
    () {
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
    },
  );

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
      _writeGovernedFile(temp, 'turn_resolution_processing_dialog_test.dart', '''
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
    'fails when diplomacy_dialogs suite reintroduces MaterialApp host',
    () {
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
    },
  );

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
import 'support/app_shell_harness.dart';

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
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'game_map_options_dialog_test.dart', '''
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'next_turn_confirmation_dialog_test.dart', '''
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'pause_menu_side_menu_specs_test.dart', '''
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'save_game_name_dialog_test.dart', '''
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'load_game_list_dialog_test.dart', '''
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'exit_confirm_dialog_test.dart', '''
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'turn_resolution_processing_dialog_test.dart', '''
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'diplomacy_dialogs_test.dart', '''
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'tribe_first_contact_overlay_test.dart', '''
import 'support/app_shell_harness.dart';

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
import 'support/app_shell_harness.dart';

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
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'overture_dialogue_intro_test.dart', '''
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'intervention_dialogue_overlay_test.dart', '''
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'dialogue_overlays_specs_part2_test.dart', '''
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'victory_overlay_test.dart', '''
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'victory_overlay_narrow_test.dart', '''
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'debug_console_overlay_panel_test.dart', '''
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'province_overlay_test.dart', '''
import 'support/app_shell_harness.dart';

void main() {
  testWidgets('ok', (tester) async {
    await tester.pumpWidget(
      buildAppShell(child: const Scaffold(body: Placeholder())),
    );
  });
}
''');
      _writeGovernedFile(temp, 'province_overlay_header_l10n_test.dart', '''
import 'support/app_shell_harness.dart';

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
import 'support/app_shell_harness.dart';

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
import 'support/app_shell_harness.dart';

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
import 'support/app_shell_harness.dart';

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
import 'support/app_shell_harness.dart';

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
}
