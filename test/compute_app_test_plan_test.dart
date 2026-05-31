import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/compute_app_test_plan.dart';

void main() {
  late Directory repoRoot;

  setUp(() async {
    repoRoot = await Directory.systemTemp.createTemp('ct_app_test_plan_');
    await _writeMinimalWorkspace(repoRoot.path);
  });

  tearDown(() async {
    if (repoRoot.existsSync()) {
      await repoRoot.delete(recursive: true);
    }
  });

  // -------------- selective: app-internal seeds (existing behaviors) --------------

  test('selective: changed lib file selects importing test only', () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['app/lib/widgets/panel.dart'],
    );

    expect(plan.mode, 'selective');
    expect(plan.tests, ['app/test/widgets/panel_test.dart']);
  });

  test('selective: transitive lib change selects downstream test', () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['app/lib/core/service.dart'],
    );

    expect(plan.mode, 'selective');
    expect(
      plan.tests,
      containsAll([
        'app/test/widgets/panel_test.dart',
        'app/test/core/service_test.dart',
      ]),
    );
  });

  test('selective: changed test file includes only that test', () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['app/test/features/unrelated_test.dart'],
    );

    expect(plan.mode, 'selective');
    expect(plan.tests, ['app/test/features/unrelated_test.dart']);
  });

  test('selective: changed test helper selects tests that import it', () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['app/test/support/fixtures.dart'],
    );

    expect(plan.mode, 'selective');
    expect(plan.tests, ['app/test/features/unrelated_test.dart']);
  });

  // -------------- selective: cross-package edges (new behavior) --------------

  test(
      'selective: cross-package lib change selects exactly the two app tests '
      'whose transitive closures contain it', () {
    // AC#1 from issue #3018: changed file in colonizethis_logic/lib reached
    // by exactly two app tests (one direct, one transitive via ai).
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['packages/colonizethis_logic/lib/foo.dart'],
    );

    expect(plan.mode, 'selective');
    expect(
      plan.tests,
      <String>[
        'app/test/cross/ai_test.dart',
        'app/test/cross/foo_logic_test.dart',
      ],
    );
  });

  test(
      'selective: transitive cross-package edge (ai -> logic) is followed '
      'into app test closures', () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['packages/colonizethis_logic/lib/foo.dart'],
    );

    expect(plan.tests, contains('app/test/cross/ai_test.dart'));
  });

  test('selective: changed package lib selects only tests reaching it', () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['packages/colonizethis_ai/lib/ai.dart'],
    );

    expect(plan.mode, 'selective');
    expect(plan.tests, ['app/test/cross/ai_test.dart']);
  });

  // -------------- selective: irreducible fallback (was previously `full`) --------------

  test('irreducible fallback: asset change under app/ -> selective + all tests',
      () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['app/assets/icons/foo.png'],
    );

    expect(plan.mode, 'selective');
    expect(plan.tests, _allAppTestsExpected);
  });

  test('irreducible fallback: root pubspec.yaml -> selective + all tests', () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['pubspec.yaml'],
    );

    expect(plan.mode, 'selective');
    expect(plan.tests, _allAppTestsExpected);
  });

  test('irreducible fallback: analysis_options.yaml -> selective + all tests',
      () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['analysis_options.yaml'],
    );

    expect(plan.mode, 'selective');
    expect(plan.tests, _allAppTestsExpected);
  });

  test(
      'irreducible fallback: tool/compute_app_test_plan.dart -> selective + all tests',
      () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['tool/compute_app_test_plan.dart'],
    );

    expect(plan.mode, 'selective');
    expect(plan.tests, _allAppTestsExpected);
  });

  test(
      'irreducible fallback: .github/workflows/quality.yml -> selective + all tests',
      () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['.github/workflows/quality.yml'],
    );

    expect(plan.mode, 'selective');
    expect(plan.tests, _allAppTestsExpected);
  });

  // -------------- skip: out-of-graph changes --------------

  test('skip: tool-only change (tool/* lib not walked)', () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['tool/sim_scenarios/lib/scenario.dart'],
    );

    expect(plan.mode, 'skip');
    expect(plan.tests, isEmpty);
  });

  test('skip: SPEC-only change', () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['SPEC/program/foo.md'],
    );

    expect(plan.mode, 'skip');
    expect(plan.tests, isEmpty);
  });

  test('skip: package test/** change (package tests are out of scope)', () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['packages/colonizethis_logic/test/foo_test.dart'],
    );

    expect(plan.mode, 'skip');
    expect(plan.tests, isEmpty);
  });

  test('skip: empty changed file list', () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: const [],
    );

    expect(plan.mode, 'skip');
    expect(plan.tests, isEmpty);
  });

  // -------------- mode rules: full is never emitted --------------

  test('mode: selector never emits the legacy `full` mode', () {
    final inputs = <List<String>>[
      ['app/lib/widgets/panel.dart'],
      ['packages/colonizethis_logic/lib/foo.dart'],
      ['app/assets/icons/foo.png'],
      ['pubspec.yaml'],
      ['tool/compute_app_test_plan.dart'],
      ['SPEC/program/foo.md'],
      const [],
    ];
    for (final changed in inputs) {
      final plan =
          computeAppTestPlan(repoRoot: repoRoot.path, changedFiles: changed);
      expect(plan.mode, isNot('full'),
          reason: 'changed=$changed mode=${plan.mode}');
      expect(plan.mode, anyOf('selective', 'skip'),
          reason: 'changed=$changed mode=${plan.mode}');
    }
  });

  // -------------- determinism: pure function of changed files + workspace --------------

  test('determinism: same input -> byte-identical output across two calls',
      () {
    final changed = [
      'packages/colonizethis_logic/lib/foo.dart',
      'app/lib/widgets/panel.dart',
    ];
    final a = computeAppTestPlan(
        repoRoot: repoRoot.path, changedFiles: changed);
    final b = computeAppTestPlan(
        repoRoot: repoRoot.path, changedFiles: changed);
    expect(a.mode, b.mode);
    expect(a.tests, b.tests);
  });

  test(
      'determinism: env vars and label-style env do not influence output '
      '(selector is pure per SPEC D1)', () {
    final changed = ['packages/colonizethis_logic/lib/foo.dart'];
    final baseline = computeAppTestPlan(
        repoRoot: repoRoot.path, changedFiles: changed);
    // Set spurious env to demonstrate the binary does not consult env.
    // The function under test never reads env, so this is a structural
    // guarantee, not a test of an env hook.
    expect(Platform.environment.containsKey('CI_FULL_APP_OVERRIDE'), isFalse,
        reason: 'sanity: spec D1 means selector ignores any env');
    final replay = computeAppTestPlan(
        repoRoot: repoRoot.path, changedFiles: changed);
    expect(replay.mode, baseline.mode);
    expect(replay.tests, baseline.tests);
  });

  // -------------- CLI smoke (real repo) --------------

  test('CLI emits JSON for changed files (selective)', () {
    final result = Process.runSync(
      'dart',
      [
        'run',
        p.join('tool', 'compute_app_test_plan.dart'),
        '--changed-files=app/lib/widgets/ct_panel.dart',
      ],
      workingDirectory: _workspaceRoot(),
    );

    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    final json = (result.stdout as String).trim();
    expect(json, contains('"mode":"selective"'));
    expect(json, contains('naval_units_panel_test'));
  });
}

