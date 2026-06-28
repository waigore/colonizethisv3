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
      contains('no duplicated min-viewport scaffolding found'),
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
}
