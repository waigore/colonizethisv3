import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared_bootstrap_map_hud.dart';

/// Selects an advanced-start preset in DLG10001 before tapping **Start**.
///
/// Requires the locked full-init profile (`CT_E2E_LOCKED_FULL_INIT=true`).
/// [optionLabel] must match the English l10n string (e.g. `50 Turns In (1598)`).
Future<void> e2eSelectLeaderDialogAdvancedStart(
  WidgetTester tester,
  String optionLabel, {
  E2ePerfLog? perf,
}) async {
  final dropdown = find.byType(CtDropdown<AdvancedStartType>);
  expect(dropdown, findsOneWidget);

  // Locked full-init DLG10001 exceeds the 720 px CI viewport; scroll the shell
  // body before tapping (same scrollable as the Start-button drag below).
  final shellScrollable = find.descendant(
    of: find.byType(CtDialogShell),
    matching: find.byType(Scrollable),
  );
  await tester.dragUntilVisible(
    dropdown,
    shellScrollable,
    const Offset(0, -120),
  );
  await e2ePumpUntilConditionOrIdle(
    tester,
    () => dropdown.hitTestable().evaluate().isNotEmpty,
    timeout: const Duration(milliseconds: 600),
    perf: perf,
    phaseName: 'pump_until_advanced_start_dropdown_tappable',
  );

  final didOpenMenu = await e2eEnsureVisibleAndTapHitTestable(
    tester,
    dropdown,
  );
  expect(
    didOpenMenu,
    isTrue,
    reason: 'Advanced start dropdown must be tappable after scroll',
  );
  await e2ePumpUntilConditionOrIdle(
    tester,
    () => find.text(optionLabel).evaluate().isNotEmpty,
    timeout: const Duration(seconds: 5),
    perf: perf,
    phaseName: 'pump_until_advanced_start_menu_open',
  );

  final menuOption = find.text(optionLabel);
  expect(
    menuOption,
    findsWidgets,
    reason: 'Advanced start menu must list $optionLabel',
  );
  final didSelectOption = await e2eEnsureVisibleAndTapHitTestable(
    tester,
    menuOption.last,
  );
  expect(
    didSelectOption,
    isTrue,
    reason: 'Advanced start option $optionLabel must be tappable',
  );
  await e2ePumpUntilConditionOrIdle(
    tester,
    () => find
        .widgetWithText(CtDropdown<AdvancedStartType>, optionLabel)
        .evaluate()
        .isNotEmpty,
    timeout: const Duration(seconds: 5),
    perf: perf,
    phaseName: 'pump_until_advanced_start_selected',
  );
}

