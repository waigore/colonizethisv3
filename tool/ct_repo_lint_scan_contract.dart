import 'dart:io';

import 'package:path/path.dart' as p;

/// Shared “domain runtime Dart” scan roots for repo-wide AST checks.
///
/// SPEC: SPEC/program/repo-lint.md
const List<String> repoLintDomainScanRoots = <String>[
  'packages',
  'app/lib',
  'ctdev/lib',
  'ctterm/lib',
  'tool',
];

/// True when [relativePathFromRepo] should not be scanned (test/fixture context
/// or generated Dart), matching the historical `check_*` predicates.
bool repoLintPathIsExcludedTestOrGeneratedDart(String relativePathFromRepo) {
  if (!relativePathFromRepo.endsWith('.dart')) {
    return true;
  }
  if (relativePathFromRepo.contains('/test/') ||
      relativePathFromRepo.endsWith('_test.dart')) {
    return true;
  }
  if (relativePathFromRepo.endsWith('.g.dart') ||
      relativePathFromRepo.endsWith('.freezed.dart') ||
      relativePathFromRepo.endsWith('.mocks.dart')) {
    return true;
  }
  return false;
}

/// True for `.dart` files under a `lib/` directory segment, excluding tests and
/// generated files — the set walked by [collectRepoLintDomainDartFiles].
bool repoLintPathIsDomainLibSourceForScan(String relativePathFromRepo) {
  if (repoLintPathIsExcludedTestOrGeneratedDart(relativePathFromRepo)) {
    return false;
  }
  if (!relativePathFromRepo.contains('/lib/')) {
    return false;
  }
  return true;
}

/// All domain `lib/**/*.dart` files under [repoLintDomainScanRoots], excluding
/// tests and generated files (same behavior as the pre–Phase 2 checkers).
List<File> collectRepoLintDomainDartFiles(String repoRoot) {
  final files = <File>[];
  for (final domainRoot in repoLintDomainScanRoots) {
    final base = Directory(p.join(repoRoot, domainRoot));
    if (!base.existsSync()) {
      continue;
    }
    for (final entity in base.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final rel = p.relative(entity.path, from: repoRoot);
      if (!repoLintPathIsDomainLibSourceForScan(rel)) {
        continue;
      }
      files.add(entity);
    }
  }
  return files;
}
