import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_domain_package_dead_files.dart';

void _makeDomainSrcDirs(String root, {Iterable<String>? only}) {
  final domains = only ?? domainPackageDeadFilesDomainsForTests;
  for (final domain in domains) {
    Directory(p.join(root, 'packages', 'colonizethis_$domain', 'lib', 'src'))
        .createSync(recursive: true);
  }
}

void main() {
  test('passes on real repo workspace', () {
    final repoRoot = Directory.current.path;
    final logs = <String>[];
    final code = runCheckDomainPackageDeadFiles(
      repoRoot,
      info: logs.add,
      err: logs.add,
    );
    expect(code, 0, reason: logs.join('\n'));
    expect(
      logs.join('\n'),
      contains('Domain-package dead-file check passed'),
    );
  });

  test('audits the eight extracted domain packages', () {
    expect(
      domainPackageDeadFilesDomainsForTests,
      containsAll(<String>[
        'world',
        'combat',
        'economy',
        'diplomacy',
        'setup',
        'orders',
        'turn',
        'ai_contracts',
      ]),
    );
    expect(domainPackageDeadFilesDomainsForTests.length, 8);
  });

  test('fails when a domain src file is unreachable from any consumer', () {
    final temp =
        Directory.systemTemp.createTempSync('domain_dead_files_fail_');
    addTearDown(() => temp.deleteSync(recursive: true));

    _makeDomainSrcDirs(temp.path);

    final worldSrc = Directory(
      p.join(temp.path, 'packages/colonizethis_world/lib/src/world'),
    )..createSync(recursive: true);
    File(p.join(worldSrc.path, 'used.dart'))
        .writeAsStringSync('class Used {}\n');
    File(p.join(worldSrc.path, 'orphan.dart'))
        .writeAsStringSync('class Orphan {}\n');

    // An anchor consumer outside the domain src trees references `used.dart`
    // (directly via the package src path) but never `orphan.dart`.
    final appLib = Directory(p.join(temp.path, 'app/lib'))
      ..createSync(recursive: true);
    File(p.join(appLib.path, 'anchor.dart')).writeAsStringSync(
      "import 'package:colonizethis_world/src/world/used.dart';\n"
      'void useIt() => Used();\n',
    );

    final err = <String>[];
    final code = runCheckDomainPackageDeadFiles(
      temp.path,
      info: (_) {},
      err: err.add,
    );

    expect(code, 1);
    expect(err.join('\n'), contains('orphan.dart'));
    expect(err.join('\n'), isNot(contains('used.dart')));
  });

  test('keeps a domain file reachable through a cross-package re-export', () {
    final temp =
        Directory.systemTemp.createTempSync('domain_dead_files_reexport_');
    addTearDown(() => temp.deleteSync(recursive: true));

    _makeDomainSrcDirs(temp.path);

    // world src file consumed only via a re-export from another package's lib.
    final worldSrc = Directory(
      p.join(temp.path, 'packages/colonizethis_world/lib/src/world'),
    )..createSync(recursive: true);
    File(p.join(worldSrc.path, 'naval.dart'))
        .writeAsStringSync('class Naval {}\n');

    // turn (a non-domain-src anchor file) re-exports the world src file.
    final turnLib = Directory(p.join(temp.path, 'packages/colonizethis_turn/lib'))
      ..createSync(recursive: true);
    File(p.join(turnLib.path, 'colonizethis_turn.dart')).writeAsStringSync(
      "export 'package:colonizethis_world/src/world/naval.dart';\n",
    );

    final logs = <String>[];
    final code = runCheckDomainPackageDeadFiles(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 0, reason: logs.join('\n'));
  });

  test('fails when a domain src tree is missing', () {
    final temp =
        Directory.systemTemp.createTempSync('domain_dead_files_missing_');
    addTearDown(() => temp.deleteSync(recursive: true));

    // Only create a subset of the required domain src trees.
    _makeDomainSrcDirs(temp.path, only: const ['world', 'combat']);

    final err = <String>[];
    final code = runCheckDomainPackageDeadFiles(
      temp.path,
      info: (_) {},
      err: err.add,
    );

    expect(code, 1);
    expect(err.join('\n'), contains('Missing domain src tree'));
  });
}