/// Canonical new-game → map HUD path shared by E2E scenarios (Refs #2336).
///
/// Adaptive polling notes (GitHub #2336 AC5):
///
/// - After the `New Game` tap, [e2eWaitUntilFound] polls for the `Start`
///   button with check-before-pump + exponential backoff (25 → 500 ms cap)
///   via the inner [e2eWaitUntilFound] call.
/// - After the drag that scrolls the dialog to the `Start` button,
///   [e2ePumpUntilConditionOrIdle] polls for the button becoming
///   hit-testable with the same check-before-pump cadence.
/// - After the `Start` tap, [e2ePumpUntilConditionOrIdle] polls for any
///   post-tap observable (`Creating game` indicator, the home-to-capital
///   button on instant map gen, the intro-overlay loading branch, or the
///   `Could not create game` error dialog) with a short 200 ms safety net.
///   The downstream [e2eWaitForMapHudAfterNewGameStart] then handles the
///   longer-running adaptive poll up to [overallCap]. The settle slice is
///   attributable to `pump_until_post_start_tap_settled`.
/// - After the map HUD mounts, [e2ePumpUntilConditionOrIdle] polls for the
///   home-to-capital button becoming hit-testable before
///   [e2eAdvanceGameStartIntroUntilDismissed] dismisses the intro overlay.
///
/// No bare single-frame `tester.pump()` settles remain in the body; every
/// state transition is gated by a condition-based wait so the helper
/// conforms to AC5 end-to-end.
Future<void> e2eBootstrapNewGameToMap(
  WidgetTester tester, {
  E2ePerfLog? perf,
  Duration overallCap = const Duration(seconds: 60),
  String? advancedStartOptionLabel,
}) async {
  final phaseSw = Stopwatch()..start();
  await tester.tap(find.text('New Game'));
  await e2eWaitUntilFound(
    tester,
    find.text('Start'),
    timeout: const Duration(seconds: 30),
    perf: perf,
    phaseName: 'wait_until_found_start_button',
  );

  if (advancedStartOptionLabel != null) {
    await e2eSelectLeaderDialogAdvancedStart(
      tester,
      advancedStartOptionLabel,
      perf: perf,
    );
  }

  final startButton = find.ancestor(
    of: find.text('Start'),
    matching: find.byType(CtNinePatchButton),
  );
  expect(startButton, findsOneWidget);

  final shellScrollable = find.descendant(
    of: find.byType(CtDialogShell),
    matching: find.byType(Scrollable),
  );
  await tester.dragUntilVisible(
    startButton,
    shellScrollable,
    const Offset(0, -120),
  );
  await e2ePumpUntilConditionOrIdle(
    tester,
    () => startButton.hitTestable().evaluate().isNotEmpty,
    timeout: const Duration(milliseconds: 600),
    perf: perf,
    phaseName: 'pump_until_start_button_tappable_after_drag',
  );
  await tester.ensureVisible(startButton);
  await tester.tap(startButton);
  // Replace the legacy bare single-frame `await tester.pump();` settle with
  // an adaptive condition-based wait so the helper conforms to GitHub #2336
  // AC5 (check-before-pump + exponential backoff capped at ≤500 ms). The
  // poll short-circuits the moment any post-Start-tap observable surfaces
  // (`Creating game` indicator, the home-to-capital button on instant map
  // gen, the intro-overlay loading branch, or the `Could not create game`
  // error dialog), so the canonical success path (which mounts `Creating
  // game` on the very next frame) returns within a single 25 ms pump
  // instead of opaque pump-then-blind-handoff sequencing. The downstream
  // [e2eWaitForMapHudAfterNewGameStart] still runs the longer-running
  // adaptive poll; this settle is a short, observable safety net so
  // post-Start-tap latency is attributable to a dedicated
  // `pump_until_post_start_tap_settled` perf slice. The 200 ms cap is
  // strictly a fast-path bound — the downstream helper's `overallCap`
  // (default 60 s) governs the slow path.
  await e2ePumpUntilConditionOrIdle(
    tester,
    () =>
        find.text('Creating game').evaluate().isNotEmpty ||
        find.byKey(kHomeToCapitalButtonKey).evaluate().isNotEmpty ||
        find.text('Could not create game').evaluate().isNotEmpty ||
        e2eGameStartIntroBlocksUi(tester),
    timeout: const Duration(milliseconds: 200),
    perf: perf,
    phaseName: 'pump_until_post_start_tap_settled',
  );

  await e2eWaitForMapHudAfterNewGameStart(
    tester,
    overallCap: overallCap,
    perf: perf,
  );

  expect(find.byKey(kHomeToCapitalButtonKey), findsOneWidget);
  await e2ePumpUntilConditionOrIdle(
    tester,
    () =>
        find.byKey(kHomeToCapitalButtonKey).hitTestable().evaluate().isNotEmpty,
    timeout: const Duration(milliseconds: 800),
    perf: perf,
    phaseName: 'pump_until_home_capital_tappable_after_map',
  );
  await e2eAdvanceGameStartIntroUntilDismissed(tester, perf: perf);
  perf?.timing('new_game_to_map', phaseSw.elapsed);
}
