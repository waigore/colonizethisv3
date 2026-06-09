// Enforces the one-way dependency DAG between the post-split colonizethis
// domain packages (Refs #3290). Before the split, the cross-domain import DAG
// was guarded inside the monolith by `repo.logic_domain_import_dag`, which
// scanned `packages/colonizethis_logic/lib/src/<domain>/`. After extraction
// those domain folders live in their own packages, so that gate no longer sees
// any cross-domain edge. This gate re-establishes the strict DAG at the package
// boundary: each domain package's `lib/` may only import (or export) the domain
// packages in its canonical downstream set. Any other domain-package import is a
// wrong-direction (or bidirectional) edge and fails.
import 'dart:io';

import 'package:path/path.dart' as p;

/// Canonical one-way dependency DAG between the split domain packages.
///
/// Keys are the domain package short names; values are the set of domain
/// packages each is allowed to depend on in `lib/`. The map mirrors the
/// production `dependencies` declared in each package's `pubspec.yaml` and the
/// target DAG in `SPEC/program/logic-package-split-phase0.md`. Leaf peers
/// (`combat` / `economy`) intentionally have no mutual edge.
const Map<String, Set<String>> _domainDag = {
  'world': {},
  'combat': {'world'},
  'economy': {'world'},
  'diplomacy': {'world', 'combat', 'economy'},
  'setup': {'world', 'diplomacy'},
  'orders': {'world', 'diplomacy', 'economy'},
  'turn': {'world', 'combat', 'economy', 'diplomacy', 'orders'},
  'ai_contracts': {'world', 'orders'},
};

final RegExp _domainImport = RegExp(
  r"(?:import|export)\s+'package:colonizethis_([a-z_]+)/",
);

bool _isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.mocks.dart');

void main() {
  exit(runCheckDomainPackageImportDag(Directory.current.path));
}

int runCheckDomainPackageImportDag(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final domainNames = _domainDag.keys.toSet();

  final violations = <String>[];
  for (final domain in _domainDag.keys) {
    final allowed = _domainDag[domain]!;
    final libDir = Directory(
      p.join(repoRoot, 'packages', 'colonizethis_$domain', 'lib'),
    );
    if (!libDir.existsSync()) {
      logE('check_domain_package_import_dag: missing ${libDir.path}');
      return 1;
    }

    for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (_isGenerated(entity.path)) continue;
      final relative = p.relative(entity.path, from: repoRoot);
      for (final match in _domainImport.allMatches(entity.readAsStringSync())) {
        final imported = match.group(1)!;
        if (!domainNames.contains(imported)) continue;
        if (imported == domain) continue;
        if (allowed.contains(imported)) continue;
        violations.add(
          '$relative imports package:colonizethis_$imported '
          '(colonizethis_$domain may only depend on '
          '${allowed.isEmpty ? '<none>' : allowed.map((d) => 'colonizethis_$d').join(', ')})',
        );
      }
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_domain_package_import_dag: ${_domainDag.length} domain packages '
      'respect the one-way dependency DAG.',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_domain_package_import_dag: wrong-direction domain-package imports '
    'break the one-way DAG:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

/// Exposes the canonical DAG for tests (acyclicity + pubspec consistency).
Map<String, Set<String>> domainPackageDagForTests() => {
  for (final entry in _domainDag.entries) entry.key: {...entry.value},
};
