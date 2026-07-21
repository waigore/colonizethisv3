// Physical line ratchet for colonizethis_orders lib source (repo rule:
// `repo.orders_lib_source_file_size`).
//
// Wave 5 (#4109) split the remaining near-cap modules (prechecks, ICE replay,
// feedstock gates, explorer probes) so most lib files stay well below the
// shared 500-line `repo.domain_package_source_file_size` cap. This tighter
// orders-only ceiling keeps the splits from silently re-growing.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Ratchet ceiling chosen at wave-5 post-split target (~400 physical lines).
const int ordersLibSourceFileSizeCeiling = 400;

const String _ordersLibRelativePath = 'packages/colonizethis_orders/lib';

/// Hot files still above the wave-5 physical-line ceiling but separately gated
/// by `repo.orders_file_size` (1000 non-comment lines). Shrink-only allowlist.
const List<String> ordersLibSourceFileSizeGrandfathered = <String>[
  'packages/colonizethis_orders/lib/src/orders/order_engine_validation.dart',
  'packages/colonizethis_orders/lib/src/orders/validators/work_order_validator.dart',
];

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

int runCheckOrdersLibSourceFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = ordersLibSourceFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final libDir = Directory(p.join(repoRoot, _ordersLibRelativePath));
  if (!libDir.existsSync()) {
    logE('check_orders_lib_source_file_size: $_ordersLibRelativePath not found.');
    return 1;
  }

  final grandfathered =
      (grandfatheredPaths ?? ordersLibSourceFileSizeGrandfathered)
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
      'check_orders_lib_source_file_size: stale grandfather entries (file no '
      'longer exists; remove from allowlist):',
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
      'check_orders_lib_source_file_size: no violations found '
      '(ceiling $ceiling; Refs #4109).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_orders_lib_source_file_size: found ${violations.length} violation(s) '
    'under $_ordersLibRelativePath (wave-5 ceiling $ceiling; Refs #4109):',
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

  const prefix = '$_ordersLibRelativePath/';
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

int maxOrdersLibSourceFilePhysicalLinesForTests() =>
    ordersLibSourceFileSizeCeiling;

void main(List<String> args) {
  final files = repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(
    runCheckOrdersLibSourceFileSize(
      Directory.current.path,
      targetFiles: files.isEmpty ? null : files,
    ),
  );
}
