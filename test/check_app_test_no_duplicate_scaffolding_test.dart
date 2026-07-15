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
        'or units-panel Game scaffolding found',
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
    expect(
      logs.join('\n'),
      contains('inline Game( construction'),
    );
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
    expect(
      logs.join('\n'),
      contains('inline Game( construction'),
    );
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
    expect(
      logs.join('\n'),
      contains('inline Game( construction'),
    );
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
    expect(
      logs.join('\n'),
      contains('inline Game( construction'),
    );
  });

  test('passes when naval mockup-fidelity uses shared OwFleets factory only', () {
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
  });
}
