// Enforces one-way domain import boundaries inside colonizethis_logic (Refs #3290 Phase 0).
import 'dart:io';

import 'package:path/path.dart' as p;

const _logicSrcRelative = 'packages/colonizethis_logic/lib/src';

/// Domain directories under `lib/src/` tracked for cross-import DAG rules.
const _domains = <String>{
  'ai',
  'combat',
  'debug_console',
  'di',
  'diplomacy',
  'dossier',
  'economy',
  'event_bus',
  'orders',
  'setup',
  'turn',
  'utils',
  'world',
};

/// Shared modules that may be imported from any domain without counting as a
/// cross-domain edge (hoisted prerequisites for package split).
const _neutralTopLevelDirs = <String>{'trace', 'validation'};

const _neutralTopLevelFiles = <String>{
  'turn_resolution_seeds.dart',
  'constants.dart',
  'game_events.dart',
  'logic_validation_exception.dart',
};

/// Forbidden (fromDomain, toDomain) pairs for the target package DAG.
///
/// `world` is the leaf layer: `combat`, `economy`, and `diplomacy` (which the
/// `dossier` directory folds into) all sit above it, so `world` must not import
/// any of them. `dossier` is tracked as a distinct forbidden target because it
/// is a separate `lib/src` directory today even though it merges into the
/// `colonizethis_diplomacy` package at extraction time (Refs #3290).
const _forbiddenEdges = <(String, String)>{
  ('world', 'turn'),
  ('world', 'setup'),
  ('world', 'diplomacy'),
  ('world', 'combat'),
  ('world', 'dossier'),
  ('combat', 'diplomacy'),
  ('economy', 'orders'),
  ('orders', 'turn'),
  ('ai', 'diplomacy'),
};

/// Grandfathered violations documented in SPEC/program/logic-package-split-phase0.md
/// until the matching C0 follow-up lands. Format: `fromDomain->toDomain:relative/import/path`.
const _grandfatherAllowlist = <String>{
  'economy->orders:economy/world_market/trade_order_validator.dart',
  'orders->turn:orders/order_projections.dart',
};

void main() {
  exit(runCheckLogicDomainImportDag(Directory.current.path));
}

int runCheckLogicDomainImportDag(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final srcDir = Directory(p.join(repoRoot, _logicSrcRelative));
  if (!srcDir.existsSync()) {
    logE('check_logic_domain_import_dag: missing $_logicSrcRelative');
    return 1;
  }

  final violations = <String>[];
  for (final entity in srcDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final relativeFile = p.relative(entity.path, from: srcDir.path);
    final fromDomain = _domainForSrcRelativePath(relativeFile);
    if (fromDomain == null) continue;

    final content = entity.readAsStringSync();
    for (final match in _importPattern.allMatches(content)) {
      final importPath = match.group(1)!;
      final toDomain = _resolveImportTargetDomain(relativeFile, importPath);
      if (toDomain == null || toDomain == fromDomain) continue;
      if (!_forbiddenEdges.contains((fromDomain, toDomain))) continue;

      final violationKey =
          '$fromDomain->$toDomain:${p.normalize(relativeFile)}';
      if (_grandfatherAllowlist.contains(violationKey)) continue;

      violations.add(
        '$fromDomain -> $toDomain: packages/colonizethis_logic/lib/src/$relativeFile imports $importPath',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_logic_domain_import_dag: no violations outside allowlist.');
    return 0;
  }

  logE(
    'check_logic_domain_import_dag: found ${violations.length} forbidden import(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

final _importPattern = RegExp(r"import\s+'([^']+)';");

String? _domainForSrcRelativePath(String relativePath) {
  final segments = p.split(relativePath);
  if (segments.isEmpty) return null;
  final first = segments.first;
  if (_domains.contains(first)) return first;
  return null;
}

String? _resolveImportTargetDomain(String fromRelativeFile, String importPath) {
  if (importPath.startsWith('package:colonizethis_logic/src/')) {
    final remainder = importPath.substring(
      'package:colonizethis_logic/src/'.length,
    );
    return _domainFromResolvedPath(remainder);
  }
  if (!importPath.startsWith('../') && !importPath.startsWith('./')) {
    return null;
  }
  final fromDir = p.dirname(fromRelativeFile);
  final resolved = p.normalize(p.join(fromDir, importPath));
  return _domainFromResolvedPath(resolved);
}

String? _domainFromResolvedPath(String resolvedPath) {
  final segments = p.split(resolvedPath);
  if (segments.isEmpty) return null;
  final first = segments.first;
  if (_neutralTopLevelDirs.contains(first)) return null;
  if (segments.length == 1 && _neutralTopLevelFiles.contains(first)) {
    return null;
  }
  if (_domains.contains(first)) return first;
  return null;
}

/// Test helper: decode the embedded grandfather allowlist for assertions.
Set<String> logicDomainImportDagGrandfatherAllowlistForTests() =>
    Set<String>.from(_grandfatherAllowlist);

/// Test helper: list forbidden edges as JSON-friendly strings.
List<String> logicDomainImportForbiddenEdgesForTests() =>
    _forbiddenEdges.map((e) => '${e.$1}->${e.$2}').toList(growable: false);
