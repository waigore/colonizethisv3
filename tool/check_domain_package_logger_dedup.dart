import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3393, Phase 2 — logging dedup).
///
/// Enforces that every `packages/<pkg>/lib/package_logger.dart` consumes the
/// shared `domainPackageLogger(prefix, [subPrefix])` factory from
/// `colonizethis_logger` instead of copy-pasting the identical prefix-composition
/// body. The historic copy-paste declared a local
/// `packageLogger([subPrefix])` whose body constructed `CtLogger(...)` directly:
///
/// ```dart
/// CtLogger packageLogger([String? subPrefix]) {
///   if (subPrefix == null || subPrefix.isEmpty) {
///     return CtLogger(kPackageLogPrefix);
///   }
///   return CtLogger('$kPackageLogPrefix.$subPrefix');
/// }
/// ```
///
/// The compliant form delegates:
///
/// ```dart
/// CtLogger packageLogger([String? subPrefix]) =>
///     domainPackageLogger(kPackageLogPrefix, subPrefix);
/// ```
///
/// A `lib/package_logger.dart` is therefore a violation when it constructs a
/// `CtLogger(` instance inline (the duplicated body). Re-exporting the type via
/// `export '...' show CtLogger;` and annotating the return type
/// (`CtLogger packageLogger(...)`) are not flagged because neither places an
/// opening parenthesis immediately after the `CtLogger` token. The shared
/// factory itself lives in `lib/src/package_domain_logger.dart`, which this rule
/// does not scan, so the single canonical construction site is preserved.

/// Inline `CtLogger(` construction — the copy-paste marker.
final RegExp _inlineCtLoggerConstruction = RegExp(r'\bCtLogger\s*\(');

/// Marker that the wrapper delegates to the shared factory.
const String _sharedFactoryCall = 'domainPackageLogger(';

void main(List<String> args) {
  exit(runCheckDomainPackageLoggerDedup(Directory.current.path));
}

int runCheckDomainPackageLoggerDedup(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final root = p.normalize(repoRoot);
  final packagesDir = Directory(p.join(root, 'packages'));
  if (!packagesDir.existsSync()) {
    logE('ERROR: Missing packages directory: packages');
    return 1;
  }

  final loggerFiles = <File>[];
  for (final entity in packagesDir.listSync(followLinks: false)) {
    if (entity is! Directory) continue;
    final loggerFile = File(p.join(entity.path, 'lib', 'package_logger.dart'));
    if (loggerFile.existsSync()) {
      loggerFiles.add(loggerFile);
    }
  }
  loggerFiles.sort((a, b) => a.path.compareTo(b.path));

  if (loggerFiles.isEmpty) {
    logE('ERROR: No packages/*/lib/package_logger.dart files found to scan.');
    return 1;
  }

  final violations = <String>[];
  for (final file in loggerFiles) {
    final relative = p.relative(file.path, from: root);
    final content = file.readAsStringSync();
    final match = _inlineCtLoggerConstruction.firstMatch(content);
    if (match == null) continue;
    final lineNumber =
        '\n'.allMatches(content.substring(0, match.start)).length + 1;
    final delegates = content.contains(_sharedFactoryCall);
    violations.add(
      '$relative:$lineNumber'
      "${delegates ? ' (delegates but also constructs CtLogger inline)' : ''}",
    );
  }

  if (violations.isEmpty) {
    logI('check_domain_package_logger_dedup: no violations found.');
    return 0;
  }

  logE(
    'check_domain_package_logger_dedup: found ${violations.length} '
    'package_logger.dart file(s) that construct `CtLogger(...)` inline. '
    'Delegate to the shared '
    '`domainPackageLogger(kPackageLogPrefix, subPrefix)` factory from '
    'package:colonizethis_logger/colonizethis_logger.dart instead of '
    'copy-pasting the prefix-composition body.',
  );
  for (final v in violations) {
    logE(' - $v');
  }
  return 1;
}
