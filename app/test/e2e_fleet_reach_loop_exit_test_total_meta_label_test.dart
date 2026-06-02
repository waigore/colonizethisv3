/// Pins the contract of [e2eFleetReachLoopExitTestTotalMetaLabel]
/// (`app/integration_test/e2e_test_shared_fleet_reach_loop_test_total_meta.dart`).
///
/// The fleet-reach scenario in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` calls this helper via
/// the AC1 barrel alias `fleetReachLoopExitTestTotalMetaLabel` exactly
/// once per [e2eFleetReachTurnLoop] return to decide whether to emit a
/// `result=<branch>` `test_total` meta and early-return, or fall through
/// to the post-loop final-naval-check (which later emits its own
/// `result=final_check`). A silent regression here would either:
///
///   - Rename one of the legacy `result=<branch>` strings and orphan every
///     `E2E_TIMING|...|meta=result=...` log scraper / AC8 dashboard keyed
///     on that label (Bottleneck 4 / Refs GitHub #2336).
///   - Drop the special **`reachedSnapshotAfterRegionTab` →
///     `result=reached_snapshot_precheck`** legacy mapping; the post-lift
///     loop intentionally surfaces the after-region-tab exit as a distinct
///     enum value but the wall-clock meta must remain byte-identical to
///     the pre-lift behaviour so the downstream attribution stays stable.
///   - Return a non-null value for [E2eFleetReachLoopExit.loopExhausted];
///     the call site relies on the null return to fall through to the
///     final-naval-check path and emit `result=final_check` after that
///     check completes. A non-null return here would short-circuit the
///     final naval check and skip the test's terminal assertion (silent
///     pass on a never-reached fleet).
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 4.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';
import '../integration_test/e2e_test_shared.dart' as shared;

