import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/ct_repo_lint_scan_contract.dart';

void main() {
  group('repoLintPathIsExcludedTestOrGeneratedDart', () {
    test('excludes tests and generated suffixes', () {
      expect(repoLintPathIsExcludedTestOrGeneratedDart('a.dart'), isFalse);
      expect(repoLintPathIsExcludedTestOrGeneratedDart('x_test.dart'), isTrue);
      expect(
        repoLintPathIsExcludedTestOrGeneratedDart('lib/foo_test.dart'),
        isTrue,
      );
      expect(
        repoLintPathIsExcludedTestOrGeneratedDart('packages/p/test/a.dart'),
        isTrue,
      );
      expect(repoLintPathIsExcludedTestOrGeneratedDart('lib/x.g.dart'), isTrue);
      expect(
        repoLintPathIsExcludedTestOrGeneratedDart('lib/x.freezed.dart'),
        isTrue,
      );
      expect(
        repoLintPathIsExcludedTestOrGeneratedDart('lib/x.mocks.dart'),
        isTrue,
      );
      expect(repoLintPathIsExcludedTestOrGeneratedDart('lib/x.txt'), isTrue);
    });
  });

  group('repoLintPathIsDomainLibSourceForScan', () {
    test('requires lib segment and allows normal sources', () {
      expect(
        repoLintPathIsDomainLibSourceForScan('packages/foo/lib/a.dart'),
        isTrue,
      );
      expect(
        repoLintPathIsDomainLibSourceForScan('tool/x/bin/run.dart'),
        isFalse,
      );
    });
  });

  group('collectRepoLintDomainDartFiles', () {
    test('walks roots and applies filters', () {
      final tmp = Directory.systemTemp.createTempSync('ct_repo_scan_');
      addTearDown(() {
        if (tmp.existsSync()) {
          tmp.deleteSync(recursive: true);
        }
      });

      final repo = tmp.path;
      final keep = File(p.join(repo, 'packages', 'z', 'lib', 'keep.dart'));
      keep.createSync(recursive: true);
      File(p.join(repo, 'packages', 'z', 'lib', 'keep.g.dart')).createSync();
      File(
        p.join(repo, 'packages', 'z', 'test', 't.dart'),
      ).createSync(recursive: true);
      File(
        p.join(repo, 'packages', 'z', 'lib', 'nested', 'x.dart'),
      ).createSync(recursive: true);

      final got = collectRepoLintDomainDartFiles(repo);
      final rels = got.map((f) => p.relative(f.path, from: repo)).toSet();
      expect(
        rels,
        containsAll(<String>[
          p.join('packages', 'z', 'lib', 'keep.dart'),
          p.join('packages', 'z', 'lib', 'nested', 'x.dart'),
        ]),
      );
      expect(
        rels,
        isNot(contains(p.join('packages', 'z', 'lib', 'keep.g.dart'))),
      );
      expect(rels, isNot(contains(p.join('packages', 'z', 'test', 't.dart'))));
    });
  });
}
