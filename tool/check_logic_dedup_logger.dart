import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #2391, Pattern 1).
///
/// Enforces the consolidated logger contract for `colonizethis_logic` and the
/// split logic-domain packages (Refs #3290): `lib/src/**` files must consume
/// their package's shared package logger (for example `logicLog` from
/// `package:colonizethis_logic/package_logger.dart`) instead of re-declaring
/// private duplicates of `final _log = packageLogger();`. A single shared
/// instance per package prevents split-brain copies of the same package logger
/// declaration.
///
/// Post-split (Refs #3290) the domain code that originally lived in the
/// `colonizethis_logic` monolith moved into the eight split domain packages.
/// Scanning only the now-thin `colonizethis_logic/lib/src` core would make this
/// gate a silent no-op, so it scans every split domain package source tree plus
/// the thin core where a bare `final _log = packageLogger();` duplicate could
/// regress.
///
/// Sub-prefixed loggers (`packageLogger('subprefix')`) and explicitly named
/// instances such as `final _gameEventLog = packageLogger();` are NOT covered
/// by this check; only the bare anonymous `_log = packageLogger()` pattern is
/// rejected.

/// Production source trees scanned for bare `final _log = packageLogger();`
/// declarations.
const _scanDirsRelative = <String>[
  'packages/colonizethis_world/lib/src',
  'packages/colonizethis_combat/lib/src',
  'packages/colonizethis_economy/lib/src',
  'packages/colonizethis_diplomacy/lib/src',
  'packages/colonizethis_setup/lib/src',
  'packages/colonizethis_orders/lib/src',
  'packages/colonizethis_turn/lib/src',
  'packages/colonizethis_ai_contracts/lib/src',
  'packages/colonizethis_logic/lib/src',
];

/// Exposed for tests verifying the post-split scan roots.
List<String> logicDedupLoggerScanDirsForTests() =>
    List<String>.unmodifiable(_scanDirsRelative);

/// Top-level (non-indented) `final _log = packageLogger();` declaration.
final RegExp _localPackageLoggerDecl = RegExp(
  r'^final\s+_log\s*=\s*packageLogger\s*\(\s*\)\s*;',
  multiLine: true,
);

void main(List<String> args) {
  exit(runCheckLogicDedupLogger(Directory.current.path));
}

int runCheckLogicDedupLogger(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final root = p.normalize(repoRoot);
  final scanRoots = <Directory>[];
  for (final relative in _scanDirsRelative) {
    final dir = Directory(p.join(root, relative));
    if (!dir.existsSync()) {
      logE('ERROR: Missing logic src directory: $relative');
      return 1;
    }
    scanRoots.add(dir);
  }

  final violations = <String>[];
  for (final srcDir in scanRoots) {
    for (final entity in srcDir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relative = p.relative(entity.path, from: root);
      final content = entity.readAsStringSync();
      final match = _localPackageLoggerDecl.firstMatch(content);
      if (match == null) continue;
      final lineNumber =
          '\n'.allMatches(content.substring(0, match.start)).length + 1;
      violations.add('$relative:$lineNumber');
    }
  }

  if (violations.isEmpty) {
    logI('check_logic_dedup_logger: no violations found.');
    return 0;
  }

  logE(
    'check_logic_dedup_logger: found ${violations.length} duplicate '
    "`final _log = packageLogger();` declaration(s) across the split "
    "logic-domain packages. Use that package's shared package logger "
    '(for example `logicLog` from '
    'package:colonizethis_logic/package_logger.dart) instead.',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}