void main() {
  suppressLogsForTests();

  group(
    'e2eFleetReachLoopExitTestTotalMetaLabel — early-return exit mappings',
    () {
      test(
        'reachedSnapshotPrecheck -> result=reached_snapshot_precheck',
        () {
          expect(
            e2eFleetReachLoopExitTestTotalMetaLabel(
              shared.E2eFleetReachLoopExit.reachedSnapshotPrecheck,
            ),
            'result=reached_snapshot_precheck',
            reason:
                'Pre-lift switch case emitted this exact meta when the '
                'iteration-start snapshot precheck succeeded. A silent '
                'rename would orphan every `E2E_TIMING|...|'
                'meta=result=reached_snapshot_precheck` log scraper / AC8 '
                'dashboard.',
          );
        },
      );

      test(
        'reachedSnapshotAfterDismiss -> result=reached_snapshot_after_dismiss',
        () {
          expect(
            e2eFleetReachLoopExitTestTotalMetaLabel(
              shared.E2eFleetReachLoopExit.reachedSnapshotAfterDismiss,
            ),
            'result=reached_snapshot_after_dismiss',
            reason:
                'Pre-lift switch case emitted this exact meta when the '
                'snapshot precheck succeeded after the per-iteration '
                '`e2eDismissTransientUi(...)` call. A silent rename would '
                'orphan the dismiss-attributed `test_total` timing line.',
          );
        },
      );

      test(
        'reachedSnapshotAfterRegionTab -> result=reached_snapshot_precheck '
        '(LEGACY label pin)',
        () {
          expect(
            e2eFleetReachLoopExitTestTotalMetaLabel(
              shared.E2eFleetReachLoopExit.reachedSnapshotAfterRegionTab,
            ),
            'result=reached_snapshot_precheck',
            reason:
                'Pre-lift switch case emitted `result=reached_snapshot_'
                'precheck` (NOT `..._after_region_tab`) for the '
                'region-tab branch. The lifted enum exposes the exit as a '
                'separate value so call sites can map it deliberately, '
                'but the wall-clock meta MUST remain byte-identical to '
                'the legacy label or downstream `E2E_TIMING|...|'
                'meta=result=...` scrapers / dashboards keyed on the '
                'legacy attribution will silently lose precheck-bucket '
                'reach detections (Refs GitHub #2336 AC1 / AC2 / '
                'Bottleneck 4).',
          );
        },
      );

      test('reachedInLoop -> result=reached_in_loop', () {
        expect(
          e2eFleetReachLoopExitTestTotalMetaLabel(
            shared.E2eFleetReachLoopExit.reachedInLoop,
          ),
          'result=reached_in_loop',
          reason:
              'Pre-lift switch case emitted this exact meta when the naval '
              'panel UI detected a non-home fleet in NW during the '
              'snapshot-unavailable branch. A silent rename would orphan '
              'the in-loop reach attribution.',
        );
      });

      test('reachedAfterMove -> result=reached_after_move', () {
        expect(
          e2eFleetReachLoopExitTestTotalMetaLabel(
            shared.E2eFleetReachLoopExit.reachedAfterMove,
          ),
          'result=reached_after_move',
          reason:
              'Pre-lift switch case emitted this exact meta when the '
              'harness detected the reach after a `e2eTryNavalMoveSegment` '
              'attempt + close-sheet. A silent rename would orphan the '
              'after-move reach attribution.',
        );
      });

      test(
        'reachedSnapshotAfterTurn -> result=reached_snapshot_after_turn',
        () {
          expect(
            e2eFleetReachLoopExitTestTotalMetaLabel(
              shared.E2eFleetReachLoopExit.reachedSnapshotAfterTurn,
            ),
            'result=reached_snapshot_after_turn',
            reason:
                'Pre-lift switch case emitted this exact meta when the '
                'snapshot precheck succeeded after the per-iteration '
                '`e2eAdvanceOneHumanTurn(...)`. A silent rename would '
                'orphan the post-next-turn reach attribution.',
          );
        },
      );
    },
  );

  group(
    'e2eFleetReachLoopExitTestTotalMetaLabel — loopExhausted fall-through',
    () {
      test(
        'loopExhausted -> null (caller continues to post-loop '
        'final-naval-check)',
        () {
          expect(
            e2eFleetReachLoopExitTestTotalMetaLabel(
              shared.E2eFleetReachLoopExit.loopExhausted,
            ),
            isNull,
            reason:
                'Pre-lift switch case used `break;` here to fall through '
                'to the post-loop `ensureNonHomeFleetInNwAfterLoop` call '
                'and the final `result=final_check` `test_total` timing. '
                'A non-null return would short-circuit that path and skip '
                'the test\'s terminal naval assertion — silently passing '
                'a scenario where the fleet never reached NW. The null '
                'return is the structural fall-through signal the lifted '
                'helper preserves; the call site uses '
                '`if (earlyReturnMeta != null) { emit + return; }` so the '
                'loopExhausted branch continues into the post-loop work.',
          );
        },
      );
    },
  );

  group(
    'e2eFleetReachLoopExitTestTotalMetaLabel — early-return covers every '
    'non-loopExhausted enum value',
    () {
      test(
        'every non-loopExhausted exit returns a non-null `result=...` meta',
        () {
          final exhaustiveExitsExcludingLoopExhausted =
              shared.E2eFleetReachLoopExit.values
                  .where(
                    (e) => e != shared.E2eFleetReachLoopExit.loopExhausted,
                  )
                  .toList();
          for (final exit in exhaustiveExitsExcludingLoopExhausted) {
            final meta = e2eFleetReachLoopExitTestTotalMetaLabel(exit);
            expect(
              meta,
              isNotNull,
              reason:
                  'A new early-return exit added to '
                  'E2eFleetReachLoopExit without a corresponding entry '
                  'here would silently fall through to the '
                  'final-naval-check path and skip the early-return '
                  'attribution. The helper must map every '
                  'non-loopExhausted value to a non-null '
                  '`result=...` meta label so a future enum addition '
                  'fails this exhaustive pin at unit-test time '
                  'instead of in CI dashboards (exit was: $exit).',
            );
            expect(
              meta!.startsWith('result='),
              isTrue,
              reason:
                  'Every meta label must start with `result=` so the '
                  'downstream `E2E_TIMING|...|meta=result=...` scraper '
                  'attribution stays stable (exit was: $exit, meta was: '
                  '"$meta").',
            );
          }
        },
      );
    },
  );

  group(
    'e2eFleetReachLoopExitTestTotalMetaLabel — AC1 barrel forwarding',
    () {
      test(
        'fleetReachLoopExitTestTotalMetaLabel (barrel alias) returns the '
        'same value as the lifted form for every exit',
        () {
          for (final exit in shared.E2eFleetReachLoopExit.values) {
            expect(
              fleetReachLoopExitTestTotalMetaLabel(exit),
              e2eFleetReachLoopExitTestTotalMetaLabel(exit),
              reason:
                  'The AC1 barrel wrapper must forward the exit verbatim '
                  'and return the same `String?` the lifted form returns. '
                  'A regression that hard-coded a default or dropped a '
                  'branch from the wrapper would surface here (exit was: '
                  '$exit).',
            );
          }
        },
      );

      test(
        'fleetReachLoopExitTestTotalMetaLabel is re-exported as a '
        'tear-off (compile-time signature pin)',
        () {
          final String? Function(shared.E2eFleetReachLoopExit) ref =
              fleetReachLoopExitTestTotalMetaLabel;
          expect(
            ref,
            isNotNull,
            reason:
                'The AC1 barrel must continue to export the helper with '
                'the documented signature: `String? Function('
                'E2eFleetReachLoopExit)`. A silent removal from the '
                '`show` clause, an arg-type swap, or a changed return '
                'nullability would fail this assignment at compile time.',
          );
        },
      );
    },
  );
}
