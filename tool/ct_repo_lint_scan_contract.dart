import 'dart:io';

import 'package:path/path.dart' as p;

/// Path fragments that mark fixture / golden trees excluded from scans.
const List<String> repoLintFixtureDirPathMarkers = <String>[
  '/test_data/',
  '/testdata/',
  '/fixtures/',
  '/fixture/',
  '/golden/',
  '/goldens/',
];

bool _repoLintSlashPathContainsFixtureMarker(String slashPath) {
  final withLeading = slashPath.startsWith('/') ? slashPath : '/$slashPath';
  for (final marker in repoLintFixtureDirPathMarkers) {
    if (withLeading.contains(marker)) {
      return true;
    }
  }
  return false;
}

/// True for repo-root `test/**` (tooling / checker tests), not package `test/`.
bool repoLintPathIsUnderRepoRootToolingTestTree(String relativePathFromRepo) {
  final slash = relativePathFromRepo.replaceAll('\\', '/');
  return slash == 'test' || slash.startsWith('test/');
}

/// Non-`.dart` or known generated Dart suffixes (always excluded from domain scans).
bool repoLintPathIsExcludedGeneratedDart(String relativePathFromRepo) {
  if (!relativePathFromRepo.endsWith('.dart')) {
    return true;
  }
  if (relativePathFromRepo.endsWith('.g.dart') ||
      relativePathFromRepo.endsWith('.freezed.dart') ||
      relativePathFromRepo.endsWith('.mocks.dart') ||
      relativePathFromRepo.endsWith('.gen.dart')) {
    return true;
  }
  return false;
}

/// True when [relativePathFromRepo] should not be scanned (historical helper:
/// package `test/`, loose `*_test.dart`, generated, non-`.dart`).
///
/// Domain collectors use [repoLintPathIsDomainLibSourceForScan] and
/// [repoLintPathIsDomainTestOrIntegrationTestSourceForScan] instead. AST
/// checkers that analyze package tests use [repoLintPathShouldSkipAstRuleFile].
bool repoLintPathIsExcludedTestOrGeneratedDart(String relativePathFromRepo) {
  if (repoLintPathIsExcludedGeneratedDart(relativePathFromRepo)) {
    return true;
  }
  final slash = relativePathFromRepo.replaceAll('\\', '/');
  if (slash.contains('/test/') || slash.contains('/integration_test/')) {
    return true;
  }
  if (slash.endsWith('_test.dart')) {
    return true;
  }
  return false;
}

/// Skip only generated, repo-root checker `test/`, and fixture trees — not
/// package `test/` / `integration_test/` (GitHub #2014).
bool repoLintPathShouldSkipAstRuleFile(String relativePathFromRepo) {
  if (repoLintPathIsExcludedGeneratedDart(relativePathFromRepo)) {
    return true;
  }
  final slash = relativePathFromRepo.replaceAll('\\', '/');
  if (repoLintPathIsUnderRepoRootToolingTestTree(slash)) {
    return true;
  }
  if (_repoLintSlashPathContainsFixtureMarker(slash)) {
    return true;
  }
  return false;
}

/// True when [relativePathFromRepo] is `lib/**/*.dart` under a domain package
/// (not generated; not repo-root `test/`).
bool repoLintPathIsDomainLibSourceForScan(String relativePathFromRepo) {
  if (repoLintPathIsExcludedGeneratedDart(relativePathFromRepo)) {
    return false;
  }
  final slash = relativePathFromRepo.replaceAll('\\', '/');
  if (repoLintPathIsUnderRepoRootToolingTestTree(slash)) {
    return false;
  }
  if (!slash.contains('/lib/')) {
    return false;
  }
  if (_repoLintSlashPathContainsFixtureMarker(slash)) {
    return false;
  }
  return true;
}

/// Package/app/ctdev/tool `test/**` or `integration_test/**` Dart (GitHub #2014),
/// excluding generated, repo-root checker tests, and fixture trees.
bool repoLintPathIsDomainTestOrIntegrationTestSourceForScan(
  String relativePathFromRepo,
) {
  if (repoLintPathIsExcludedGeneratedDart(relativePathFromRepo)) {
    return false;
  }
  final slash = relativePathFromRepo.replaceAll('\\', '/');
  if (repoLintPathIsUnderRepoRootToolingTestTree(slash)) {
    return false;
  }
  final inDomain =
      slash.startsWith('packages/') ||
      slash.startsWith('app/') ||
      slash.startsWith('ctdev/') ||
      slash.startsWith('tool/');
  if (!inDomain) {
    return false;
  }
  if (!slash.contains('/test/') && !slash.contains('/integration_test/')) {
    return false;
  }
  if (_repoLintSlashPathContainsFixtureMarker(slash)) {
    return false;
  }
  return true;
}

