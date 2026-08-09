import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

/// Opens the production screen from the empire rail, closing conflicting sheets
/// and dialogs first (GitHub #2336 H7 / shared full-turn path).
Future<void> e2eOpenProductionPanel(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration timeout = const Duration(seconds: 20),
}) async {
  final productionPanel = find.byKey(kCtE2EProductionPanelRootKey);
  final productionButton = find.byKey(kEmpireProductionButtonKey);
  final sw = Stopwatch()..start();
  await e2eAdvanceGameStartIntroUntilDismissed(tester, perf: perf);
  var idlePollMs = 25;
  while (sw.elapsed < timeout) {
    if (productionPanel.evaluate().isNotEmpty) {
      perf?.timing('open_panel_production', sw.elapsed);
      return;
    }

    if (find.byType(BottomSheet).evaluate().isNotEmpty) {
      await e2eCloseBottomSheet(tester, perf: perf);
      await e2ePumpUntilConditionOrIdle(
        tester,
        () => find.byType(BottomSheet).evaluate().isEmpty,
        timeout: const Duration(milliseconds: 600),
        perf: perf,
        phaseName: 'pump_until_sheet_cleared_production_open',
      );
      idlePollMs = 25;
      continue;
    }

    // Shared two-step CtDialogShell dismissal: broad-spectrum dismiss first,
    // then `handlePopRoute()` + bounded `e2ePumpUntil` when the shell
    // survives. Lifted into [e2eDismissCtDialogShellWithPopRouteEscalation]
    // so the escalation recipe is single-source-of-truth and pinned by
    // `app/test/e2e_dismiss_ct_dialog_shell_with_pop_route_escalation_test.dart`.
    // The default `escalationPhase` preserves the legacy
    // `pump_until_production_path_shell_cleared` perf-timing label so
    // downstream `E2E_TIMING|phase=...` log scrapers stay attributed to the
    // same step (Refs GitHub #2336 AC1 / AC2 / AC10).
    if (await e2eDismissCtDialogShellWithPopRouteEscalation(
      tester,
      perf: perf,
    )) {
      idlePollMs = 25;
      continue;
    }

    if (productionButton.evaluate().isNotEmpty) {
      // Mirror the naval/civilian opener's pre-tap rail-hit-testable wait
      // so an overlay covering the production button does not silently
      // drop the tap. No `secondary` finder — production has no
      // map-marker concept. Refs GitHub #2336 AC1 / AC10 (deferred slice
      // from PR #2782).
      await e2eAwaitPanelOpenerRailHitTestable(
        tester,
        primary: productionButton,
        perf: perf,
        phaseName: 'wait_until_production_rail_hit_testable',
      );
      // Shared defensive tap: `ensureVisible` (best-effort) + hit-testable
      // resolve so a rail button pushed off-screen by a transient overlay
      // still lands a centered tap. Production previously did the
      // hit-testable resolve inline but skipped `ensureVisible`; lifting
      // both behind [e2eEnsureVisibleAndTapHitTestable] makes the three
      // panel openers byte-equivalent on the post-tap path. Refs GitHub
      // #2336 AC1 / AC10.
      await e2eEnsureVisibleAndTapHitTestable(tester, productionButton);
      // Shared post-tap mount probe: fast hit-check → one pump → bounded
      // poll without `fail()` so the outer opener loop can dismiss
      // transient overlays and retry the rail tap when a race covers the
      // panel mount. Production keeps its longer 5 s cap (vs the 3 s used
      // by civilian/naval) so the existing wider tolerance for production
      // panel mount is preserved verbatim. Without this lift each of the
      // three openers inlined the same three-step recipe and could drift
      // independently (Refs GitHub #2336 AC1 / AC10).
      if (await e2eAwaitPanelMountAfterOpenerTap(
        tester,
        productionPanel,
        timeout: const Duration(seconds: 5),
        perf: perf,
        phaseName: 'pump_until_production_panel_after_rail_tap',
      )) {
        perf?.timing('open_panel_production', sw.elapsed);
        return;
      }
      idlePollMs = 25;
      continue;
    }
    await e2eDismissTransientUi(tester, perf: perf);
    if (await e2ePumpUntilConditionOrIdle(
      tester,
      () =>
          productionPanel.evaluate().isNotEmpty ||
          productionButton.hitTestable().evaluate().isNotEmpty,
      timeout: Duration(milliseconds: idlePollMs),
      perf: perf,
      phaseName: 'pump_until_production_entry_after_dismiss_transient',
    )) {
      idlePollMs = 25;
    } else {
      idlePollMs = e2eAdaptivePollRampAfterIdle(idlePollMs);
    }
  }

  fail(
    'Timed out opening production panel; '
    'button=$productionButton panel=$productionPanel',
  );
}
