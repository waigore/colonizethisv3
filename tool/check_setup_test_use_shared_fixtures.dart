import 'dart:io';

import 'package:path/path.dart' as p;

/// Setup package tests must use shared [TestFixtures] / [configWithOverrides]
/// instead of re-inlining empty [Game]/[WorldState] shells or full
/// [GameSetupConfig] rebuilds (Refs #4029).
const String _setupTestPathPrefix = 'packages/colonizethis_setup/test/';

const String _configSupportRelativePath =
    'packages/colonizethis_setup/test/setup/'
    'init_game_orchestrator_test_support.dart';

final RegExp _inlineGameConstructor = RegExp(r'\bGame\s*\(');
final RegExp _inlineWorldStateConstructor = RegExp(r'\bWorldState\s*\(');
final RegExp _inlineGameSetupConfigConstructor = RegExp(
  r'\bGameSetupConfig\s*\(',
);

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupTestUseSharedFixtures(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, 'packages/colonizethis_setup/test'));
  if (!dir.existsSync()) {
    logI('Setup test shared-fixtures check skipped (test dir absent).');
    return 0;
  }

  final violations = <SetupTestSharedFixturesViolation>[];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final slashPath = p.relative(entity.path, from: root).replaceAll('\\', '/');
    final reason = setupTestSharedFixturesViolationReason(
      slashPath,
      entity.readAsStringSync(),
    );
    if (reason != null) {
      violations.add(
        SetupTestSharedFixturesViolation(path: slashPath, message: reason),
      );
    }
  }

  if (violations.isEmpty) {
    logI('Setup test shared-fixtures check passed.');
    return 0;
  }

  logE(
    'ERROR: Setup tests must use TestFixtures / configWithOverrides '
    '(or lockedFullInitConfig) instead of inlining empty Game/WorldState '
    'shells or GameSetupConfig rebuilds (Refs #4029).',
  );
  for (final v in violations) {
    logE('${v.path} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupTestUseSharedFixtures(Directory.current.path));
}

/// True when repo-relative [slashPath] is under the setup package `test/` tree.
bool setupTestUseSharedFixturesPathInScope(String slashPath) =>
    slashPath.replaceAll('\\', '/').startsWith(_setupTestPathPrefix);

/// Returns a violation reason when [content] of an in-scope setup test file
/// re-inlines empty game/world shells or full [GameSetupConfig] constructors,
/// or `null` when compliant.
String? setupTestSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!setupTestUseSharedFixturesPathInScope(normalized)) return null;
  final code = _stripLineComments(content);

  if (normalized != _configSupportRelativePath &&
      _inlineGameSetupConfigConstructor.hasMatch(code)) {
    return 're-inlines GameSetupConfig(...); use configWithOverrides / '
        'lockedFullInitConfig from init_game_orchestrator_test_support.dart '
        '(Refs #4029)';
  }

  final inlineGame = _inlineGameConstructor.hasMatch(code);
  final inlineWorldState = _inlineWorldStateConstructor.hasMatch(code);
  if (!inlineGame && !inlineWorldState) return null;

  final parts = <String>[
    if (inlineGame) 'Game(...)',
    if (inlineWorldState) 'WorldState(...)',
  ];
  return 're-inlines ${parts.join(' + ')}; use TestFixtures '
      '(package:colonizethis_test/game_test_fixtures.dart) or a thin support '
      'delegate (Refs #4029)';
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

class SetupTestSharedFixturesViolation {
  const SetupTestSharedFixturesViolation({
    required this.path,
    required this.message,
  });

  final String path;
  final String message;
}
