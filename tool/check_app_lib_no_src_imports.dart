import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #4269 Slice B).
///
/// Forbid `package:colonizethis_<domain>/src/` imports under `app/lib/**`.
/// UI must consume promoted symbols through domain barrels or narrow logic
/// contract entrypoints.
const _appLibPrefix = 'app/lib/';

final RegExp _forbiddenAppSrcImport = RegExp(
  r'''import\s+['"]package:colonizethis_[^/'"]+/src/[^'"]+['"]''',
);

bool appLibNoSrcImportsPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_appLibPrefix) && normalized.endsWith('.dart');
}

String? appLibNoSrcImportsViolationReason(String content) {
  final match = _forbiddenAppSrcImport.firstMatch(content);
  if (match == null) {
    return null;
  }
  return 'use a domain barrel or narrow logic contract instead of src/ imports '
      '(Refs #4269)';
}

int runCheckAppLibNoSrcImports(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  final appLibDir = Directory(p.join(repoRoot, 'app', 'lib'));
  if (!appLibDir.existsSync()) {
    logE('check_app_lib_no_src_imports: app/lib not found');
    return 1;
  }

  for (final entity in appLibDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final rel = p.relative(entity.path, from: repoRoot).replaceAll('\\', '/');
    if (!appLibNoSrcImportsPathInScope(rel)) {
      continue;
    }
    final content = entity.readAsStringSync();
    final reason = appLibNoSrcImportsViolationReason(content);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_app_lib_no_src_imports: no src/ import violations.');
    return 0;
  }

  logE('check_app_lib_no_src_imports: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAppLibNoSrcImports(Directory.current.path));
}
