// Forbids world tests and world pubspec from depending on colonizethis_logic,
// colonizethis_turn, or colonizethis_orders (Refs #4515). orders → world already;
// a world test/dev dep would invert the domain DAG.
import 'dart:io';

import 'package:path/path.dart' as p;

const _worldTestRelative = 'packages/colonizethis_world/test';
const _worldPubspecRelative = 'packages/colonizethis_world/pubspec.yaml';

final _forbiddenImport = RegExp(
  r"import\s+'package:colonizethis_(logic|turn|orders)/",
);

final _forbiddenPubspecDep = RegExp(
  r'^  colonizethis_(logic|turn|orders)\s*:',
  multiLine: true,
);

void main() {
  exit(runCheckWorldTestNoUpstreamDomainDeps(Directory.current.path));
}

int runCheckWorldTestNoUpstreamDomainDeps(
  String repoRoot, {
  void Function(String line)? err,
}) {
  final logE = err ?? stderr.writeln;
  final testDir = Directory(p.join(repoRoot, _worldTestRelative));
  if (!testDir.existsSync()) {
    logE(
      'check_world_test_no_upstream_domain_deps: missing $_worldTestRelative',
    );
    return 1;
  }

  final violations = <String>[];
  for (final entity in testDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final content = entity.readAsStringSync();
    if (_forbiddenImport.hasMatch(content)) {
      violations.add(p.relative(entity.path, from: repoRoot));
    }
  }

  final pubspec = File(p.join(repoRoot, _worldPubspecRelative));
  if (!pubspec.existsSync()) {
    logE(
      'check_world_test_no_upstream_domain_deps: missing $_worldPubspecRelative',
    );
    return 1;
  }
  if (_forbiddenPubspecDep.hasMatch(pubspec.readAsStringSync())) {
    violations.add(_worldPubspecRelative);
  }

  if (violations.isEmpty) {
    return 0;
  }

  logE(
    'check_world_test_no_upstream_domain_deps: colonizethis_world test/** '
    'and pubspec.yaml must not depend on colonizethis_logic, '
    'colonizethis_turn, or colonizethis_orders:',
  );
  for (final path in violations) {
    logE(' - $path');
  }
  return 1;
}
