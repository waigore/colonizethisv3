import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical GP–Minor fixture module for orders diplomatic tests (Refs #3877).
const ordersGpMinorFixtureModule =
    'packages/colonizethis_orders/test/orders/diplomatic_orders_test_fixtures.dart';

const _ordersTestPathPrefix = 'packages/colonizethis_orders/test/';

/// Matches a top-level `Game gpMinor*Game(` builder outside the canonical fixture
/// module, e.g. `Game gpMinorGame({` or `Game gpMinorBaseGame({`.
final RegExp _gpMinorGameBuilderDeclaration = RegExp(
  r'^\s*Game\s+gpMinor\w*Game\s*\(',
  multiLine: true,
);

/// True when [slashPath] is under colonizethis_orders `test/`.
bool ordersTestDedupGpMinorGamePathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_ordersTestPathPrefix);
}

/// Returns a violation reason when [slashPath] redefines a GP–Minor game builder,
/// or `null` when compliant.
String? ordersTestDedupGpMinorGameViolationReason(
  String slashPath,
  String content,
) {
  if (!ordersTestDedupGpMinorGamePathInScope(slashPath)) {
    return null;
  }
  if (slashPath.replaceAll('\\', '/') == ordersGpMinorFixtureModule) {
    return null;
  }
  final code = _stripLineComments(content);
  if (!_gpMinorGameBuilderDeclaration.hasMatch(code)) {
    return null;
  }
  return 'defines a local `Game gpMinor*Game(...)` builder; use '
      "'$ordersGpMinorFixtureModule' instead (Refs #3877)";
}

String _stripLineComments(String content) {
  final out = StringBuffer();
  for (final line in content.split('\n')) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('//') || trimmed.startsWith('*')) {
      continue;
    }
    out.writeln(line);
  }
  return out.toString();
}

int runCheckOrdersTestDedupGpMinorGame(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = ordersTestDedupGpMinorGameViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_orders_test_dedup_gp_minor_game: no duplicate GP–Minor builder '
      'violations.',
    );
    return 0;
  }
  logE(
    'check_orders_test_dedup_gp_minor_game: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckOrdersTestDedupGpMinorGame(Directory.current.path));
}
