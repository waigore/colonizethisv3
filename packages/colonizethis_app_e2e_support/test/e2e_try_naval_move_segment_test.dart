/// Pins the widget-tree contract of [e2eTryNavalMoveSegment]
/// (`app/integration_test/e2e_test_shared_panels.dart`).
///
/// The fleet-reach turn loop in `new_game_fleet_reaches_new_world_e2e_test.dart`
/// calls this helper via the AC1 barrel alias `tryNavalMoveSegment` up to
/// `_kMaxNextTurnTapsForNwFleetReach (35)` times per scenario. A silent rename
/// or behavioural drift here would either stall the loop at the per-call
/// [kE2eDefaultNavalMoveSegmentUiWait] cap × 35 turns (Bottleneck 4 / H1–H4 in
/// `SPEC/program/e2e-integration-tests.md` § Determinism) or break the
/// `no_non_home_move_control` / `no_legal_step` short-circuits that keep the
/// bundled-Explore path from burning wall clock on impossible moves.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test layer
/// carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 4 / H1–H4.
library;

// ignore_for_file: deprecated_member_use

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'support/dismissible_sea_dialog_host.dart';
import 'support/naval_fleet_move_harness.dart';
import 'support/e2e_try_naval_move_segment_guard_group.dart';
import 'support/e2e_try_naval_move_segment_guard_group2.dart';

void main() {
  suppressLogsForTests();

  group('e2eTryNavalMoveSegment — early exit branches', () {
    testWidgets('no non-home Move control -> no dialog (naval panel open)', (
      tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(
            children: [
              ExpansionTile(
                title: const Text('Home Fleet'),
                initiallyExpanded: true,
                children: [FleetMoveButton(onPressedSpy: () {})],
              ),
            ],
          ),
        ),
      );
      await e2eTryNavalMoveSegment(tester, l10n, navalPanelAlreadyOpen: true);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('no adjacent sea zones message -> Cancel dismisses dialog', (
      tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(
            children: [
              fleetMoveTile(
                title: 'Fleet 2',
                subtitle: 'New World — Outer Sea',
                dialogBuilder: (context) => AlertDialog(
                  content: Text(l10n.moveFleet_noAdjacentSeaZones),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.common_cancel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      await e2eTryNavalMoveSegment(tester, l10n, navalPanelAlreadyOpen: true);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('e2eTryNavalMoveSegment — happy path', () {
    testWidgets('sea-radio move dialog confirmed when panel already open', (
      tester,
    ) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(
            children: [
              fleetMoveTile(
                title: 'Fleet 2',
                subtitle: 'New World — Outer Sea',
                dialogBuilder: (_) => DismissibleSeaDialog(l10n: l10n),
              ),
            ],
          ),
        ),
      );
      await e2eTryNavalMoveSegment(tester, l10n, navalPanelAlreadyOpen: true);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
      'allowWarpDestinations false reaches sea-radio branch on warp+sea dialog',
      (tester) async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        await tester.pumpWidget(
          wrapNavalScrollBody(
            navalPanelRoot(
              children: [
                fleetMoveTile(
                  title: 'Fleet 2',
                  subtitle: 'New World — Outer Sea',
                  dialogBuilder: (_) => AlertDialog(
                    content: SingleChildScrollView(
                      key: kCtE2EMoveFleetDialogScrollRootKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<int>(
                            title: const Text('links to New World'),
                            value: 0,
                            groupValue: null,
                            onChanged: (_) {},
                          ),
                          RadioListTile<int>(
                            title: const Text(kE2eDismissibleSeaDialogPinLabel),
                            value: 1,
                            groupValue: null,
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      Builder(
                        builder: (context) => TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.common_confirm),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        Object? caught;
        try {
          await e2eTryNavalMoveSegment(
            tester,
            l10n,
            navalPanelAlreadyOpen: true,
            allowWarpDestinations: false,
            maxUiResponseWait: const Duration(seconds: 10),
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNull,
          reason:
              'allowWarpDestinations=false must delegate to the sea-radio '
              'branch without entering the warp drag-probe fail path.',
        );
        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  });

  registerE2eTryNavalMoveSegmentGuardGroup();

  registerE2eTryNavalMoveSegmentGuardGroup2();
}
