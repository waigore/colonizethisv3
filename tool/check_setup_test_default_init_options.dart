import 'dart:io';

import 'package:path/path.dart' as p;

/// Setup-package tests must reuse [defaultInitOptions] from
/// `init_game_orchestrator_test_support.dart` instead of repeating the
/// `InitGameOptions(cellSize: 8, renderPng: false)` literal (Refs #3840).
const _setupTestPathPrefix = 'packages/colonizethis_setup/test/';

const _testSupportRelativePath =
    'packages/colonizethis_setup/test/setup/init_game_orchestrator_test_support.dart';

final RegExp _bannedLiteralPattern = RegExp(
  r'InitGameOptions\s*\(\s*cellSize:\s*8\s*,\s*renderPng:\s*false\s*\)',
);

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupTestDefaultInitOptions(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, 'packages/colonizethis_setup/test'));
  if (!dir.existsSync()) {
    logI('Setup test default-init-options check skipped (test dir absent).');
    return 0;
  }

  final violations = <SetupTestDefaultInitOptionsViolation>[];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final slashPath = p.relative(entity.path, from: root).replaceAll('\\', '/');
    if (slashPath == _testSupportRelativePath) continue;
    final lines = entity.readAsStringSync().split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;
      if (_bannedLiteralPattern.hasMatch(line)) {
        violations.add(
          SetupTestDefaultInitOptionsViolation(
            path: slashPath,
            line: i + 1,
            message:
                'Use defaultInitOptions from init_game_orchestrator_test_support.dart '
                'instead of repeating InitGameOptions(cellSize: 8, renderPng: false).',
          ),
        );
      }
    }
  }

  if (violations.isEmpty) {
    logI('Setup test default-init-options check passed.');
    return 0;
  }

  logE(
    'ERROR: Setup tests must use defaultInitOptions from test support instead '
    'of the repeated InitGameOptions(cellSize: 8, renderPng: false) literal.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupTestDefaultInitOptions(Directory.current.path));
}

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

List<SetupTestDefaultInitOptionsViolation>
findSetupTestDefaultInitOptionsViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupTestDefaultInitOptionsViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    if (path == _testSupportRelativePath) continue;
    if (!path.replaceAll('\\', '/').startsWith(_setupTestPathPrefix)) {
      continue;
    }
    final lines = sourcesByPath[path]!.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;
      if (_bannedLiteralPattern.hasMatch(line)) {
        violations.add(
          SetupTestDefaultInitOptionsViolation(
            path: path,
            line: i + 1,
            message: 'Banned InitGameOptions literal; use defaultInitOptions.',
          ),
        );
      }
    }
  }
  return violations;
}

class SetupTestDefaultInitOptionsViolation {
  const SetupTestDefaultInitOptionsViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
