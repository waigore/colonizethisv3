/// Pins the widget-tree contract of
/// [e2ePickMoveDestinationAndConfirm]
/// (`app/integration_test/e2e_test_shared_panels.dart`).
///
/// The fleet-reach turn loop in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` calls this helper via
/// `_tryNavalMoveSegment` up to `_kMaxNextTurnTapsForNwFleetReach (35)`
/// times per scenario. A silent rename / behavioural drift here would
/// either:
///
///   - Stall the loop at the per-call
///     [kE2eDefaultMoveFleetDialogBudget] cap (5 s) × 35 turns — Bottleneck
///     4 / H4 in `SPEC/program/e2e-integration-tests.md` § Determinism —
///     burning wall-clock issue #2336 § AC9 is shrinking; or
///   - Silently flip warp vs sea-radio selection and mask a real production
///     regression in `MoveFleetDialog`.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test layer
/// carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / AC4 / Bottleneck 4 / H4.
library;

// The production move-fleet dialog (`move_fleet_dialog.dart`) constructs
// `RadioListTile<_MovePick>` with the legacy `groupValue` / `onChanged` API;
// the AC1 helper matches on `runtimeType.toString().startsWith('RadioListTile<')`,
// so the test fixtures must build the same widget shape (not the newer
// RadioGroup-based API) for the pin to validate the production code path.
// Same pattern as `e2e_radio_list_tiles_in_alert_dialogs_test.dart`.
// ignore_for_file: deprecated_member_use

import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'support/move_dialog_widget_tester_harness.dart';

