import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/ct_repo_lint_scan_contract.dart';

void main() {
  group('repoLintPathIsUnderRepoRootToolingTestTree', () {
    test('matches only repo-root test/', () {
      expect(
        repoLintPathIsUnderRepoRootToolingTestTree('test/foo.dart'),
        isTrue,
      );
      expect(
        repoLintPathIsUnderRepoRootToolingTestTree(
          p.join('packages', 'p', 'test', 'a.dart'),
        ),
        isFalse,
      );
    });
  });

  group('repoLintPathIsExcludedTestOrGeneratedDart', () {
    test(
      'excludes package tests, loose _test.dart, and generated suffixes',
      () {
        expect(repoLintPathIsExcludedTestOrGeneratedDart('a.dart'), isFalse);
        expect(
          repoLintPathIsExcludedTestOrGeneratedDart('x_test.dart'),
          isTrue,
        );
        expect(
          repoLintPathIsExcludedTestOrGeneratedDart('lib/foo_test.dart'),
          isTrue,
        );
        expect(
          repoLintPathIsExcludedTestOrGeneratedDart('packages/p/test/a.dart'),
          isTrue,
        );
        expect(
          repoLintPathIsExcludedTestOrGeneratedDart('lib/x.g.dart'),
          isTrue,
        );
        expect(
          repoLintPathIsExcludedTestOrGeneratedDart('lib/x.freezed.dart'),
          isTrue,
        );
        expect(
          repoLintPathIsExcludedTestOrGeneratedDart('lib/x.mocks.dart'),
          isTrue,
        );
        expect(
          repoLintPathIsExcludedTestOrGeneratedDart('lib/x.gen.dart'),
          isTrue,
        );
        expect(repoLintPathIsExcludedTestOrGeneratedDart('lib/x.txt'), isTrue);
      },
    );
  });

  group('repoLintPathShouldSkipAstRuleFile', () {
    test('skips generated, repo-root test/, fixtures; keeps package test/', () {
      expect(
        repoLintPathShouldSkipAstRuleFile('packages/p/test/a.dart'),
        isFalse,
      );
      expect(
        repoLintPathShouldSkipAstRuleFile('app/integration_test/e2e.dart'),
        isFalse,
      );
      expect(
        repoLintPathShouldSkipAstRuleFile('test/check_foo_test.dart'),
        isTrue,
      );
      expect(
        repoLintPathShouldSkipAstRuleFile('packages/p/lib/x.g.dart'),
        isTrue,
      );
      expect(
        repoLintPathShouldSkipAstRuleFile('packages/p/lib/goldens/foo.dart'),
        isTrue,
      );
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
      expect(
        repoLintPathIsDomainLibSourceForScan('packages/foo/test/t.dart'),
        isFalse,
      );
    });
  });

  group('repoLintPathIsDomainTestOrIntegrationTestSourceForScan', () {
    test('matches package test and integration_test trees', () {
      expect(
        repoLintPathIsDomainTestOrIntegrationTestSourceForScan(
          'packages/foo/test/t.dart',
        ),
        isTrue,
      );
      expect(
        repoLintPathIsDomainTestOrIntegrationTestSourceForScan(
          'app/integration_test/e2e.dart',
        ),
        isTrue,
      );
      expect(
        repoLintPathIsDomainTestOrIntegrationTestSourceForScan(
          'test/check_foo_test.dart',
        ),
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
          p.join('packages', 'z', 'test', 't.dart'),
        ]),
      );
      expect(
        rels,
        isNot(contains(p.join('packages', 'z', 'lib', 'keep.g.dart'))),
      );
    });
  });

  group('repoLintPathIsUnderLiteralScanRoots', () {
    test('matches top-level scan roots including ctdev', () {
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
        isTrue,
      );
      expect(
        repoLintPathIsUnderLiteralScanRoots(
          'other/x.dart',
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
      expect(
        repoLintIdentifierLiteralShouldSkipFile(
          'packages/p/test/widget_test.dart',
          excluded,
        ),
        isFalse,
      );
      expect(
        repoLintIdentifierLiteralShouldSkipFile(
          'app/integration_test/e2e.dart',
          excluded,
        ),
        isFalse,
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

  group('repoLintPathIsUnderPackageOrRootTestTree', () {
    test('detects repo test/ and package test dirs', () {
      expect(repoLintPathIsUnderPackageOrRootTestTree('test/foo.dart'), isTrue);
      expect(
        repoLintPathIsUnderPackageOrRootTestTree(
          p.join('packages', 'p', 'test', 'a.dart'),
        ),
        isTrue,
      );
      expect(
        repoLintPathIsUnderPackageOrRootTestTree('packages/p/lib/a.dart'),
        isFalse,
      );
    });
  });

  group('repoLintCanonicalProvinceTileKeyShouldSkipFile', () {
    test('skips excluded, repo-root test, and generated; not package test', () {
      const excluded = <String>{'tool/x.dart'};
      expect(
        repoLintCanonicalProvinceTileKeyShouldSkipFile('tool/x.dart', excluded),
        isTrue,
      );
      expect(
        repoLintCanonicalProvinceTileKeyShouldSkipFile(
          'test/check_foo_test.dart',
          excluded,
        ),
        isTrue,
      );
      expect(
        repoLintCanonicalProvinceTileKeyShouldSkipFile(
          p.join('packages', 'p', 'test', 'a.dart'),
          excluded,
        ),
        isFalse,
      );
      expect(
        repoLintCanonicalProvinceTileKeyShouldSkipFile(
          'packages/p/lib/a.g.dart',
          excluded,
        ),
        isTrue,
      );
      expect(
        repoLintCanonicalProvinceTileKeyShouldSkipFile(
          'packages/p/lib/a.gen.dart',
          excluded,
        ),
        isTrue,
      );
      expect(
        repoLintCanonicalProvinceTileKeyShouldSkipFile(
          'packages/p/lib/a.dart',
          excluded,
        ),
        isFalse,
      );
    });
  });

  group('collectRepoLintCanonicalProvinceTileKeyDartFiles', () {
    test('keeps lib sources and package tests; drops generated', () {
      final tmp = Directory.systemTemp.createTempSync('ct_canon_tile_');
      addTearDown(() {
        if (tmp.existsSync()) {
          tmp.deleteSync(recursive: true);
        }
      });
      final repo = tmp.path;
      File(
        p.join(repo, 'packages', 'p', 'lib', 'keep.dart'),
      ).createSync(recursive: true);
      File(
        p.join(repo, 'packages', 'p', 'lib', 'x.g.dart'),
      ).createSync(recursive: true);
      File(
        p.join(repo, 'packages', 'p', 'test', 't.dart'),
      ).createSync(recursive: true);

      final got = collectRepoLintCanonicalProvinceTileKeyDartFiles(repo, {});
      final rels = got.map((f) => p.relative(f.path, from: repo)).toSet();
      expect(rels, contains(p.join('packages', 'p', 'lib', 'keep.dart')));
      expect(rels, isNot(contains(p.join('packages', 'p', 'lib', 'x.g.dart'))));
      expect(rels, contains(p.join('packages', 'p', 'test', 't.dart')));
    });
  });

  group('repoLintAppLibHardcodedUiVisitorShouldSkip', () {
    test('matches historical app/lib visitor filters', () {
      expect(
        repoLintAppLibHardcodedUiVisitorShouldSkip('app/lib/a.dart'),
        isFalse,
      );
      expect(
        repoLintAppLibHardcodedUiVisitorShouldSkip('app/lib/a.g.dart'),
        isTrue,
      );
      expect(
        repoLintAppLibHardcodedUiVisitorShouldSkip('app/lib/foo_test.dart'),
        isTrue,
      );
      expect(
        repoLintAppLibHardcodedUiVisitorShouldSkip('app/lib/x.gen.dart'),
        isTrue,
      );
    });
  });

  group('collectRepoLintAppLibDartFilesSorted', () {
    test('returns sorted dart files under app/lib', () {
      final tmp = Directory.systemTemp.createTempSync('ct_app_lib_');
      addTearDown(() {
        if (tmp.existsSync()) {
          tmp.deleteSync(recursive: true);
        }
      });
      final repo = tmp.path;
      File(p.join(repo, 'app', 'lib', 'b.dart')).createSync(recursive: true);
      File(p.join(repo, 'app', 'lib', 'a.dart')).createSync(recursive: true);

      final got = collectRepoLintAppLibDartFilesSorted(repo);
      expect(got.length, 2);
      expect(p.basename(got[0].path), 'a.dart');
      expect(p.basename(got[1].path), 'b.dart');
    });
  });

  group('repoLintSplitRelativeDartPathsArg', () {
    test('splits commas and newlines and trims', () {
      expect(repoLintSplitRelativeDartPathsArg(''), isEmpty);
      expect(repoLintSplitRelativeDartPathsArg('  '), isEmpty);
      expect(repoLintSplitRelativeDartPathsArg('a.dart,b.dart'), [
        'a.dart',
        'b.dart',
      ]);
      expect(repoLintSplitRelativeDartPathsArg('a.dart\nb.dart'), [
        'a.dart',
        'b.dart',
      ]);
      expect(repoLintSplitRelativeDartPathsArg(' a.dart , b.dart '), [
        'a.dart',
        'b.dart',
      ]);
    });
  });

  group('repoLintParseIncrementalRelativeDartPathsFromArgs', () {
    test('returns null paths when no --files', () {
      final r = repoLintParseIncrementalRelativeDartPathsFromArgs(const []);
      expect(r.paths, isNull);
      expect(r.missingValueError, isFalse);
    });

    test('parses --files= comma list', () {
      final r = repoLintParseIncrementalRelativeDartPathsFromArgs(const [
        '--files=lib/a.dart,lib/b.dart',
      ]);
      expect(r.paths, ['lib/a.dart', 'lib/b.dart']);
      expect(r.missingValueError, isFalse);
    });

    test('parses --files followed by csv', () {
      final r = repoLintParseIncrementalRelativeDartPathsFromArgs(const [
        '--files',
        'lib/a.dart,lib/b.dart',
      ]);
      expect(r.paths, ['lib/a.dart', 'lib/b.dart']);
      expect(r.missingValueError, isFalse);
    });

    test('sets missingValueError when --files has no value', () {
      final r = repoLintParseIncrementalRelativeDartPathsFromArgs(const [
        '--files',
      ]);
      expect(r.paths, isNull);
      expect(r.missingValueError, isTrue);
    });

    test('last --files wins', () {
      final r = repoLintParseIncrementalRelativeDartPathsFromArgs(const [
        '--files=first.dart',
        '--files',
        'second.dart',
      ]);
      expect(r.paths, ['second.dart']);
      expect(r.missingValueError, isFalse);
    });
  });

  group('repoLintParseStrictIncrementalFilesArgs', () {
    test('empty argv yields no paths and no errors', () {
      final r = repoLintParseStrictIncrementalFilesArgs(const []);
      expect(r.paths, isNull);
      expect(r.missingValueError, isFalse);
      expect(r.unsupportedArgument, isNull);
    });

    test('rejects unknown flags', () {
      final r = repoLintParseStrictIncrementalFilesArgs(const ['--verbose']);
      expect(r.unsupportedArgument, '--verbose');
    });

    test('parses --files= then rejects trailing junk', () {
      final r = repoLintParseStrictIncrementalFilesArgs(const [
        '--files=a.dart',
        '--other',
      ]);
      expect(r.paths, ['a.dart']);
      expect(r.unsupportedArgument, '--other');
    });
  });
}
