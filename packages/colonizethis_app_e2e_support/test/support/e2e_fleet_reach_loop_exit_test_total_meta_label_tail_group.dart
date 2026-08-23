// Extracted from e2e_fleet_reach_loop_exit_test_total_meta_label_test.dart
// (#4598 headroom).
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;

void registerE2eFleetReachLoopExitTestTotalMetaLabelTailGroups() {
  group(
    'e2eFleetReachLoopExitTestTotalMetaLabel — loopExhausted fall-through',
    () {
      test('loopExhausted -> null (caller continues to post-loop '
          'final-naval-check)', () {
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
      });
    },
  );

  group('e2eFleetReachLoopExitTestTotalMetaLabel — early-return covers every '
      'non-loopExhausted enum value', () {
    test(
      'every non-loopExhausted exit returns a non-null `result=...` meta',
      () {
        final exhaustiveExitsExcludingLoopExhausted = shared
            .E2eFleetReachLoopExit
            .values
            .where((e) => e != shared.E2eFleetReachLoopExit.loopExhausted)
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
  });

  group('e2eFleetReachLoopExitTestTotalMetaLabel — AC1 barrel forwarding', () {
    test('fleetReachLoopExitTestTotalMetaLabel (barrel alias) returns the '
        'same value as the lifted form for every exit', () {
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
    });

    test('fleetReachLoopExitTestTotalMetaLabel is re-exported as a '
        'tear-off (compile-time signature pin)', () {
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
    });
  });
}
