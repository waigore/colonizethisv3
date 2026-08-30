// Physical line ratchet for colonizethis_economy lib source (repo rule:
// `repo.economy_source_file_size`).
//
// The shared `repo.domain_package_source_file_size` gate caps every split
// domain-package `lib/src` file at 500 physical lines. The phase-7 economy
// refactor (Refs #4049) factored the remaining multi-concern kitchen-sink
// libraries (`treasury_bid_budget.dart`, `town_manufacturing_bonus.dart`,
// `first_right_credits.dart`, `tile_extraction_pipeline.dart`) into
// single-concern siblings, leaving every economy lib file at or below
// ~302 physical lines. Phase 8 (#4299) lowered the ceiling to 260 after
// near-cap splits. This tighter economy-only ceiling keeps the splits from
// silently re-growing back toward the shared 500-line cap.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Ratchet ceiling for phase-9 economy lib files (Refs #4550).
const int economySourceFileSizeCeiling = 250;

const String _economyLibRelativePath = 'packages/colonizethis_economy/lib';

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

int runCheckEconomySourceFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = economySourceFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final libDir = Directory(p.join(repoRoot, _economyLibRelativePath));
  if (!libDir.existsSync()) {
    logE('check_economy_source_file_size: $_economyLibRelativePath not found.');
    return 1;
  }

  final violations = <String>[];
  for (final filePath in _collectFilesToCheck(repoRoot, libDir, targetFiles)) {
    final file = File(filePath);
    final relativePath = p.relative(file.path, from: repoRoot);
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
      'check_economy_source_file_size: no violations found '
      '(ceiling $ceiling; Refs #4550).',
    );
    return 0;
  }

  logE(
    'check_economy_source_file_size: found ${violations.length} violation(s) '
    'under $_economyLibRelativePath (phase-9 ceiling $ceiling; Refs #4550):',
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

  final results = <String>[];
  for (final relativePath in targetFiles) {
    if (!relativePath.startsWith('$_economyLibRelativePath/') ||
        !relativePath.endsWith('.dart') ||
        _generatedSuffix.hasMatch(relativePath)) {
      continue;
    }
    final file = File(p.join(repoRoot, relativePath));
    if (!file.existsSync()) {
      continue;
    }
    results.add(file.path);
  }
  return results;
}

void main(List<String> args) {
  exit(
    runCheckEconomySourceFileSize(
      Directory.current.path,
      targetFiles: args.isEmpty ? null : args,
    ),
  );
}
