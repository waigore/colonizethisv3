// Regression guard (Refs #2509 S1): ensures planning dartdoc, SPEC/ai
// documents, and `colonizethis_ai` test comments stop claiming the deleted
// legacy files (`colonial_pressure.dart` and
// `diplomacy_planner_peace_targets.dart`) retain delegating stubs or have
// a pending deletion. Both files were deleted in #2509 S1; the helpers they
// hosted are canonical in the phase-planner modules and
// `observer_goal_phase.dart`.
//
// New dartdoc / SPEC / test-comment text may still describe the historical
// migration via past-tense phrases ("previously retained",
// "now-completed S1 deletion", "formerly in colonial_pressure.dart"). This
// guard fails when present-tense claims reappear that contradict the live
// tree, whether in `lib/src/planning/` or in this package's `test/` tree.

import 'dart:io';

import 'package:colonizethis_test/test.dart';

const _forbiddenSubstrings = <String>[
  'retains a thin delegating',
  'retains thin delegating',
  'planned S1 deletion',
  'until S1 deletion',
];

const _planningDirRelative = 'lib/src/planning';
const _testDirRelative = 'test';

/// Self-reference excluded from the scan because this guard intentionally
/// embeds the forbidden substrings in its own constants.
const _selfRelative =
    'test/planning/spec_dartdoc_stale_legacy_file_refs_test.dart';

/// Resolves a directory inside the `colonizethis_ai` package whether the
/// test is invoked from the repo root or from the package directory.
Directory _packageDir(String relative) {
  for (final candidate in <String>[
    relative,
    'packages/colonizethis_ai/$relative',
  ]) {
    final dir = Directory(candidate);
    if (dir.existsSync()) {
      return dir;
    }
  }
  fail(
    'Could not locate $relative directory; tried '
    '$relative and packages/colonizethis_ai/$relative',
  );
}

Iterable<File> _dartFilesUnder(String relative) => _packageDir(relative)
    .listSync(recursive: true, followLinks: false)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

bool _isSelfReferenceGuard(File file) {
  final normalized = file.path.replaceAll('\\', '/');
  return normalized.endsWith(_selfRelative);
}

List<String> _scanForbiddenSubstrings(Iterable<File> files) {
  final offenders = <String>[];
  for (final file in files) {
    if (_isSelfReferenceGuard(file)) continue;
    final content = file.readAsStringSync();
    for (final phrase in _forbiddenSubstrings) {
      if (content.contains(phrase)) {
        offenders.add('${file.path}: contains "$phrase"');
      }
    }
  }
  return offenders;
}

List<String> _scanLegacyImports(Iterable<File> files) {
  final offenders = <String>[];
  const deletedImportNeedles = <String>[
    "'colonial_pressure.dart'",
    "'diplomacy_planner_peace_targets.dart'",
    'package:colonizethis_ai/src/planning/colonial_pressure.dart',
    'package:colonizethis_ai/src/planning/'
        'diplomacy_planner_peace_targets.dart',
  ];
  for (final file in files) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.trimLeft().startsWith('import ')) {
        continue;
      }
      for (final needle in deletedImportNeedles) {
        if (line.contains(needle)) {
          offenders.add(
            '${file.path}:${i + 1}: imports deleted legacy file '
            '($needle)',
          );
        }
      }
    }
  }
  return offenders;
}

void main() {
  group('SPEC/dartdoc post-S1 hygiene (Refs #2509)', () {
    test('planning/*.dart contains no present-tense claims that deleted files '
        'retain delegating stubs or have a planned S1 deletion', () {
      final offenders = _scanForbiddenSubstrings(
        _dartFilesUnder(_planningDirRelative),
      );
      expect(
        offenders,
        isEmpty,
        reason:
            'The legacy `colonial_pressure.dart` and '
            '`diplomacy_planner_peace_targets.dart` files were deleted in '
            '#2509 S1. Update doc-comment wording to past tense (e.g. '
            '"previously retained a thin delegating stub", "now-completed '
            'S1 deletion").\n\nOffending sites:\n${offenders.join('\n')}',
      );
    });

    test('planning/*.dart does not import deleted legacy files', () {
      final offenders = _scanLegacyImports(
        _dartFilesUnder(_planningDirRelative),
      );
      expect(offenders, isEmpty);
    });

    test('test/**/*.dart contains no present-tense claims that deleted files '
        'retain delegating stubs or have a planned S1 deletion', () {
      final offenders = _scanForbiddenSubstrings(
        _dartFilesUnder(_testDirRelative),
      );
      expect(
        offenders,
        isEmpty,
        reason:
            'colonizethis_ai test comments must not reintroduce the '
            'present-tense claim that `colonial_pressure.dart` or '
            '`diplomacy_planner_peace_targets.dart` still exists. Both '
            'files were deleted in #2509 S1; rewrite to past tense '
            '("previously retained a thin delegating stub", "now-completed '
            'S1 deletion").\n\nOffending sites:\n${offenders.join('\n')}',
      );
    });

    test('test/**/*.dart does not import deleted legacy files', () {
      final offenders = _scanLegacyImports(
        _dartFilesUnder(_testDirRelative),
      );
      expect(offenders, isEmpty);
    });
  });
}
