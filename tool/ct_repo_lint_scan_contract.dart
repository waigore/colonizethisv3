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

// --- Identifier-literal checkers (tech / work-target / civilian unit type) ---

/// Scan roots for tech / work-target / civilian literal checkers (historical
/// layout: top-level `app`, `ctterm`, `packages`, `tool` — not `ctdev/lib`).
const List<String> repoLintIdentifierLiteralScanRoots = <String>[
  'app',
  'ctterm',
  'packages',
  'tool',
];

/// Path fragments that mark fixture / golden trees excluded from scans.
const List<String> repoLintFixtureDirPathMarkers = <String>[
  '/test_data/',
  '/testdata/',
  '/fixtures/',
  '/fixture/',
  '/golden/',
  '/goldens/',
];

/// True when [relativePathFromRepo] lies under one of [roots] (POSIX-style
/// segments after normalizing backslashes).
bool repoLintPathIsUnderLiteralScanRoots(
  String relativePathFromRepo,
  List<String> roots,
) {
  final normalized = relativePathFromRepo.replaceAll('\\', '/');
  for (final root in roots) {
    if (normalized == root || normalized.startsWith('$root/')) {
      return true;
    }
  }
  return false;
}

/// Collects every `.dart` file under [roots]; callers filter with
/// [repoLintIdentifierLiteralShouldSkipFile].
List<File> collectRepoLintDartFilesUnderRelativeRoots(
  String repoRoot,
  List<String> roots,
) {
  final files = <File>[];
  for (final relRoot in roots) {
    final absRoot = p.join(repoRoot, relRoot);
    final dir = Directory(absRoot);
    if (!dir.existsSync()) {
      continue;
    }
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        files.add(entity);
      }
    }
  }
  return files;
}

/// Shared skip logic for identifier literal checkers: must live under `lib/`,
/// not be generated, not match [excludedPaths], and not sit under fixture dirs.
bool repoLintIdentifierLiteralShouldSkipFile(
  String relativePathFromRepo,
  Set<String> excludedPaths,
) {
  final slashPath = '/${relativePathFromRepo.replaceAll('\\', '/')}';
  if (!slashPath.contains('/lib/')) {
    return true;
  }
  if (excludedPaths.contains(relativePathFromRepo)) {
    return true;
  }
  if (relativePathFromRepo.endsWith('.g.dart') ||
      relativePathFromRepo.endsWith('.freezed.dart') ||
      relativePathFromRepo.endsWith('.mocks.dart') ||
      relativePathFromRepo.endsWith('.gen.dart')) {
    return true;
  }
  for (final marker in repoLintFixtureDirPathMarkers) {
    if (slashPath.contains(marker)) {
      return true;
    }
  }
  return false;
}
