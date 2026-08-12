import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const String dossierSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/dossier_test_support.dart';

const String _perceptionTestDir = 'packages/colonizethis_ai/test/perception/';

const Set<String> dossierSharedFixtureAdopterBasenames = {
  'dossier_test.dart',
};

final RegExp _localGameWithEvidenceDecl =
    RegExp(r'Game\s+_gameWithEvidence\b');

bool _isAdopterPath(String normalized) {
  if (!normalized.startsWith(_perceptionTestDir)) {
    return false;
  }
  return dossierSharedFixtureAdopterBasenames.contains(p.basename(normalized));
}

String? aiDossierSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isAdopterPath(normalized)) {
    return null;
  }
  if (_localGameWithEvidenceDecl.hasMatch(content)) {
    return 'redeclares local `_gameWithEvidence`; import '
        '`dossierGameWithEvidence` from '
        '`$dossierSharedFixturesSupportFile` (Refs #4310)';
  }
  return null;
}

int runCheckAiDossierTestSharedFixtures(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final supportPath = p.join(
    repoRoot,
    'packages',
    'colonizethis_ai',
    'test',
    'support',
    'dossier_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_dossier_test_shared_fixtures: missing shared support file '
      '`$dossierSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiDossierSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_dossier_test_shared_fixtures: no local dossier fixture '
      'redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_dossier_test_shared_fixtures: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiDossierTestSharedFixtures(Directory.current.path));
}
