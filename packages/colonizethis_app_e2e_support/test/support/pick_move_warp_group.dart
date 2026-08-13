library;

import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'move_dialog_widget_tester_harness.dart';

void registerPickMoveWarpGroup() {
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

}
