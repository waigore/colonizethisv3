library;

import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'move_dialog_widget_tester_harness.dart';

void registerPickMoveConstantsGroup() {
  group('e2ePickMoveDestinationAndConfirm — default constants', () {
    test(
      'kE2eDefaultMoveFleetDialogBudget matches the legacy 5 s per-call cap',
      () {
        expect(
          kE2eDefaultMoveFleetDialogBudget,
          const Duration(seconds: 5),
          reason:
              'The pre-lift private `_kMaxUiResponseWait = Duration(seconds: '
              '5)` constant gated every call site in '
              'new_game_fleet_reaches_new_world_e2e_helpers.dart. A '
              'regression that shortened this cap would force flaky '
              'budget-exceeded failures in the fleet-reach loop; a '
              'regression that widened it would inflate the wall clock '
              'cap issue #2336 § AC9 is shrinking.',
        );
      },
    );

    test(
      'kE2eDefaultMoveFleetWarpDragProbes matches the legacy 8-probe bound',
      () {
        expect(
          kE2eDefaultMoveFleetWarpDragProbes,
          8,
          reason:
              'The pre-lift private `maxWarpDragProbes = 8` constant capped '
              'the warp-row drag loop. A regression that reset this to the '
              'pre-#2336 36-probe cap (each 50 ms) would reintroduce '
              'Bottleneck 2 / H4 wall-clock blow-out (~1.8 s per turn × 35 '
              'turns).',
        );
      },
    );
  });
}
