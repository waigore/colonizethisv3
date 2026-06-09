import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_domain_package_import_dag.dart';

/// Reads the production (`dependencies:`) domain-package deps for a package,
/// excluding `dev_dependencies:` / `dependency_overrides:`.
Set<String> _productionDomainDeps(String repoRoot, String domain) {
  final pubspec = File(
    p.join(repoRoot, 'packages', 'colonizethis_$domain', 'pubspec.yaml'),
  ).readAsLinesSync();
  final domainNames = domainPackageDagForTests().keys.toSet();
  final deps = <String>{};
  var inDeps = false;
  for (final line in pubspec) {
    if (line.startsWith('dependencies:')) {
      inDeps = true;
      continue;
    }
    if (line.startsWith('dev_dependencies:') ||
        line.startsWith('dependency_overrides:')) {
      inDeps = false;
      continue;
    }
    if (!inDeps) continue;
    final match = RegExp(r'^  colonizethis_([a-z_]+):').firstMatch(line);
    if (match == null) continue;
    final name = match.group(1)!;
    if (domainNames.contains(name)) deps.add(name);
  }
  return deps;
}

void main() {
  test('canonical domain DAG is acyclic', () {
    final dag = domainPackageDagForTests();
    final visiting = <String>{};
    final done = <String>{};

    bool hasCycleFrom(String node) {
      if (done.contains(node)) return false;
      if (!visiting.add(node)) return true;
      for (final next in dag[node] ?? const <String>{}) {
        if (hasCycleFrom(next)) return true;
      }
      visiting.remove(node);
      done.add(node);
      return false;
    }

    for (final node in dag.keys) {
      expect(hasCycleFrom(node), isFalse, reason: 'cycle reachable from $node');
    }
  });

  test('canonical DAG only references known domain packages', () {
    final dag = domainPackageDagForTests();
    for (final entry in dag.entries) {
      for (final dep in entry.value) {
        expect(
          dag.containsKey(dep),
          isTrue,
          reason: '${entry.key} -> $dep references an unknown domain package',
        );
      }
    }
  });

  test('canonical DAG matches each package production dependencies', () {
    final repoRoot = Directory.current.path;
    final dag = domainPackageDagForTests();
    for (final entry in dag.entries) {
      expect(
        _productionDomainDeps(repoRoot, entry.key),
        equals(entry.value),
        reason:
            'colonizethis_${entry.key} pubspec dependencies drifted from the '
            'canonical DAG entry',
      );
    }
  });

  test('passes for the real post-split domain packages', () {
    final code = runCheckDomainPackageImportDag(
      Directory.current.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 0);
  });

  test('fails on a wrong-direction (leaf imports orchestrator) edge', () {
    final temp = Directory.systemTemp.createTempSync('domain_dag_wrong_');
    addTearDown(() => temp.deleteSync(recursive: true));

    for (final domain in domainPackageDagForTests().keys) {
      Directory(
        p.join(temp.path, 'packages', 'colonizethis_$domain', 'lib'),
      ).createSync(recursive: true);
    }
    // world is a leaf; importing turn is a forbidden back-edge.
    File(
      p.join(temp.path, 'packages', 'colonizethis_world', 'lib', 'leak.dart'),
    ).writeAsStringSync("import 'package:colonizethis_turn/x.dart';\n");

    final code = runCheckDomainPackageImportDag(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 1);
  });

  test('fails on a forbidden leaf-peer (economy imports combat) edge', () {
    final temp = Directory.systemTemp.createTempSync('domain_dag_peer_');
    addTearDown(() => temp.deleteSync(recursive: true));

    for (final domain in domainPackageDagForTests().keys) {
      Directory(
        p.join(temp.path, 'packages', 'colonizethis_$domain', 'lib'),
      ).createSync(recursive: true);
    }
    File(
      p.join(temp.path, 'packages', 'colonizethis_economy', 'lib', 'x.dart'),
    ).writeAsStringSync("import 'package:colonizethis_combat/y.dart';\n");

    final code = runCheckDomainPackageImportDag(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 1);
  });

  test('allows an in-DAG edge and ignores generated files', () {
    final temp = Directory.systemTemp.createTempSync('domain_dag_ok_');
    addTearDown(() => temp.deleteSync(recursive: true));

    for (final domain in domainPackageDagForTests().keys) {
      Directory(
        p.join(temp.path, 'packages', 'colonizethis_$domain', 'lib'),
      ).createSync(recursive: true);
    }
    // combat -> world is allowed.
    File(
      p.join(temp.path, 'packages', 'colonizethis_combat', 'lib', 'ok.dart'),
    ).writeAsStringSync("import 'package:colonizethis_world/w.dart';\n");
    // A generated file with a forbidden edge must be ignored.
    File(
      p.join(temp.path, 'packages', 'colonizethis_world', 'lib', 'g.g.dart'),
    ).writeAsStringSync("import 'package:colonizethis_turn/x.dart';\n");

    final code = runCheckDomainPackageImportDag(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 0);
  });

  test('fails when a domain package lib tree is missing', () {
    final temp = Directory.systemTemp.createTempSync('domain_dag_missing_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final code = runCheckDomainPackageImportDag(
      temp.path,
      info: (_) {},
      err: (_) {},
    );
    expect(code, 1);
  });
}