void main() {
  suppressLogsForTests();

  group('e2ePickMoveDestinationAndConfirm — warp branch', () {
    testWidgets(
      'taps warp RadioListTile when present and confirms (default args)',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        final host = await pumpMoveDialog(
          tester,
          l10n: l10n,
          includeWarp: true,
        );
        expect(host.selectedKind, isNull);
        expect(host.dialogOpen, isTrue);

        await e2ePickMoveDestinationAndConfirm(tester, l10n);

        expect(
          host.selectedKind,
          'warp',
          reason:
              'When the warp row text is present, the helper must select the '
              'warp RadioListTile (not the sea-radio fallback). A regression '
              'that tapped the sea radio here would silently keep the fleet '
              'sailing along NW seas instead of warping back to OW '
              '(Refs #1869 / fleet-reach behaviour).',
        );
        expect(
          host.dialogOpen,
          isFalse,
          reason:
              'Helper must tap Confirm and pump until the AlertDialog leaves '
              'the tree (`pump_until_move_dialog_closed`). A regression that '
              'returned before the dialog closed would leave the next loop '
              'iteration tapping into a stale dialog.',
        );
        expect(
          host.taps,
          1,
          reason:
              'Helper must tap exactly one RadioListTile. A double-tap or '
              'thrash would deselect the warp row before Confirm fires.',
        );
      },
    );

    testWidgets(
      'taps warp tile via RadioListTile ancestor (not the inner Text)',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        final host = await pumpMoveDialog(
          tester,
          l10n: l10n,
          includeWarp: true,
        );

        await e2ePickMoveDestinationAndConfirm(tester, l10n);

        // The tap target is `find.ancestor(of: warp.hitTestable().first,
        // matching: byWidgetPredicate(runtimeType startsWith 'RadioListTile<'))`.
        // The host's RadioListTile<int>.onChanged sets selectedRowIndex —
        // we verify the warp tile was selected (not just the Text widget).
        expect(
          host.selectedKind,
          'warp',
          reason:
              'Helper must tap the RadioListTile ancestor of the warp text '
              'so the tile selection actually updates (Linux CI / headless '
              'can miss implicit taps on the inner Text). A regression that '
              'tapped only the Text would leave selectedKind null.',
        );
      },
    );

    testWidgets(
      'drag-probes the scrollable when warp row is initially off-screen',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        final host = await pumpMoveDialog(
          tester,
          l10n: l10n,
          includeWarp: true,
          warpAheadFillers: 5,
        );
        final warpFinder = find.text(kMoveDialogWarpText);
        expect(
          warpFinder.evaluate().isNotEmpty,
          isTrue,
          reason:
              'Sanity: warp Text widget exists in the tree (off-screen) '
              'before the helper runs.',
        );

        await e2ePickMoveDestinationAndConfirm(tester, l10n);

        expect(
          host.selectedKind,
          'warp',
          reason:
              'After scrolling/dragging, the helper must successfully tap '
              'the warp tile. A regression that skipped the drag probe '
              'loop (or capped it at 0) would silently fail before tapping.',
        );
        expect(host.dialogOpen, isFalse);
      },
    );

    testWidgets(
      'fails deterministically when warp row never becomes hit-testable',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        // Wrap the warp tile in [IgnorePointer] so the Text widget remains
        // findable via `find.textContaining(...)` (the helper's entry
        // condition) but `warp.hitTestable()` always resolves empty. This
        // forces the deterministic `fail(...)` path after the drag-probe
        // loop exhausts; `NeverScrollableScrollPhysics` is not enough on
        // its own because [tester.scrollUntilVisible] composes
        // [Scrollable.ensureVisible] programmatically and bypasses scroll
        // physics.
        await pumpMoveDialog(
          tester,
          l10n: l10n,
          includeWarp: true,
          wrapWarpInIgnorePointer: true,
        );

        Object? caught;
        try {
          await e2ePickMoveDestinationAndConfirm(
            tester,
            l10n,
            maxWarpDragProbes: 2,
            moveDialogBudget: const Duration(seconds: 10),
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNotNull,
          reason:
              'Helper must fail deterministically when the warp row is '
              'never hit-testable. A silent fall-back to the sea radio '
              'would mask a real production scroll regression.',
        );
        expect(
          caught.toString(),
          contains('Warp row not hit-testable'),
          reason:
              'Failure message must name the warp-row diagnostic so the '
              'fleet-reach loop log surfaces the cause; a generic timeout '
              'message would leave Bottleneck 4 hard to diagnose.',
        );
      },
    );

    testWidgets(
      'falls back to dialog Scrollable when kCtE2EMoveFleetDialogScrollRootKey '
      'is absent',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        final host = await pumpMoveDialog(
          tester,
          l10n: l10n,
          includeWarp: true,
          withScrollKey: false,
        );

        await e2ePickMoveDestinationAndConfirm(tester, l10n);

        expect(
          host.selectedKind,
          'warp',
          reason:
              'Production [MoveFleetDialog] always supplies '
              'kCtE2EMoveFleetDialogScrollRootKey, but the helper must '
              'still tap the warp tile under a generic AlertDialog '
              'descendant-Scrollable fallback. A regression here would '
              'turn the helper into a soft-dependency on a private key.',
        );
      },
    );
  });

  group('e2ePickMoveDestinationAndConfirm — sea radio branch', () {
    testWidgets(
      'taps sea RadioListTile when warp row is absent',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        final host = await pumpMoveDialog(
          tester,
          l10n: l10n,
          includeWarp: false,
        );

        await e2ePickMoveDestinationAndConfirm(tester, l10n);

        expect(
          host.selectedKind,
          'sea',
          reason:
              'When no warp row exists, the helper must select the first '
              'AlertDialog-scoped RadioListTile via '
              'e2eRadioListTilesInAlertDialogs. A regression that dropped '
              'the AlertDialog scope would match panel radios outside the '
              'dialog (Refs `e2e_radio_list_tiles_in_alert_dialogs_test`).',
        );
        expect(host.dialogOpen, isFalse);
      },
    );

    testWidgets(
      'takes the sea-radio branch (no warp scroll/drag) when '
      'allowWarpDestinations is false',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        // Both rows hit-testable on a viewport that can fit them. The
        // contract pin is that with allowWarpDestinations=false **and**
        // [NeverScrollableScrollPhysics], the helper must NOT enter the
        // warp-scroll/drag branch (which would `fail` because the row
        // ordering puts the on-screen warp tile first but the helper's
        // sea-radio branch picks `seaRadio.first` directly — proving no
        // warp-scroll work happened).
        final host = await pumpMoveDialog(
          tester,
          l10n: l10n,
          includeWarp: true,
          // `NeverScrollableScrollPhysics` here would normally crash the
          // warp-scroll branch with "Warp row not hit-testable" once the
          // warp row is off-screen; we keep the row on-screen so the
          // helper succeeds via the sea-radio branch (whose `.first` is
          // the warp tile in tree order). The combination pins that
          // allowWarpDestinations=false does not consult the warp text or
          // probe drags at all.
          scrollPhysics: const NeverScrollableScrollPhysics(),
        );

        Object? caught;
        try {
          await e2ePickMoveDestinationAndConfirm(
            tester,
            l10n,
            allowWarpDestinations: false,
            // Cap drag probes at 0 so the warp branch (if accidentally
            // taken) would immediately fail with "Warp row not hit-testable".
            // A clean pass here proves the helper never entered that branch.
            maxWarpDragProbes: 0,
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNull,
          reason:
              'With allowWarpDestinations=false the helper must not consult '
              'the warp text or run the drag-probe loop — otherwise '
              'maxWarpDragProbes=0 would surface a deterministic '
              '"Warp row not hit-testable" failure here.',
        );
        expect(
          host.dialogOpen,
          isFalse,
          reason:
              'Sea-radio branch still confirms the dialog. A regression '
              'that left dialogOpen=true would stall the fleet-reach loop '
              'on a stale dialog.',
        );
        expect(
          host.selectedKind,
          isNotNull,
          reason:
              'Helper must tap `seaRadio.first` (whatever the first '
              'dialog-scoped RadioListTile happens to be in tree order). '
              'A null selectedKind would mean no tile was tapped — the '
              'helper short-circuited before Confirm.',
        );
      },
    );

    testWidgets(
      'sea radio branch needs no scrollable / scroll key in the dialog',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        // No Scrollable, no scroll key — only the sea-radio tile rendered
        // inside the AlertDialog content. The helper must reach the
        // sea-radio branch and confirm without depending on
        // `kCtE2EMoveFleetDialogScrollRootKey` or a descendant
        // [Scrollable].
        final host = await pumpMoveDialog(
          tester,
          l10n: l10n,
          includeWarp: false,
          includeScrollable: false,
        );

        Object? caught;
        try {
          await e2ePickMoveDestinationAndConfirm(
            tester,
            l10n,
            allowWarpDestinations: false,
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNull,
          reason:
              'Sea-radio branch must not require '
              'kCtE2EMoveFleetDialogScrollRootKey or a descendant '
              'Scrollable; it must read the AlertDialog-scoped radio list '
              'and tap the first match directly. A regression that '
              'required a scroll root here would break dialogs that fit '
              'every destination on one screen.',
        );
        expect(
          host.dialogOpen,
          isFalse,
          reason:
              'Even without a Scrollable, the helper must still tap '
              'Confirm and pump until the AlertDialog leaves the tree.',
        );
        expect(host.selectedKind, 'sea');
      },
    );
  });

  group('e2ePickMoveDestinationAndConfirm — budget / determinism', () {
    testWidgets(
      'fails with deterministic message when no AlertDialog mounts in time',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await pumpMoveDialogScaffold(tester, child: const SizedBox());

        Object? caught;
        try {
          await e2ePickMoveDestinationAndConfirm(
            tester,
            l10n,
            // Allow the inner `wait_until_found_move_dialog` (2 s) to run to
            // its own timeout and surface a deterministic "Timed out" failure;
            // the budget guard would otherwise short-circuit with the at-step
            // diagnostic, which is also valid but covered by the next case.
            moveDialogBudget: const Duration(seconds: 10),
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNotNull,
          reason:
              'When no AlertDialog mounts, the inner '
              'wait_until_found_move_dialog must throw (helper does not '
              'swallow it). Silent return would let the fleet-reach loop '
              'proceed into a NUL state.',
        );
        expect(
          caught.toString(),
          contains('Timed out'),
          reason:
              'Failure surface must include the timeout sentinel from '
              'e2eWaitUntilFound so triage points at the missing dialog, '
              'not a downstream symptom.',
        );
      },
    );

    testWidgets(
      'fails on the very first ensureBudget when moveDialogBudget is zero',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await pumpMoveDialog(
          tester,
          l10n: l10n,
          includeWarp: true,
        );

        Object? caught;
        try {
          await e2ePickMoveDestinationAndConfirm(
            tester,
            l10n,
            moveDialogBudget: Duration.zero,
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNotNull,
          reason:
              'A non-positive budget must trip the ensureBudget guard '
              'immediately. A regression that swallowed Duration.zero would '
              'let the helper run past the documented per-call cap.',
        );
        expect(
          caught.toString(),
          contains('Move fleet dialog exceeded'),
          reason:
              'Failure must use the budget-exceeded diagnostic (not a '
              'generic timeout) so triage knows the cap fired, not the '
              'inner finders.',
        );
      },
    );

    testWidgets(
      'is deterministic across two independent invocations',
      (WidgetTester tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));

        final hostA = await pumpMoveDialog(
          tester,
          l10n: l10n,
          includeWarp: true,
        );
        await e2ePickMoveDestinationAndConfirm(tester, l10n);
        expect(hostA.selectedKind, 'warp');
        expect(hostA.dialogOpen, isFalse);

        final hostB = await pumpMoveDialog(
          tester,
          l10n: l10n,
          includeWarp: true,
        );
        await e2ePickMoveDestinationAndConfirm(tester, l10n);
        expect(
          hostB.selectedKind,
          'warp',
          reason:
              'Helper has no hidden state — a second invocation on a fresh '
              'host must yield the same warp-tap result (Refs GitHub #2336 '
              'AC5 / Bottleneck 4 determinism contract).',
        );
        expect(hostB.dialogOpen, isFalse);
      },
    );
  });

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
