library;

import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'advance_game_start_intro_harness.dart';

void registerAdvanceGameStartIntroMultiLabelGroup() {
  group('e2eAdvanceGameStartIntroUntilDismissed multi-label pass', () {
    test(
      'control label order and post-tap settle cap stay pinned for bootstrap '
      'wall-clock (#2336 AC5)',
      () {
        expect(
          kE2eGameStartIntroControlLabels,
          ['I shall.', 'Continue'],
          reason:
              'The collapsed game_start_intro step (Refs #3628) exposes only '
              'the Yarn option label "I shall.", so it must be tried first for '
              'a one-tap dismissal; the generic Continue stays as a defensive '
              'fallback (e.g. the asset-load error shell).',
        );
        expect(
          kE2eDefaultIntroControlPostTapSettleTimeout,
          const Duration(milliseconds: 500),
          reason:
              'Per-control settle must stay well below the legacy 5 s cap so '
              'bootstrap does not burn seconds waiting for full dismissal '
              'after an intermediate control tap.',
        );
        expect(
          kE2eDefaultIntroControlPostTapSettleTimeout.inMilliseconds,
          lessThan(5000),
        );
      },
    );
  });

}
