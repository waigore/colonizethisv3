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

  test('selective: changed lib file selects importing test only', () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['app/lib/widgets/panel.dart'],
    );

    expect(plan.mode, 'selective');
    expect(
      plan.tests,
      ['app/test/widgets/panel_test.dart'],
    );
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

  test('full: asset change under app/', () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['app/assets/icons/foo.png'],
    );

    expect(plan.mode, 'full');
    expect(plan.tests, isEmpty);
  });

  test('full: package change', () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['packages/colonizethis_logic/lib/foo.dart'],
    );

    expect(plan.mode, 'full');
    expect(plan.tests, isEmpty);
  });

  test('skip: tool-only change', () {
    final plan = computeAppTestPlan(
      repoRoot: repoRoot.path,
      changedFiles: ['tool/sim_scenarios/lib/scenario.dart'],
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

  test('CLI emits JSON for changed files', () {
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

Future<void> _writeMinimalApp(String root) async {
  Future<void> write(String rel, String content) async {
    final file = File(p.join(root, rel));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  await write(
    'app/lib/widgets/panel.dart',
    "import 'package:colonizethis_app/core/service.dart';\n"
    'class Panel {}\n',
  );
  await write(
    'app/lib/core/service.dart',
    'class Service {}\n',
  );
  await write(
    'app/test/widgets/panel_test.dart',
    "import 'package:colonizethis_app/widgets/panel.dart';\n"
    "void main() {}\n",
  );
  await write(
    'app/test/core/service_test.dart',
    "import 'package:colonizethis_app/core/service.dart';\n"
    "void main() {}\n",
  );
  await write(
    'app/test/support/fixtures.dart',
    'class Fixtures {}\n',
  );
  await write(
    'app/test/features/unrelated_test.dart',
    "import '../support/fixtures.dart';\n"
    "void main() {}\n",
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
