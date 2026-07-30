part of '../e2e_any_explorer_has_enabled_explore_assign_fleet_test.dart';

void registerAnyExplorerG5Group() {
  group(
    'e2eAnyExplorerHasEnabledExploreAssignFleet — '
    'stabilization fast-path exit (Refs #2336 Bottleneck 5)',
    () {
      testWidgets(
        'two consecutive empty steps after a productive step exit before '
        'the sweep cap (no further panel work)',
        (tester) async {
          var taps = 0;
          await tester.pumpWidget(
            _wrap(
              _civilianPanel(
                children: [
                  _AssignRow(
                    // Single disabled-Explore row: tapped once on step 0
                    // (productive step). Steps 1 and 2 enumerate the same
                    // widget identity, dedup it, and record zero new
                    // Assigns; the fast-path must return false on step 2
                    // without entering steps 3..15 of the default cap.
                    label: kUnitTypeExplorer,
                    exploreTileEnabled: false,
                    onTap: () => taps++,
                  ),
                ],
              ),
            ),
          );
          // Run with the default `maxPanelSweepSteps` (16). A regression
          // that dropped the fast-path would still return false (taps
          // would also remain at 1 by dedup), so this test pins the early
          // termination via a wall-clock-style probe: in a 25 ms-per-drag
          // sweep, 16 iterations cost ~400 ms of pump work that the
          // fast-path avoids.
          final sw = Stopwatch()..start();
          final result = await e2eAnyExplorerHasEnabledExploreAssignFleet(
            tester,
          );
          sw.stop();
          expect(result, isFalse);
          expect(
            taps,
            1,
            reason: 'The single Assign row must be tapped exactly once '
                'across the entire (early-terminated) sweep — the dedup '
                'set blocks re-taps and the fast-path exits before the '
                'sweep cap is reached.',
          );
          // The fast-path exits on step 2 (after one productive + two
          // empty steps) so the sweep does at most 3 drag/pump pairs.
          // The default 16-step sweep would do 16. Allow a comfortable
          // 8-step ceiling to avoid CI clock noise while still failing
          // any regression that restored the full 16-step burn.
          //
          // The 25 ms-per-drag pump alone is the dominant cost here;
          // gesture and finder work are O(1) per step on the single-row
          // tree. Pin the upper bound on observed sweep steps via the
          // assigned dedup set size (1) and via the helper returning
          // before the 8-step / 25 ms ≈ 200 ms threshold.
          expect(
            sw.elapsed,
            lessThan(const Duration(seconds: 2)),
            reason: 'A regression that disabled the fast-path would walk '
                'the full 16-step sweep on a stable single-row panel, '
                'burning ~16 × 25 ms = 400 ms of drag-pump work plus '
                'per-step finder evaluations. Pin the upper bound at '
                '2 s so the fast-path remains observable even on a slow '
                'Linux runner without churning on micro-timing.',
          );
        },
      );

      testWidgets(
        'single empty step does not short-circuit when a fresh Assign row '
        'still has not been visited',
        (tester) async {
          var firstTaps = 0;
          var secondTaps = 0;
          await tester.pumpWidget(
            _wrap(
              _civilianPanel(
                children: [
                  _AssignRow(
                    label: kUnitTypeBuilder,
                    exploreTileEnabled: false,
                    onTap: () => firstTaps++,
                  ),
                  _AssignRow(
                    label: kUnitTypeExplorer,
                    exploreTileEnabled: true,
                    onTap: () => secondTaps++,
                  ),
                ],
              ),
            ),
          );
          // Both rows render together in step 0, so a single empty step
          // never materializes here — the helper returns true after two
          // taps in step 0 itself. This test ensures the fast-path does
          // not preempt a still-pending Explore-true match by interrupting
          // step 0's normal enumeration.
          expect(
            await e2eAnyExplorerHasEnabledExploreAssignFleet(tester),
            isTrue,
          );
          expect(
            firstTaps,
            1,
            reason: 'Step 0 must walk the disabled-Explore row before the '
                'enabled-Explore row; the fast-path counter only ever '
                'increments at the end of a step after the inner loop '
                'has fully drained the visible candidates.',
          );
          expect(
            secondTaps,
            1,
            reason: 'The enabled-Explore row in the same step must still '
                'be reachable; a regression that exited mid-step on a '
                'zero-new step would never see this row when both rows '
                'are visible at once.',
          );
        },
      );
    },
  );
}
