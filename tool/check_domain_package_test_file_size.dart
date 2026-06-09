// Physical line limit for split domain-package tests (Refs #3290).
// Mirrors `repo.logic_test_file_size` (400 physical lines) across every
// `packages/colonizethis_<domain>/test/**` tree for the eight extracted
// logic-domain packages.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _maxPhysicalLines = 400;

/// Domain packages whose migrated test suites must stay within the shared cap.
const List<String> domainPackageTestFileSizeDomainsForTests = [
  'world',
  'combat',
  'economy',
  'diplomacy',
  'setup',
  'orders',
  'turn',
  'ai_contracts',
];

int runCheckDomainPackageTestFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final violations = <String>[];

  for (final domain in domainPackageTestFileSizeDomainsForTests) {
    final testDir = Directory(
      p.join(repoRoot, 'packages', 'colonizethis_$domain', 'test'),
    );
    if (!testDir.existsSync()) {
      logE(
        'check_domain_package_test_file_size: '
        'packages/colonizethis_$domain/test not found.',
      );
      return 1;
    }

    final filesToCheck = _collectFilesToCheck(
      repoRoot,
      domain,
      testDir,
      targetFiles,
    );
    for (final filePath in filesToCheck) {
      final file = File(filePath);
      final relativePath = p.relative(file.path, from: repoRoot);
      final physicalLines = const LineSplitter()
          .convert(file.readAsStringSync())
          .length;
      if (physicalLines <= _maxPhysicalLines) {
        continue;
      }
      violations.add(
        '$relativePath ($physicalLines physical lines > $_maxPhysicalLines)',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_domain_package_test_file_size: no violations found.');
    return 0;
  }

  logE(
    'check_domain_package_test_file_size: found ${violations.length} '
    'violation(s) under split domain-package test trees:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  String domain,
  Directory testDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return testDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .toList(growable: false);
  }

  final prefix = 'packages/colonizethis_$domain/test/';
  final results = <String>[];
  for (final relativePath in targetFiles) {
    if (!relativePath.startsWith(prefix) || !relativePath.endsWith('.dart')) {
      continue;
    }
    final absolutePath = p.join(repoRoot, relativePath);
    final file = File(absolutePath);
    if (!file.existsSync()) {
      continue;
    }
    results.add(file.path);
  }
  return results;
}

void main(List<String> args) {
  exit(
    runCheckDomainPackageTestFileSize(
      Directory.current.path,
      targetFiles: args.isEmpty ? null : args,
    ),
  );
}

int maxDomainPackageTestFilePhysicalLinesForTests() => _maxPhysicalLines;
