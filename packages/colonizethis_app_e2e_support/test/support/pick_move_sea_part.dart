part of '../e2e_pick_move_destination_and_confirm_test.dart';

void registerPickMoveSeaGroup() {
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

}
