/// Pins the widget-tree contract of [e2eTapMoveOnFirstNonHomeFleet]
/// (`app/integration_test/e2e_test_shared_panels.dart`).
///
/// The fleet-reach loop calls this helper through `_tryNavalMoveSegment`
/// (`new_game_fleet_reaches_new_world_e2e_helpers.dart`) up to
/// `_kMaxNextTurnTapsForNwFleetReach (35)` times per scenario. A silent
/// rename / fail-open here would stall the loop at the 35-turn cap × the
/// per-iteration `Move dialog` wait — Bottleneck 4 in
/// `SPEC/program/e2e-integration-tests.md` § Determinism — and a regression
/// that dropped the New World preference would similarly inflate the
/// wall-clock budget by tapping Move on the wrong (Old World) fleet first.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 4.
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'support/naval_fleet_move_harness.dart';
import 'support/tap_move_on_first_non_home_fleet_true_group.dart';
import 'support/tap_move_on_first_non_home_fleet_separator_group.dart';

void main() {
  suppressLogsForTests();

  group('e2eTapMoveOnFirstNonHomeFleet — false / no-tap branches', () {
    testWidgets('no naval panel root key in tree -> false', (tester) async {
      await tester.pumpWidget(wrapNavalScrollBody(const SizedBox.shrink()));
      expect(await e2eTapMoveOnFirstNonHomeFleet(tester), isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('panel mounted but no ExpansionTile -> false (post-poll)', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapNavalScrollBody(navalPanelRoot(children: const [Text('loading')])),
      );
      expect(await e2eTapMoveOnFirstNonHomeFleet(tester), isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('single tile is the home fleet -> false (no tap)', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(
            children: [
              ExpansionTile(
                title: const Text('Home Fleet'),
                initiallyExpanded: true,
                children: [
                  FleetMoveButton(
                    buttonKey: kCtE2EFleetMoveActionKey,
                    onPressedSpy: () => taps++,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      expect(await e2eTapMoveOnFirstNonHomeFleet(tester), isFalse);
      expect(taps, 0);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('only tiles without "Fleet " title prefix -> false', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        wrapNavalScrollBody(
          navalPanelRoot(
            children: [
              ExpansionTile(
                title: const Text('Flotilla 7'),
                subtitle: const Text('New World — Outer Sea'),
                initiallyExpanded: true,
                children: [
                  FleetMoveButton(
                    buttonKey: kCtE2EFleetMoveActionKey,
                    onPressedSpy: () => taps++,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      expect(await e2eTapMoveOnFirstNonHomeFleet(tester), isFalse);
      expect(taps, 0);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  registerTapMoveOnFirstNonHomeFleetTrueGroup();
  registerTapMoveOnFirstNonHomeFleetSeparatorGroup();
}
