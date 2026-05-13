import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #2391, Pattern 1).
///
/// Enforces the consolidated logger contract for `colonizethis_logic`:
/// `lib/src/**` files must consume the shared `logicLog` from
/// `package_logger.dart` instead of re-declaring private duplicates of
/// `final _log = packageLogger();`. The single shared instance prevents
/// 32+ split-brain copies of the same package logger declaration.
///
/// Sub-prefixed loggers (`packageLogger('subprefix')`) and explicitly named
/// instances such as `final _gameEventLog = packageLogger();` are NOT covered
/// by this check; only the bare anonymous `_log = packageLogger()` pattern is
/// rejected.

const _logicSrcRelative = 'packages/colonizethis_logic/lib/src';

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
  final srcDir = Directory(p.join(root, _logicSrcRelative));
  if (!srcDir.existsSync()) {
    logE('ERROR: Missing logic src directory: $_logicSrcRelative');
    return 1;
  }

  final violations = <String>[];
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

  if (violations.isEmpty) {
    logI('check_logic_dedup_logger: no violations found.');
    return 0;
  }

  logE(
    'check_logic_dedup_logger: found ${violations.length} duplicate '
    "`final _log = packageLogger();` declaration(s) in "
    "$_logicSrcRelative. Use the shared `logicLog` from "
    "package:colonizethis_logic/package_logger.dart instead.",
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}
