import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3574, slice 6).
///
/// Enforces the runtime dependency boundary `colonizethis_logic !-> colonizethis_map`.
///
/// `colonizethis_map` was moved from `colonizethis_logic` `dependencies` to
/// `dev_dependencies` (the package's `lib/` has zero map imports; only two
/// integration tests reference the map barrel). This gate keeps that boundary
/// from regressing: no production source under
/// `packages/colonizethis_logic/lib/**` may `import` or `export`
/// `package:colonizethis_map/...`. Test code (`packages/colonizethis_logic/test/**`)
/// is out of scope and may keep importing the map barrel.
const _logicLibRoot = 'packages/colonizethis_logic/lib';

/// Matches an `import`/`export` directive targeting the map package barrel or
/// any of its `src/` paths.
final RegExp _forbiddenMapImport = RegExp(
  r'''^\s*(?:import|export)\s+['"]package:colonizethis_map/''',
);

/// True when [line] is a pure comment line so prose mentioning the map package
/// is not flagged.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

/// True when [relativePath] is a generated Dart file that should be skipped.
bool _isGeneratedFile(String relativePath) =>
    relativePath.endsWith('.g.dart') ||
    relativePath.endsWith('.freezed.dart') ||
    relativePath.endsWith('.mocks.dart');

void main() {
  exit(runCheckLogicNoMapDeps(Directory.current.path));
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckLogicNoMapDeps(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _logicLibRoot));
  if (!libDir.existsSync()) {
    logE('check_logic_no_map_deps: missing $_logicLibRoot');
    return 1;
  }

  final violations = <LogicNoMapDepsViolation>[];
  for (final file in libDir.listSync(recursive: true, followLinks: false)) {
    if (file is! File || !file.path.endsWith('.dart')) {
      continue;
    }
    final relPath = p.normalize(p.relative(file.path, from: root));
    if (_isGeneratedFile(relPath)) {
      continue;
    }
    violations.addAll(
      findLogicNoMapDepsViolations(
        relativePath: relPath,
        source: file.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI('colonizethis_logic -> colonizethis_map dependency boundary check passed.');
    return 0;
  }

  logE(
    'ERROR: colonizethis_logic/lib must not import colonizethis_map; the map '
    'package is a dev-only dependency (move shared symbols into a logic-visible '
    'package or consume them from tests only):',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

List<LogicNoMapDepsViolation> findLogicNoMapDepsViolations({
  required String relativePath,
  required String source,
}) {
  final lines = source.split('\n');
  final violations = <LogicNoMapDepsViolation>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) {
      continue;
    }
    if (_forbiddenMapImport.hasMatch(line)) {
      violations.add(
        LogicNoMapDepsViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Production import of package:colonizethis_map; map is a dev '
              'dependency of colonizethis_logic.',
        ),
      );
    }
  }
  return violations;
}

class LogicNoMapDepsViolation {
  const LogicNoMapDepsViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