void _collectDomainDartFilesUnder(
  String repoRoot,
  Directory base,
  List<File> out,
) {
  if (!base.existsSync()) {
    return;
  }
  for (final entity in base.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    final rel = p.relative(entity.path, from: repoRoot);
    if (repoLintPathIsDomainLibSourceForScan(rel) ||
        repoLintPathIsDomainTestOrIntegrationTestSourceForScan(rel)) {
      out.add(entity);
    }
  }
}

void _collectPackagesDomainDartFiles(String repoRoot, List<File> out) {
  final packagesDir = Directory(p.join(repoRoot, 'packages'));
  if (!packagesDir.existsSync()) {
    return;
  }
  for (final entity in packagesDir.listSync(followLinks: false)) {
    if (entity is! Directory) {
      continue;
    }
    for (final sub in const ['lib', 'test', 'integration_test']) {
      _collectDomainDartFilesUnder(
        repoRoot,
        Directory(p.join(entity.path, sub)),
        out,
      );
    }
  }
}

void _collectToolDomainDartFiles(String repoRoot, List<File> out) {
  final toolRoot = Directory(p.join(repoRoot, 'tool'));
  if (!toolRoot.existsSync()) {
    return;
  }
  for (final entity in toolRoot.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final rel = p.relative(entity.path, from: repoRoot);
    if (repoLintPathIsDomainLibSourceForScan(rel) ||
        repoLintPathIsDomainTestOrIntegrationTestSourceForScan(rel)) {
      out.add(entity);
    }
  }
}

/// Domain `lib/`, `test/`, and `integration_test/` Dart under workspace packages,
/// `app/`, `ctdev/`, and `tool/` (see predicates), excluding generated and
/// fixture trees per SPEC/program/repo-lint.md (#2014).
List<File> collectRepoLintDomainDartFiles(String repoRoot) {
  final files = <File>[];
  _collectPackagesDomainDartFiles(repoRoot, files);
  for (final sub in const ['lib', 'test', 'integration_test']) {
    _collectDomainDartFilesUnder(
      repoRoot,
      Directory(p.join(repoRoot, 'app', sub)),
      files,
    );
  }
  for (final sub in const ['lib', 'test']) {
    _collectDomainDartFilesUnder(
      repoRoot,
      Directory(p.join(repoRoot, 'ctdev', sub)),
      files,
    );
  }
  _collectToolDomainDartFiles(repoRoot, files);
  return files;
}

/// Shared repo-wide Dart collector used by checks that intentionally scan beyond
/// domain-only `lib/`/`test/`/`integration_test/` trees.
///
/// Excludes generated Dart suffixes, fixture trees, and hidden/tool-cache/build
/// directories while preserving broad coverage semantics for legacy whole-repo
/// checks (for example `check_long_string_switches`).
bool repoLintRepoWideDartCollectorShouldSkip(String relativePathFromRepo) {
  final slash = relativePathFromRepo.replaceAll('\\', '/');
  if (!slash.endsWith('.dart')) {
    return true;
  }
  if (slash.endsWith('.g.dart') ||
      slash.endsWith('.freezed.dart') ||
      slash.endsWith('.mocks.dart') ||
      slash.endsWith('tech_effect_summary_embed.dart')) {
    return true;
  }
  if (_repoLintSlashPathContainsFixtureMarker(slash)) {
    return true;
  }
  if (slash.split('/').contains('.dart_tool') ||
      slash.split('/').contains('.pub-cache') ||
      slash.split('/').contains('build')) {
    return true;
  }
  return false;
}

List<File> collectRepoLintRepoWideDartFiles(String repoRoot) {
  final root = Directory(repoRoot);
  if (!root.existsSync()) {
    return <File>[];
  }
  final out = <File>[];
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    final rel = p.relative(entity.path, from: repoRoot);
    if (repoLintRepoWideDartCollectorShouldSkip(rel)) {
      continue;
    }
    out.add(entity);
  }
  return out;
}

