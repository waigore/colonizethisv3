// Extracted from explore_assign_snapshot_true_group.dart (#4598 headroom).
library;

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildRoad, kWorkTargetExplore;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'explore_assign_snapshot_fixtures.dart';

void registerExploreAssignSnapshotTrueGuardsAndDeterminismGroups() {
  group('e2eExploreAssignEnabledFromCivilianSnapshot — regression guards', () {
    test('case-sensitive: `Explore` (PascalCase) rejected', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          exploreAssignSnapshotForTest(
            availableWorkTargets: const {
              'unit-1': ['Explore'],
            },
          ),
        ),
        isFalse,
        reason:
            'Work-target ids are exact-match strings (logic-side '
            '`kWorkTargetExplore == \'explore\'`). A future code change '
            'that loosens comparison (e.g. ignore-case) would surface '
            'phantom matches against UI labels rather than the canonical '
            'target id — this pin keeps the comparison strict.',
      );
    });

    test('case-sensitive: `EXPLORE` (uppercase) rejected', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          exploreAssignSnapshotForTest(
            availableWorkTargets: const {
              'unit-1': ['EXPLORE'],
            },
          ),
        ),
        isFalse,
        reason:
            'Symmetric uppercase guard alongside the PascalCase case — '
            'pins the lower-case-only contract from both directions.',
      );
    });

    test('substring `exploration` does not satisfy the predicate', () {
      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(
          exploreAssignSnapshotForTest(
            availableWorkTargets: const {
              'unit-1': ['exploration'],
            },
          ),
        ),
        isFalse,
        reason:
            '`List.contains` performs exact equality. A future change '
            'that accidentally swaps to a `startsWith` / `Iterable.any` '
            'with substring matching would surface this regression here.',
      );
    });

    test(
      'first-qualifying unit short-circuits (existential, not universal)',
      () {
        final snap = exploreAssignSnapshotForTest(
          availableWorkTargets: const {
            'explorer-1': [kWorkTargetExplore],
            'unit-2': ['EXPLORE_ALL_NOT_A_REAL_TARGET'],
          },
        );
        expect(
          e2eExploreAssignEnabledFromCivilianSnapshot(snap),
          isTrue,
          reason:
              'Existential short-circuit on the first qualifying row — '
              'a universal-all-rows variant would walk the trailing '
              'placeholder list and still need to return true on the '
              'first match anyway, but the pin against `EXPLORE_ALL_*` '
              'guards against any future code that uses the trailing '
              'entry value to re-derive truthiness.',
        );
      },
    );
  });

  group('e2eExploreAssignEnabledFromCivilianSnapshot — determinism', () {
    test('identical input snapshots yield identical results', () {
      final snapA = exploreAssignSnapshotForTest(
        availableWorkTargets: const {
          'unit-1': [kWorkTargetBuildRoad],
          'explorer-2': [kWorkTargetExplore],
        },
      );
      final snapB = exploreAssignSnapshotForTest(
        availableWorkTargets: const {
          'unit-1': [kWorkTargetBuildRoad],
          'explorer-2': [kWorkTargetExplore],
        },
      );

      expect(
        e2eExploreAssignEnabledFromCivilianSnapshot(snapA),
        e2eExploreAssignEnabledFromCivilianSnapshot(snapB),
        reason:
            'Refs #2336 / Must-have AC1: predicates lifted into '
            'shared library MUST be deterministic. Two structurally '
            'identical snapshots must produce structurally identical '
            'outputs (no hidden state or global access in the lifted '
            'helper).',
      );
    });

    test('repeated calls on same snapshot yield identical results', () {
      final snap = exploreAssignSnapshotForTest(
        availableWorkTargets: const {
          'unit-1': [kWorkTargetExplore],
        },
      );
      final first = e2eExploreAssignEnabledFromCivilianSnapshot(snap);
      final second = e2eExploreAssignEnabledFromCivilianSnapshot(snap);
      final third = e2eExploreAssignEnabledFromCivilianSnapshot(snap);
      expect(
        [first, second, third],
        everyElement(equals(true)),
        reason:
            'Determinism for repeated calls on the same input — pins '
            'absence of memoization / mutable state in the predicate.',
      );
    });
  });
}