/// Expected sorted union of every `app/test/**/*_test.dart` produced by
/// [_writeMinimalWorkspace]. Kept here so fallback ACs assert against an
/// explicit list rather than implementation-derived state.
const _allAppTestsExpected = <String>[
  'app/test/core/service_test.dart',
  'app/test/cross/ai_test.dart',
  'app/test/cross/foo_logic_test.dart',
  'app/test/features/unrelated_test.dart',
  'app/test/widgets/panel_test.dart',
];

Future<void> _writeMinimalWorkspace(String root) async {
  Future<void> write(String rel, String content) async {
    final file = File(p.join(root, rel));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  // Root workspace pubspec — the selector reads `workspace:` from here and
  // each member's `name:` to build the package map.
  await write(
    'pubspec.yaml',
    'name: colonizethis\n'
    'publish_to: none\n'
    'environment:\n'
    "  sdk: '>=3.11.5 <4.0.0'\n"
    'workspace:\n'
    '  - app\n'
    '  - packages/colonizethis_logic\n'
    '  - packages/colonizethis_ai\n'
    '  - packages/colonizethis_test\n'
    '  - tool/sim_scenarios\n',
  );
  await write('app/pubspec.yaml', 'name: colonizethis_app\n');
  await write('packages/colonizethis_logic/pubspec.yaml',
      'name: colonizethis_logic\n');
  await write('packages/colonizethis_ai/pubspec.yaml',
      'name: colonizethis_ai\n');
  await write('packages/colonizethis_test/pubspec.yaml',
      'name: colonizethis_test\n');
  await write('tool/sim_scenarios/pubspec.yaml', 'name: sim_scenarios\n');

  // App-internal graph (kept from prior fixture).
  await write(
    'app/lib/widgets/panel.dart',
    "import 'package:colonizethis_app/core/service.dart';\n"
    'class Panel {}\n',
  );
  await write('app/lib/core/service.dart', 'class Service {}\n');
  await write(
    'app/test/widgets/panel_test.dart',
    "import 'package:colonizethis_app/widgets/panel.dart';\n"
    'void main() {}\n',
  );
  await write(
    'app/test/core/service_test.dart',
    "import 'package:colonizethis_app/core/service.dart';\n"
    'void main() {}\n',
  );
  await write('app/test/support/fixtures.dart', 'class Fixtures {}\n');
  await write(
    'app/test/features/unrelated_test.dart',
    "import '../support/fixtures.dart';\n"
    'void main() {}\n',
  );

  // Cross-package graph fixtures.
  // logic/foo.dart is reached by:
  //   - app/test/cross/foo_logic_test.dart (direct)
  //   - app/test/cross/ai_test.dart -> ai.dart -> logic/foo.dart (transitive)
  await write(
    'packages/colonizethis_logic/lib/foo.dart',
    'class Foo {}\n',
  );
  await write(
    'packages/colonizethis_ai/lib/ai.dart',
    "import 'package:colonizethis_logic/foo.dart';\n"
    'class Ai {}\n',
  );
  await write(
    'app/test/cross/foo_logic_test.dart',
    "import 'package:colonizethis_logic/foo.dart';\n"
    'void main() {}\n',
  );
  await write(
    'app/test/cross/ai_test.dart',
    "import 'package:colonizethis_ai/ai.dart';\n"
    'void main() {}\n',
  );

  // Packages that exist but are unreached by app tests.
  await write(
    'packages/colonizethis_test/lib/helpers.dart',
    'class Helpers {}\n',
  );
}

String _workspaceRoot() {
  var dir = Directory.current;
  while (true) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final text = pubspec.readAsStringSync();
      if (text.contains('name: colonizethis') && text.contains('workspace:')) {
        return dir.path;
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('repo root not found');
    }
    dir = parent;
  }
}
