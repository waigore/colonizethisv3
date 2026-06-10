// Forbids barrel-bypassing deep `src/` imports between split domain packages
// where the target package's public barrel already publishes the imported file
// (Refs #3393 Phase 1). Consumers should import a sibling domain package through
// its public barrel (`package:colonizethis_<target>/colonizethis_<target>.dart`)
// whenever that barrel re-exports the needed file; deep `src/` imports are
// reserved for files the barrel does not publish yet.
//
// Granularity is per-file: a deep import `package:colonizethis_<target>/src/<f>`
// is a violation when `<f>` is reachable from the target barrel's transitive
// `export` closure. Files the barrel omits entirely (e.g. world's
// `game_world_mutations.dart`) are not flagged, so consumers can keep importing
// them deeply until a later phase publishes them.
//
// The gate is scoped to the consumer -> target boundaries that have already been
// migrated. New boundaries are added to [_enforcedConsumerTargets] as later
// Phase 1 slices land. Only `import` directives are checked; deliberate narrow
// `export` re-exports of a single internal file are out of scope.
//
// Combinator-aware publication: a barrel `export` carrying a `show`/`hide`
// combinator only publishes a subset of its target file's symbols, so the file
// is treated as **not** fully published and deep imports of it remain allowed
// (a consumer may legitimately need a symbol the barrel withholds). For example
// `colonizethis_world` re-exports `fog_resolution.dart` with a `show` of only
// the coastal-visibility helpers, so `colonizethis_turn` keeps a deep import for
// the internal fog-decay helpers. Only combinator-free (full) re-exports count
// toward the published closure.
import 'dart:io';

import 'package:path/path.dart' as p;

/// Consumer domain package -> set of target domain packages whose barrel-bypass
/// deep imports are forbidden. Extended per migrated boundary (Refs #3393).
const Map<String, Set<String>> _enforcedConsumerTargets = {
  'turn': {'economy', 'diplomacy', 'world'},
};

final RegExp _deepImport = RegExp(
  r"^\s*import\s+'package:colonizethis_([a-z_]+)/(src/[^']+)'",
  multiLine: true,
);

final RegExp _exportDirective = RegExp(
  r"^\s*export\s+'([^']+)'([^;]*);",
  multiLine: true,
);

final RegExp _exportCombinator = RegExp(r'\b(show|hide)\b');

/// True when an `export` directive's trailing text carries a `show`/`hide`
/// combinator, meaning it only re-exports a subset of the target file.
bool _hasExportCombinator(String exportTail) =>
    _exportCombinator.hasMatch(exportTail);

bool _isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.mocks.dart');

/// Resolves an `export`/`import` URI seen inside [fromLibRelative] (a path
/// relative to the package `lib/` dir) to a `lib/`-relative path within the same
/// [target] package, or `null` when the URI points outside the package.
String? _resolveSamePackageUri(
  String target,
  String fromLibRelative,
  String uri,
) {
  const packagePrefix = 'package:colonizethis_';
  if (uri.startsWith('dart:')) return null;
  if (uri.startsWith(packagePrefix)) {
    final selfPrefix = 'package:colonizethis_$target/';
    if (!uri.startsWith(selfPrefix)) return null;
    return p.normalize(uri.substring(selfPrefix.length));
  }
  if (uri.startsWith('package:')) return null;
  return p.normalize(p.join(p.dirname(fromLibRelative), uri));
}

/// Computes the set of `lib/`-relative `src/...` files published (transitively)
/// by the [target] domain package's public barrel.
Set<String> barrelPublishedSrcFiles(String repoRoot, String target) {
  final libDir = Directory(
    p.join(repoRoot, 'packages', 'colonizethis_$target', 'lib'),
  );
  final published = <String>{};
  if (!libDir.existsSync()) return published;

  final barrelRelative = 'colonizethis_$target.dart';
  final visited = <String>{};
  final worklist = <String>[barrelRelative];

  while (worklist.isNotEmpty) {
    final current = worklist.removeLast();
    if (!visited.add(current)) continue;
    final file = File(p.join(libDir.path, current));
    if (!file.existsSync()) continue;
    final content = file.readAsStringSync();
    for (final match in _exportDirective.allMatches(content)) {
      final resolved = _resolveSamePackageUri(target, current, match.group(1)!);
      if (resolved == null) continue;
      // A `show`/`hide` re-export publishes only a subset of the file; treat it
      // as not fully published so deep imports of it remain allowed.
      if (_hasExportCombinator(match.group(2)!)) continue;
      if (resolved.startsWith('src/')) published.add(resolved);
      worklist.add(resolved);
    }
  }
  return published;
}

void main() {
  exit(runCheckDomainPackageBarrelImport(Directory.current.path));
}

int runCheckDomainPackageBarrelImport(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final consumer in _enforcedConsumerTargets.keys) {
    final targets = _enforcedConsumerTargets[consumer]!;
    final libDir = Directory(
      p.join(repoRoot, 'packages', 'colonizethis_$consumer', 'lib'),
    );
    if (!libDir.existsSync()) {
      logE('check_domain_package_barrel_import: missing ${libDir.path}');
      return 1;
    }

    final closures = <String, Set<String>>{
      for (final target in targets)
        target: barrelPublishedSrcFiles(repoRoot, target),
    };

    for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (_isGenerated(entity.path)) continue;
      final relative = p.relative(entity.path, from: repoRoot);
      for (final match in _deepImport.allMatches(entity.readAsStringSync())) {
        final target = match.group(1)!;
        if (!targets.contains(target)) continue;
        final srcPath = p.normalize(match.group(2)!);
        if (!closures[target]!.contains(srcPath)) continue;
        violations.add(
          '$relative imports package:colonizethis_$target/$srcPath '
          'which colonizethis_$target already publishes via its barrel; '
          "use import 'package:colonizethis_$target/colonizethis_$target.dart'",
        );
      }
    }
  }

  if (violations.isEmpty) {
    final pairs = _enforcedConsumerTargets.entries
        .map((e) => '${e.key} -> {${e.value.join(', ')}}')
        .join('; ');
    logI(
      'check_domain_package_barrel_import: no barrel-bypassing deep imports on '
      'enforced boundaries ($pairs).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_domain_package_barrel_import: deep src/ imports bypass an existing '
    'barrel export:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

/// Exposes the enforced consumer -> target boundaries for tests.
Map<String, Set<String>> enforcedConsumerTargetsForTests() => {
  for (final entry in _enforcedConsumerTargets.entries)
    entry.key: {...entry.value},
};
