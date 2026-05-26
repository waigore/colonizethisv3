// Regression guard (Refs #2509 S1 / S5): ensures planning dartdoc, SPEC/ai
// documents, and `colonizethis_ai` test comments stop claiming the deleted
// legacy files (`colonial_pressure.dart` and
// `diplomacy_planner_peace_targets.dart`) retain delegating stubs or have
// a pending deletion, and stop claiming the S5 orchestrator wiring is still
// pending. Both legacy files were deleted in #2509 S1; their helpers are
// canonical in the phase-planner modules and `observer_goal_phase.dart`.
// The S5 orchestrator wiring through `phase_planner_dispatch.dart` and
// `domain_planner_orchestrator.dart` is in place; `collectStalledGreatPowerPeaceTargets`
// is retained as the no-`phasePlan` fallback path, not as a placeholder.
//
// New dartdoc / SPEC / test-comment text may still describe the historical
// migration via past-tense phrases ("previously retained",
// "now-completed S1 deletion", "formerly in colonial_pressure.dart",
// "the S5 orchestrator wiring is in place", "on the landed post-S5
// dispatch path"). This guard fails when present-tense claims reappear
// that contradict the live tree, whether in `lib/src/planning/`, in this
// package's `test/` tree, or in `SPEC/ai/**/*.md` markdown documents.

import 'dart:io';

import 'package:colonizethis_test/test.dart';

const _forbiddenSubstrings = <String>[
  'retains a thin delegating',
  'retains thin delegating',
  'is a thin delegating',
  'now a thin delegating',
  'planned S1 deletion',
  'until S1 deletion',
  'until S1 deletes',
  'tracked under S5 / S1 of #2509',
  'tracked under S5/S1 of #2509',
  'until S5 wires this module',
  'S5 orchestrator wire-up is in flight',
  'until the S5 orchestrator wiring lands',
  'once S5 wiring is active',
  'pre-S5 wiring',
];

const _planningDirRelative = 'lib/src/planning';
const _testDirRelative = 'test';

/// Repo-relative SPEC/ai directory. The guard's documented intent (see file
/// header) covers SPEC/ai markdown alongside `lib/src/planning/` dartdoc and
/// `test/` comments; scanning it here closes the doc-vs-code gap.
const _specAiDirRelative = 'SPEC/ai';

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

/// Resolves a repo-root-relative directory (e.g. `SPEC/ai`) whether the test
/// is invoked from the repo root or from `packages/colonizethis_ai/`. Mirrors
/// `_packageDir` so the SPEC scan tolerates the same `melos` / per-package
/// invocation matrix the planning + test scans already tolerate.
Directory _repoDir(String relative) {
  for (final candidate in <String>[relative, '../../$relative']) {
    final dir = Directory(candidate);
    if (dir.existsSync()) {
      return dir;
    }
  }
  fail(
    'Could not locate $relative directory; tried '
    '$relative and ../../$relative',
  );
}

Iterable<File> _dartFilesUnder(String relative) => _packageDir(relative)
    .listSync(recursive: true, followLinks: false)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

Iterable<File> _markdownFilesUnder(String relative) => _repoDir(relative)
    .listSync(recursive: true, followLinks: false)
    .whereType<File>()
    .where((f) => f.path.endsWith('.md'));

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

const _deletedLegacyImportNeedles = <String>[
  "'colonial_pressure.dart'",
  "'diplomacy_planner_peace_targets.dart'",
  'package:colonizethis_ai/src/planning/colonial_pressure.dart',
  'package:colonizethis_ai/src/planning/'
      'diplomacy_planner_peace_targets.dart',
];

List<String> _scanLegacyImports(Iterable<File> files) {
  final offenders = <String>[];
  for (final file in files) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      _collectLegacyImportOffenders(file, i + 1, lines[i], offenders);
    }
  }
  return offenders;
}

void _collectLegacyImportOffenders(
  File file,
  int lineNumber,
  String line,
  List<String> offenders,
) {
  if (!line.trimLeft().startsWith('import ')) return;
  for (final needle in _deletedLegacyImportNeedles) {
    if (line.contains(needle)) {
      offenders.add(
        '${file.path}:$lineNumber: imports deleted legacy file '
        '($needle)',
      );
    }
  }
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
      final offenders = _scanLegacyImports(_dartFilesUnder(_testDirRelative));
      expect(offenders, isEmpty);
    });

    test('SPEC/ai/**/*.md contains no present-tense claims that deleted files '
        'retain delegating stubs or that the S5 orchestrator wiring is still '
        'pending', () {
      final offenders = _scanForbiddenSubstrings(
        _markdownFilesUnder(_specAiDirRelative),
      );
      expect(
        offenders,
        isEmpty,
        reason:
            'SPEC/ai documents must not reintroduce the present-tense claim '
            'that `colonial_pressure.dart` or '
            '`diplomacy_planner_peace_targets.dart` still exists with '
            'delegating stubs, or that the S5 orchestrator wiring is still '
            'in flight. Both legacy files were deleted in #2509 S1; the S5 '
            'orchestrator wiring through `phase_planner_dispatch.dart` and '
            '`domain_planner_orchestrator.dart` is in place. Rewrite to past '
            'tense (e.g. "previously retained a thin delegating stub", '
            '"on the landed post-S5 dispatch path").'
            '\n\nOffending sites:\n${offenders.join('\n')}',
      );
    });
  });
}
