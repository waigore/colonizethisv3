import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_rule_routing.dart';

void main() {
  test('passes when routing index, globs, and pointers are present', () {
    final tempDir = Directory.systemTemp.createTempSync(
      'check_rule_routing_pass_',
    );
    addTearDown(() => tempDir.deleteSync(recursive: true));

    _writeFixture(tempDir.path);
    final stdoutLines = <String>[];
    final code = runCheckRuleRouting(tempDir.path, info: stdoutLines.add);

    expect(code, 0);
    expect(stdoutLines.join('\n'), contains('no violations found'));
  });

  test('fails when lifecycle rule still uses broad glob', () {
    final tempDir = Directory.systemTemp.createTempSync(
      'check_rule_routing_fail_',
    );
    addTearDown(() => tempDir.deleteSync(recursive: true));

    _writeFixture(
      tempDir.path,
      lifecycleGlob: '**/*.dart',
      includeRoutingPointerInAgents: false,
    );
    final stderrLines = <String>[];
    final code = runCheckRuleRouting(tempDir.path, err: stderrLines.add);

    expect(code, 1);
    expect(
      stderrLines.join('\n'),
      contains('colonizethis-lifecycle.mdc must define targeted globs.'),
    );
    expect(
      stderrLines.join('\n'),
      contains('colonizethis-lifecycle.mdc still uses broad **/*.dart glob.'),
    );
    expect(
      stderrLines.join('\n'),
      contains('AGENTS.md must reference the routing index.'),
    );
  });
}

void _writeFixture(
  String root, {
  String lifecycleGlob =
      'app/lib/game/**/*.dart,app/lib/widgets/**/*.dart,app/lib/ui/**/*.dart,app/lib/screens/**/*.dart,app/lib/pages/**/*.dart',
  bool includeRoutingPointerInAgents = true,
}) {
  File(p.join(root, '.cursor', 'rules', 'routing-index.md'))
    ..createSync(recursive: true)
    ..writeAsStringSync('# Routing index');

  File(p.join(root, '.cursor', 'rules', 'colonizethis-component-structure.mdc'))
    ..createSync(recursive: true)
    ..writeAsStringSync('''
---
globs: "app/lib/**/*.dart,packages/*/lib/**/*.dart,tool/**/*.dart"
---
''');

  File(p.join(root, '.cursor', 'rules', 'colonizethis-code-review.mdc'))
    ..createSync(recursive: true)
    ..writeAsStringSync('''
---
globs: "app/lib/**/*.dart,packages/*/lib/**/*.dart,tool/**/*.dart"
---
''');

  File(p.join(root, '.cursor', 'rules', 'colonizethis-lifecycle.mdc'))
    ..createSync(recursive: true)
    ..writeAsStringSync('''
---
globs: "$lifecycleGlob"
---
''');

  File(
      p.join(
        root,
        '.opencode',
        'skills',
        'refactoring-opportunity-github-issue',
        'references',
        'ci-and-rules.md',
      ),
    )
    ..createSync(recursive: true)
    ..writeAsStringSync('see .cursor/rules/routing-index.md');

  File(p.join(root, 'AGENTS.md'))
    ..createSync(recursive: true)
    ..writeAsStringSync(
      includeRoutingPointerInAgents
          ? 'see .cursor/rules/routing-index.md'
          : 'missing routing pointer',
    );
}
