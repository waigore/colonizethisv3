import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/compute_app_test_plan.dart';

void main() {
  late Directory repoRoot;

  setUp(() async {
    repoRoot = await Directory.systemTemp.createTemp('ct_app_test_plan_');
    await _writeMinimalApp(repoRoot.path);
  });

  tearDown(() async {
    if (repoRoot.existsSync()) {
      await repoRoot.delete(recursive: true);
    }
  });

  group('app lib + test seeds (#3018 single-package selection)', () {
    test('selective: changed lib file selects importing test only', () {
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const ['app/lib/widgets/panel.dart'],
      );

      expect(plan.mode, 'selective');
      expect(plan.tests, const ['app/test/widgets/panel_test.dart']);
    });

    test('selective: transitive lib change selects downstream test', () {
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const ['app/lib/core/service.dart'],
      );

      expect(plan.mode, 'selective');
      expect(
        plan.tests,
        containsAll(<String>[
          'app/test/widgets/panel_test.dart',
          'app/test/core/service_test.dart',
        ]),
      );
    });

    test('selective: changed test file includes only that test', () {
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const ['app/test/features/unrelated_test.dart'],
      );

      expect(plan.mode, 'selective');
      expect(plan.tests, const ['app/test/features/unrelated_test.dart']);
    });

    test('selective: changed test helper selects tests that import it', () {
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const ['app/test/support/fixtures.dart'],
      );

      expect(plan.mode, 'selective');
      expect(plan.tests, const ['app/test/features/unrelated_test.dart']);
    });
  });

  group('cross-package selection (#3018 AC-1, AC-2)', () {
    test(
        'selective: change in packages/colonizethis_logic/lib/foo.dart '
        'selects the full transitive closure of importing app tests', () {
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const ['packages/colonizethis_logic/lib/foo.dart'],
      );

      expect(plan.mode, 'selective');
      // foo.dart is reachable through three independent app-test closures:
      //   app test -> ai wrapper -> logic.foo,
      //   app test -> app service -> logic.foo (direct),
      //   app test -> panel -> app service -> logic.foo (transitive in app).
      // The selector must include all three (and never include the unrelated
      // helpers-only test that does not pull logic.foo).
      expect(
        plan.tests,
        equals(<String>[
          'app/test/ai/wrapper_test.dart',
          'app/test/core/service_test.dart',
          'app/test/widgets/panel_test.dart',
        ]),
      );
      expect(plan.tests, isNot(contains('app/test/features/unrelated_test.dart')));
    });

    test(
        'selective: isolated package change selects only its direct '
        'importing app test (AC-1 negative-isolation pin)', () {
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const [
          'packages/colonizethis_test/lib/helpers.dart',
        ],
      );

      // helpers.dart is reachable from exactly one app-test closure:
      //   unrelated_test -> support/fixtures.dart -> colonizethis_test.helpers
      // No other app test transitively imports the helpers module.
      expect(plan.mode, 'selective');
      expect(plan.tests, const <String>['app/test/features/unrelated_test.dart']);
    });

    test(
        'selective: transitive cross-package edge — change in '
        'packages/colonizethis_logic/lib/foo.dart selects the app test that '
        'imports a colonizethis_ai re-export of foo', () {
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const ['packages/colonizethis_logic/lib/foo.dart'],
      );

      expect(plan.tests, contains('app/test/ai/wrapper_test.dart'));
    });

    test(
        'safety net: change in packages/<pkg>/lib/** that no app test '
        'transitively imports falls back to selective + full app-test list '
        '(conservative for new / orphan / deleted package files)', () {
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const ['packages/colonizethis_models/lib/unused.dart'],
      );

      expect(plan.mode, 'selective');
      expect(plan.tests, _expectedFullAppTestList());
    });

    test(
        'cross-package test-only helper edge — change in '
        'packages/colonizethis_test/lib/helpers.dart selects the app test '
        'that imports it', () {
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const ['packages/colonizethis_test/lib/helpers.dart'],
      );

      expect(plan.tests, contains('app/test/features/unrelated_test.dart'));
    });

    test(
        'safety net: change to a brand-new (not yet on disk) app/lib path '
        'falls back to selective + full app-test list', () {
      // The path is intentionally absent from the fixture to simulate a
      // newly-added (or deleted) Dart file that the static graph cannot
      // yet reason about. Per AGENTS.md / the selector contract, the safe
      // behavior is the full app-test list rather than `skip`.
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const ['app/lib/brand_new_module.dart'],
      );

      expect(plan.mode, 'selective');
      expect(plan.tests, _expectedFullAppTestList());
    });
  });

  group('irreducible fallback (#3018 AC-3, AC-4, AC-5)', () {
    test(
        'selective + full app-test list: asset change under app/ triggers '
        'irreducible fallback', () {
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const ['app/assets/icons/foo.png'],
      );

      expect(plan.mode, 'selective');
      expect(plan.tests, _expectedFullAppTestList());
    });

    test('selective + full app-test list: root pubspec.yaml change', () {
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const ['pubspec.yaml'],
      );

      expect(plan.mode, 'selective');
      expect(plan.tests, _expectedFullAppTestList());
    });

    test(
        'selective + full app-test list: changing the selector tool itself '
        'triggers irreducible fallback', () {
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const ['tool/compute_app_test_plan.dart'],
      );

      expect(plan.mode, 'selective');
      expect(plan.tests, _expectedFullAppTestList());
    });

    test('selective + full app-test list: quality.yml change', () {
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const ['.github/workflows/quality.yml'],
      );

      expect(plan.mode, 'selective');
      expect(plan.tests, _expectedFullAppTestList());
    });

    test('selective + full app-test list: analysis_options.yaml change', () {
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const ['analysis_options.yaml'],
      );

      expect(plan.mode, 'selective');
      expect(plan.tests, _expectedFullAppTestList());
    });
  });

  group('skip cases (#3018 AC-6, determinism)', () {
    test('skip: tool-only change outside the selector', () {
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const ['tool/sim_scenarios/lib/scenario.dart'],
      );

      expect(plan.mode, 'skip');
      expect(plan.tests, isEmpty);
    });

    test('skip: empty changed file list', () {
      final plan = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: const <String>[],
      );

      expect(plan.mode, 'skip');
      expect(plan.tests, isEmpty);
    });
  });

  group('determinism (#3018 AC-12)', () {
    test(
        'identical inputs produce byte-identical mode and tests across '
        'repeated invocations', () {
      const args = <String>['packages/colonizethis_logic/lib/foo.dart'];
      final a = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: args,
      );
      final b = computeAppTestPlan(
        repoRoot: repoRoot.path,
        changedFiles: args,
      );

      expect(a.mode, b.mode);
      expect(a.tests, equals(b.tests));
    });
  });

  group('schema invariants (#3018)', () {
    test('mode is never "full" — schema is selective | skip only', () {
      final inputs = <List<String>>[
        const ['app/lib/widgets/panel.dart'],
        const ['app/assets/icons/foo.png'],
        const ['pubspec.yaml'],
        const ['tool/compute_app_test_plan.dart'],
        const ['.github/workflows/quality.yml'],
        const ['packages/colonizethis_logic/lib/foo.dart'],
        const ['tool/sim_scenarios/lib/scenario.dart'],
        const <String>[],
      ];

      for (final input in inputs) {
        final plan = computeAppTestPlan(
          repoRoot: repoRoot.path,
          changedFiles: input,
        );
        expect(plan.mode, anyOf('selective', 'skip'),
            reason: 'mode for $input must not be "full"');
      }
    });
  });

  test('CLI emits JSON for changed files', () {
    final result = Process.runSync(
      'dart',
      <String>[
        'run',
        p.join('tool', 'compute_app_test_plan.dart'),
        '--changed-files=app/lib/widgets/ct_panel.dart',
      ],
      workingDirectory: _workspaceRoot(),
    );

    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    final json = (result.stdout as String).trim();
    expect(json, contains('"mode":"selective"'));
    expect(json, contains('naval_units_panel_part1_test'));
  });
}