/// Splits comma/newline-separated repo-relative paths (same as `check_* --files`).
List<String> repoLintSplitRelativeDartPathsArg(String value) {
  if (value.trim().isEmpty) {
    return const [];
  }
  final normalized = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  return normalized
      .split(RegExp('[,\n]'))
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

/// Parses `--files=` / `--files <csv>` from a checker `main(argv)` list.
///
/// When a bare `--files` has no following argument, [missingValueError] is true
/// and callers should print a tool-specific prefix then exit `2`.
({List<String>? paths, bool missingValueError})
repoLintParseIncrementalRelativeDartPathsFromArgs(List<String> args) {
  List<String>? out;
  var missingValue = false;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--files=')) {
      out = repoLintSplitRelativeDartPathsArg(arg.substring('--files='.length));
    } else if (arg == '--files') {
      if (i + 1 >= args.length) {
        missingValue = true;
      } else {
        i++;
        out = repoLintSplitRelativeDartPathsArg(args[i]);
      }
    }
  }
  return (paths: out, missingValueError: missingValue);
}

/// Like [repoLintParseIncrementalRelativeDartPathsFromArgs], but rejects any
/// token that is not `--files`, `--files=…`, or the single value token after a
/// bare `--files` (for checkers that accept only incremental file lists).
///
/// [unsupportedArgument] is the first argv token that violates that contract.
({List<String>? paths, bool missingValueError, String? unsupportedArgument})
repoLintParseStrictIncrementalFilesArgs(List<String> args) {
  List<String>? out;
  var missingValue = false;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--files=')) {
      out = repoLintSplitRelativeDartPathsArg(arg.substring('--files='.length));
      continue;
    }
    if (arg == '--files') {
      if (i + 1 >= args.length) {
        missingValue = true;
      } else {
        i++;
        out = repoLintSplitRelativeDartPathsArg(args[i]);
      }
      continue;
    }
    return (
      paths: out,
      missingValueError: missingValue,
      unsupportedArgument: arg,
    );
  }
  return (
    paths: out,
    missingValueError: missingValue,
    unsupportedArgument: null,
  );
}

/// Same as [repoLintParseStrictIncrementalFilesArgs], but prints the shared
/// `ERROR:` stderr lines and **exits 2** on missing `--files` value or unknown
/// argv tokens (identifier-literal and dart file-size checkers).
List<String> repoLintStrictIncrementalFilesArgListOrExit(List<String> args) {
  final r = repoLintParseStrictIncrementalFilesArgs(args);
  if (r.missingValueError) {
    stderr.writeln('ERROR: Missing value for --files.');
    exit(2);
  }
  if (r.unsupportedArgument != null) {
    stderr.writeln(
      'ERROR: Unsupported argument "${r.unsupportedArgument}". Supported: --files '
      '(comma-separated or newline-separated relative paths).',
    );
    exit(2);
  }
  return r.paths ?? const [];
}

// --- Identifier-literal checkers (tech / work-target / civilian unit type) ---

