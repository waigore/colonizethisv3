// Regression guard (Refs #2509 S1): ensures planning dartdoc and SPEC/ai
// documents stop claiming the deleted legacy files (`colonial_pressure.dart`
// and `diplomacy_planner_peace_targets.dart`) retain delegating stubs or have
// a pending deletion. Both files were deleted in #2509 S1; the helpers they
// hosted are canonical in the phase-planner modules and
// `observer_goal_phase.dart`.
//
// New dartdoc / SPEC text may still describe the historical migration via
// past-tense phrases ("previously retained", "now-completed S1 deletion",
// "formerly in colonial_pressure.dart"). This guard fails when present-tense
// claims reappear that contradict the live tree.

import 'dart:io';

import 'package:colonizethis_test/test.dart';

const _forbiddenSubstrings = <String>[
  'retains a thin delegating',
  'retains thin delegating',
  'planned S1 deletion',
  'until S1 deletion',
];

const _planningDirRelative = 'lib/src/planning';

/// Resolves the planning directory in `packages/colonizethis_ai/` whether the
/// test is invoked from the repo root or from the package directory.
Directory _planningDir() {
  for (final candidate in <String>[
    _planningDirRelative,
    'packages/colonizethis_ai/$_planningDirRelative',
  ]) {
    final dir = Directory(candidate);
    if (dir.existsSync()) {
      return dir;
    }
  }
  fail(
    'Could not locate planning lib directory; tried $_planningDirRelative and '
    'packages/colonizethis_ai/$_planningDirRelative',
  );
}

Iterable<File> _planningDartFiles() => _planningDir()
    .listSync(recursive: true, followLinks: false)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

void main() {
  group('SPEC/dartdoc post-S1 hygiene (Refs #2509)', () {
    test('planning/*.dart contains no present-tense claims that deleted files '
        'retain delegating stubs or have a planned S1 deletion', () {
      final offenders = <String>[];
      for (final file in _planningDartFiles()) {
        final content = file.readAsStringSync();
        for (final phrase in _forbiddenSubstrings) {
          if (content.contains(phrase)) {
            offenders.add('${file.path}: contains "$phrase"');
          }
        }
      }
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
      final offenders = <String>[];
      const deletedImportNeedles = <String>[
        "'colonial_pressure.dart'",
        "'diplomacy_planner_peace_targets.dart'",
        'package:colonizethis_ai/src/planning/colonial_pressure.dart',
        'package:colonizethis_ai/src/planning/'
            'diplomacy_planner_peace_targets.dart',
      ];
      for (final file in _planningDartFiles()) {
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
      expect(offenders, isEmpty);
    });
  });
}