const _expectedFullAppTestListLiteral = <String>[
  'app/test/ai/wrapper_test.dart',
  'app/test/core/service_test.dart',
  'app/test/features/unrelated_test.dart',
  'app/test/widgets/panel_test.dart',
];

List<String> _expectedFullAppTestList() => _expectedFullAppTestListLiteral;

Future<void> _writeMinimalApp(String root) async {
  Future<void> write(String rel, String content) async {
    final file = File(p.join(root, rel));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  // Minimal workspace pubspec.yaml so the selector picks up the package map.
  // Must match the `name: colonizethis` + `workspace:` shape that
  // `_findRepoRoot` looks for, and the entries it walks.
  await write(
    'pubspec.yaml',
    '''
name: colonizethis
publish_to: none

environment:
  sdk: '>=3.11.5 <4.0.0'

workspace:
  - app
  - packages/colonizethis_logic
  - packages/colonizethis_ai
  - packages/colonizethis_models
  - packages/colonizethis_test
  - tool/sim_scenarios
''',
  );

  // App package: lib + tests.
  await write(
    'app/pubspec.yaml',
    '''
name: colonizethis_app
publish_to: none
resolution: workspace
environment:
  sdk: '>=3.11.5 <4.0.0'
''',
  );
  await write(
    'app/lib/widgets/panel.dart',
    "import 'package:colonizethis_app/core/service.dart';\n"
        'class Panel {}\n',
  );
  await write(
    'app/lib/core/service.dart',
    "import 'package:colonizethis_logic/foo.dart';\n"
        'class Service {}\n',
  );
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
  await write(
    'app/test/support/fixtures.dart',
    "import 'package:colonizethis_test/helpers.dart';\n"
        'class Fixtures {}\n',
  );
  await write(
    'app/test/features/unrelated_test.dart',
    "import '../support/fixtures.dart';\n"
        'void main() {}\n',
  );
  await write(
    'app/test/ai/wrapper_test.dart',
    "import 'package:colonizethis_ai/wrapper.dart';\n"
        'void main() {}\n',
  );

  // Package fixtures forming a cross-package edge graph:
  //   colonizethis_logic.foo  <-  colonizethis_ai.wrapper  <-  app test
  //   colonizethis_logic.foo  <-  app/lib/core/service.dart <- app test
  //   colonizethis_test.helpers <- app/test/support/fixtures.dart <- app test
  //   colonizethis_models.unused: orphan (no app test imports it)
  await write(
    'packages/colonizethis_logic/pubspec.yaml',
    'name: colonizethis_logic\nresolution: workspace\n'
        'environment:\n  sdk: ">=3.11.5 <4.0.0"\n',
  );
  await write(
    'packages/colonizethis_logic/lib/foo.dart',
    'class Foo {}\n',
  );

  await write(
    'packages/colonizethis_ai/pubspec.yaml',
    'name: colonizethis_ai\nresolution: workspace\n'
        'environment:\n  sdk: ">=3.11.5 <4.0.0"\n',
  );
  await write(
    'packages/colonizethis_ai/lib/wrapper.dart',
    "import 'package:colonizethis_logic/foo.dart';\n"
        'class Wrapper {}\n',
  );

  await write(
    'packages/colonizethis_models/pubspec.yaml',
    'name: colonizethis_models\nresolution: workspace\n'
        'environment:\n  sdk: ">=3.11.5 <4.0.0"\n',
  );
  await write(
    'packages/colonizethis_models/lib/unused.dart',
    'class Unused {}\n',
  );

  await write(
    'packages/colonizethis_test/pubspec.yaml',
    'name: colonizethis_test\nresolution: workspace\n'
        'environment:\n  sdk: ">=3.11.5 <4.0.0"\n',
  );
  await write(
    'packages/colonizethis_test/lib/helpers.dart',
    'class Helpers {}\n',
  );

  await write(
    'tool/sim_scenarios/pubspec.yaml',
    'name: sim_scenarios\nresolution: workspace\n'
        'environment:\n  sdk: ">=3.11.5 <4.0.0"\n',
  );
  await write(
    'tool/sim_scenarios/lib/scenario.dart',
    'class Scenario {}\n',
  );

  await write(
    'analysis_options.yaml',
    'include: package:lints/recommended.yaml\n',
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