/// Scan roots for tech / work-target / civilian literal checkers (top-level
/// `app`, `packages`, `tool`, and `ctdev` — aligned with #2014 domain coverage).
const List<String> repoLintIdentifierLiteralScanRoots = <String>[
  'app',
  'packages',
  'ctdev',
  'tool',
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

bool _repoLintPathHasLibTestOrIntegrationSegment(String slashPath) {
  return slashPath.contains('/lib/') ||
      slashPath.contains('/test/') ||
      slashPath.contains('/integration_test/');
}

/// Shared skip logic for identifier literal checkers: domain `lib/`, `test/`,
/// or `integration_test/` under scan roots; not generated; not repo-root
/// tooling tests; not [excludedPaths]; not fixture dirs.
bool repoLintIdentifierLiteralShouldSkipFile(
  String relativePathFromRepo,
  Set<String> excludedPaths,
) {
  if (excludedPaths.contains(relativePathFromRepo)) {
    return true;
  }
  final slash = relativePathFromRepo.replaceAll('\\', '/');
  if (repoLintPathIsUnderRepoRootToolingTestTree(slash)) {
    return true;
  }
  if (!_repoLintPathHasLibTestOrIntegrationSegment(slash)) {
    return true;
  }
  if (relativePathFromRepo.endsWith('.g.dart') ||
      relativePathFromRepo.endsWith('.freezed.dart') ||
      relativePathFromRepo.endsWith('.mocks.dart') ||
      relativePathFromRepo.endsWith('.gen.dart')) {
    return true;
  }
  // `flutter gen-l10n` output per app/l10n.yaml under `lib/l10n/gen/`
  // (`app_l10n_flutter_gen*.dart`, gitignored). ARB-derived strings may echo
  // canonical work-target ids; do not subject generated l10n to identifier-literal domain gates.
  if (slash.startsWith('app/lib/l10n/gen/app_l10n_flutter_gen')) {
    return true;
  }
  if (_repoLintSlashPathContainsFixtureMarker(slash)) {
    return true;
  }
  return false;
}

// --- Canonical province tile-key checker ---

/// Repo-root `test/**` or any `.../test/...` segment (normalized path).
bool repoLintPathIsUnderPackageOrRootTestTree(String relativePathFromRepo) {
  final norm = p.normalize(relativePathFromRepo);
  if (norm.startsWith('test${p.separator}')) {
    return true;
  }
  if (norm.contains('${p.separator}test${p.separator}')) {
    return true;
  }
  return false;
}

bool repoLintPathEndsWithKnownGeneratedDartSuffix(String relativePathFromRepo) {
  return relativePathFromRepo.endsWith('.g.dart') ||
      relativePathFromRepo.endsWith('.freezed.dart') ||
      relativePathFromRepo.endsWith('.mocks.dart') ||
      relativePathFromRepo.endsWith('.gen.dart');
}

bool repoLintCanonicalProvinceTileKeyShouldSkipFile(
  String relativePathFromRepo,
  Set<String> excludedPaths,
) {
  if (excludedPaths.contains(relativePathFromRepo)) {
    return true;
  }
  final slash = relativePathFromRepo.replaceAll('\\', '/');
  if (repoLintPathIsUnderRepoRootToolingTestTree(slash)) {
    return true;
  }
  if (repoLintPathEndsWithKnownGeneratedDartSuffix(relativePathFromRepo)) {
    return true;
  }
  if (!_repoLintPathHasLibTestOrIntegrationSegment(slash)) {
    return true;
  }
  if (_repoLintSlashPathContainsFixtureMarker(slash)) {
    return true;
  }
  return false;
}

/// Candidate `.dart` files for the canonical province `targetTileKey` gate
/// (same roots as identifier-literal checkers; skips repo-root tooling tests,
/// generated Dart, checker-local [excludedPaths], and fixture dirs).
List<File> collectRepoLintCanonicalProvinceTileKeyDartFiles(
  String repoRoot,
  Set<String> excludedPaths,
) {
  final candidates = collectRepoLintDartFilesUnderRelativeRoots(
    repoRoot,
    repoLintIdentifierLiteralScanRoots,
  );
  final out = <File>[];
  for (final f in candidates) {
    final rel = p.normalize(p.relative(f.path, from: repoRoot));
    if (!repoLintCanonicalProvinceTileKeyShouldSkipFile(rel, excludedPaths)) {
      out.add(f);
    }
  }
  return out;
}

// --- App `lib/` hardcoded UI string checker ---

/// All `app/lib/**/*.dart` files, sorted by path (historical checker order).
List<File> collectRepoLintAppLibDartFilesSorted(String repoRoot) {
  final base = Directory(p.join(repoRoot, 'app', 'lib'));
  if (!base.existsSync()) {
    return <File>[];
  }
  final files = <File>[];
  for (final entity in base.listSync(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      files.add(entity);
    }
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

/// Skip predicate for [findHardcodedUiViolations] after `app/lib` prefix checks.
bool repoLintAppLibHardcodedUiVisitorShouldSkip(String relativePathFromRepo) {
  if (!relativePathFromRepo.endsWith('.dart')) {
    return true;
  }
  if (relativePathFromRepo.contains('/test/') ||
      relativePathFromRepo.endsWith('_test.dart')) {
    return true;
  }
  if (relativePathFromRepo.endsWith('.g.dart') ||
      relativePathFromRepo.endsWith('.freezed.dart') ||
      relativePathFromRepo.endsWith('.mocks.dart') ||
      relativePathFromRepo.endsWith('.gen.dart')) {
    return true;
  }
  return false;
}
