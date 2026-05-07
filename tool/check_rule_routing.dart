import 'dart:io';

import 'package:path/path.dart' as p;

const Map<String, String> _requiredGlobs = {
  '.cursor/rules/colonizethis-component-structure.mdc':
      'app/lib/**/*.dart,packages/*/lib/**/*.dart,tool/**/*.dart',
  '.cursor/rules/colonizethis-code-review.mdc':
      'app/lib/**/*.dart,packages/*/lib/**/*.dart,tool/**/*.dart',
  '.cursor/rules/colonizethis-lifecycle.mdc':
      'app/lib/game/**/*.dart,app/lib/widgets/**/*.dart,app/lib/ui/**/*.dart,app/lib/screens/**/*.dart,app/lib/pages/**/*.dart',
};

const Set<String> _requiredPointers = {
  'AGENTS.md',
  '.opencode/skills/refactoring-opportunity-github-issue/references/ci-and-rules.md',
};

int runCheckRuleRouting(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logInfo = info ?? stdout.writeln;
  final logErr = err ?? stderr.writeln;
  final violations = <String>[];

  final routingIndex = File(
    p.join(repoRoot, '.cursor', 'rules', 'routing-index.md'),
  );
  if (!routingIndex.existsSync()) {
    violations.add('missing .cursor/rules/routing-index.md');
  }

  for (final entry in _requiredGlobs.entries) {
    final file = File(p.join(repoRoot, entry.key));
    if (!file.existsSync()) {
      violations.add('missing ${entry.key}');
      continue;
    }
    final content = file.readAsStringSync();
    if (!content.contains('globs: "${entry.value}"')) {
      violations.add('${entry.key} must define targeted globs.');
    }
    if (content.contains('globs: "**/*.dart"')) {
      violations.add('${entry.key} still uses broad **/*.dart glob.');
    }
  }

  for (final relativePath in _requiredPointers) {
    final file = File(p.join(repoRoot, relativePath));
    if (!file.existsSync()) {
      violations.add('missing $relativePath');
      continue;
    }
    final content = file.readAsStringSync();
    if (!content.contains('.cursor/rules/routing-index.md')) {
      violations.add('$relativePath must reference the routing index.');
    }
  }

  if (violations.isEmpty) {
    logInfo('check_rule_routing: no violations found.');
    return 0;
  }

  logErr('check_rule_routing: found ${violations.length} violation(s):');
  for (final violation in violations) {
    logErr(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckRuleRouting(Directory.current.path));
}
