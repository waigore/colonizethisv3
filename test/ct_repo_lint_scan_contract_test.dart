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

  group('repoLintPathIsUnderLiteralScanRoots', () {
    test('matches top-level scan roots only', () {
      expect(
        repoLintPathIsUnderLiteralScanRoots(
          'packages/foo/lib/a.dart',
          repoLintIdentifierLiteralScanRoots,
        ),
        isTrue,
      );
      expect(
        repoLintPathIsUnderLiteralScanRoots(
          'ctdev/lib/x.dart',
          repoLintIdentifierLiteralScanRoots,
        ),
        isFalse,
      );
    });
  });

  group('repoLintIdentifierLiteralShouldSkipFile', () {
    test('requires lib, honors excludes and fixture dirs', () {
      const excluded = <String>{'packages/x/lib/skip.dart'};
      expect(
        repoLintIdentifierLiteralShouldSkipFile('app/lib/a.dart', excluded),
        isFalse,
      );
      expect(
        repoLintIdentifierLiteralShouldSkipFile('app/bin/a.dart', excluded),
        isTrue,
      );
      expect(
        repoLintIdentifierLiteralShouldSkipFile(
          'packages/x/lib/skip.dart',
          excluded,
        ),
        isTrue,
      );
      expect(
        repoLintIdentifierLiteralShouldSkipFile(
          'packages/p/lib/goldens/foo.dart',
          excluded,
        ),
        isTrue,
      );
      expect(
        repoLintIdentifierLiteralShouldSkipFile(
          'packages/p/lib/x.gen.dart',
          excluded,
        ),
        isTrue,
      );
    });
  });

  group('collectRepoLintDartFilesUnderRelativeRoots', () {
    test('collects dart files under given roots', () {
      final tmp = Directory.systemTemp.createTempSync('ct_repo_lit_roots_');
      addTearDown(() {
        if (tmp.existsSync()) {
          tmp.deleteSync(recursive: true);
        }
      });
      final repo = tmp.path;
      File(
        p.join(repo, 'packages', 'q', 'lib', 'a.dart'),
      ).createSync(recursive: true);
      File(
        p.join(repo, 'tool', 't', 'lib', 'b.dart'),
      ).createSync(recursive: true);

      final got = collectRepoLintDartFilesUnderRelativeRoots(repo, const [
        'packages',
        'tool',
      ]);
      final rels = got.map((f) => p.relative(f.path, from: repo)).toSet();
      expect(
        rels,
        containsAll(<String>[
          p.join('packages', 'q', 'lib', 'a.dart'),
          p.join('tool', 't', 'lib', 'b.dart'),
        ]),
      );
    });
  });
}
