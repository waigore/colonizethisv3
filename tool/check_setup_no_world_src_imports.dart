// Forbids `colonizethis_setup` (lib + test) from deep-importing or exporting
// `colonizethis_world`'s private `lib/src/**` tree (Refs #4054). The setup-
// facing surface (graph traversal, capital reassignment, town/capital tile
// strip, validation exceptions) is published from the `colonizethis_world`
// barrel, so all consumption must go through
// `package:colonizethis_world/colonizethis_world.dart`.
import 'dart:io';

import 'package:path/path.dart' as p;

const _scanRoots = [
  'packages/colonizethis_setup/lib',
  'packages/colonizethis_setup/test',
];

/// Matches `import`/`export` of `package:colonizethis_world/src/...`,
/// capturing the directive keyword and the in-package path.
final _worldSrcDirective = RegExp(
  r"(import|export)\s+'package:colonizethis_world/(src(?:/[^']*)?)'",
);

void main() {
  exit(runCheckSetupNoWorldSrcImports(Directory.current.path));
}

/// Returns 0 when no `colonizethis_setup` lib/test file imports or exports
/// the `colonizethis_world` `src/` tree; 1 otherwise.
int runCheckSetupNoWorldSrcImports(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final sourcesByPath = <String, String>{};

  for (final scanRoot in _scanRoots) {
    final dir = Directory(p.join(repoRoot, scanRoot));
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (_isGenerated(entity.path)) continue;
      final relativePath = p.relative(entity.path, from: repoRoot);
      sourcesByPath[relativePath] = entity.readAsStringSync();
    }
  }

  final violations = findSetupWorldSrcImportViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI(
      'check_setup_no_world_src_imports: no colonizethis_world src/ '
      'imports or exports found in colonizethis_setup.',
    );
    return 0;
  }

  logE(
    'check_setup_no_world_src_imports: colonizethis_setup must not import '
    'or export package:colonizethis_world/src/** (use the '
    'colonizethis_world barrel):',
  );
  for (final v in violations) {
    logE(' - ${v.path}:${v.line} ${v.directive}');
  }
  return 1;
}

/// Pure scan over [sourcesByPath] (relative path -> file contents); returns
/// sorted violations for every `colonizethis_world/src/` import or export.
List<SetupWorldSrcImportViolation> findSetupWorldSrcImportViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupWorldSrcImportViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final lines = sourcesByPath[path]!.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;
      final match = _worldSrcDirective.firstMatch(line);
      if (match == null) continue;
      violations.add(
        SetupWorldSrcImportViolation(
          path: path,
          line: i + 1,
          directive:
              "${match.group(1)} 'package:colonizethis_world/"
              "${match.group(2)}'",
        ),
      );
    }
  }
  return violations;
}

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

bool _isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.mocks.dart');

class SetupWorldSrcImportViolation {
  const SetupWorldSrcImportViolation({
    required this.path,
    required this.line,
    required this.directive,
  });

  final String path;
  final int line;
  final String directive;
}
