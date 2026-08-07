// Physical line ratchet for colonizethis_combat lib source (repo rule:
// `repo.combat_lib_file_size`).
//
// Phase 4 (#4284) splits near-cap combat orchestration modules so lib files stay
// below a peer-aligned 280 physical-line ceiling (economy ≤310, turn ≤400).
// Generated suffixes are excluded.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Ratchet ceiling for phase-4 post-split target (≤280 physical lines).
const int combatLibFileSizeCeiling = 280;

const String _combatLibRelativePath = 'packages/colonizethis_combat/lib';

/// Hot files still above the phase-4 ceiling during transition slices. Shrink-only
/// allowlist; remove entries as splits land.
const List<String> combatLibFileSizeGrandfathered = <String>[];

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

int runCheckCombatLibFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = combatLibFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final libDir = Directory(p.join(repoRoot, _combatLibRelativePath));
  if (!libDir.existsSync()) {
    logE('check_combat_lib_file_size: $_combatLibRelativePath not found.');
    return 1;
  }

  final grandfathered = (grandfatheredPaths ?? combatLibFileSizeGrandfathered)
      .map((path) => path.replaceAll('\\', '/'))
      .toSet();

  final missingGrandfathered = <String>[];
  for (final relativePath in grandfathered) {
    if (!File(p.join(repoRoot, relativePath)).existsSync()) {
      missingGrandfathered.add(relativePath);
    }
  }
  if (missingGrandfathered.isNotEmpty) {
    logE(
      'check_combat_lib_file_size: stale grandfather entries (file no longer '
      'exists; remove from allowlist):',
    );
    for (final relativePath in missingGrandfathered) {
      logE(' - $relativePath');
    }
    return 1;
  }

  final violations = <String>[];
  for (final filePath in _collectFilesToCheck(repoRoot, libDir, targetFiles)) {
    final file = File(filePath);
    final relativePath = p
        .relative(file.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (grandfathered.contains(relativePath)) {
      continue;
    }
    final physicalLines = const LineSplitter()
        .convert(file.readAsStringSync())
        .length;
    if (physicalLines <= ceiling) {
      continue;
    }
    violations.add('$relativePath ($physicalLines physical lines > $ceiling)');
  }

  if (violations.isEmpty) {
    logI(
      'check_combat_lib_file_size: no violations found '
      '(ceiling $ceiling; Refs #4284).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_combat_lib_file_size: found ${violations.length} violation(s) '
    'under $_combatLibRelativePath (phase-4 ceiling $ceiling; Refs #4284):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  Directory libDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return libDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .where((path) => !_generatedSuffix.hasMatch(path))
        .toList(growable: false);
  }

  const prefix = '$_combatLibRelativePath/';
  final results = <String>[];
  for (final relativePath in targetFiles) {
    final normalized = relativePath.replaceAll('\\', '/');
    if (!normalized.startsWith(prefix) || !normalized.endsWith('.dart')) {
      continue;
    }
    if (_generatedSuffix.hasMatch(normalized)) {
      continue;
    }
    final file = File(p.join(repoRoot, normalized));
    if (!file.existsSync()) {
      continue;
    }
    results.add(file.path);
  }
  return results;
}

int maxCombatLibFilePhysicalLinesForTests() => combatLibFileSizeCeiling;

void main(List<String> args) {
  final files = repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(
    runCheckCombatLibFileSize(
      Directory.current.path,
      targetFiles: files.isEmpty ? null : files,
    ),
  );
}
