import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #4410).
///
/// Forbid leftover `*_expectations.dart` modules under
/// `packages/colonizethis_economy_test_support/lib/**` after the wave-2
/// leftover merge. Pin types live in paired scenarios or same-folder
/// siblings.

const String economyTestSupportLibRelativeDir =
    'packages/colonizethis_economy_test_support/lib';

bool isEconomyTestSupportExpectationsModule(String fileName) {
  return fileName.endsWith('_expectations.dart');
}

int runCheckEconomyTestSupportNoExpectationsModules(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final libDir = Directory(p.join(repoRoot, economyTestSupportLibRelativeDir));
  if (!libDir.existsSync()) {
    logE(
      'check_economy_test_support_no_expectations_modules: missing '
      '$economyTestSupportLibRelativeDir',
    );
    return 1;
  }

  final hits = <String>[];
  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    if (!entity.path.endsWith('.dart')) {
      continue;
    }
    final base = p.basename(entity.path);
    if (isEconomyTestSupportExpectationsModule(base)) {
      hits.add(p.relative(entity.path, from: repoRoot).replaceAll('\\', '/'));
    }
  }

  if (hits.isEmpty) {
    logI(
      'check_economy_test_support_no_expectations_modules: no leftover '
      '*_expectations.dart modules (Refs #4410).',
    );
    return 0;
  }

  logE(
    'check_economy_test_support_no_expectations_modules: ${hits.length} '
    '*_expectations.dart module(s) under $economyTestSupportLibRelativeDir '
    '(Refs #4410):',
  );
  for (final hit in hits) {
    logE(' - $hit');
  }
  return 1;
}

void main() {
  exit(runCheckEconomyTestSupportNoExpectationsModules(Directory.current.path));
}
