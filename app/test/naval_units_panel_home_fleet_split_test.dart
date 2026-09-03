// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.
// Concern split under repo.app_test_file_size (Refs #4013, #4352):
// Home Fleet, split, autoclose, and move pins.

import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';

import 'naval_panel_part1_pins.dart';
import 'naval_units_panel_test_support.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Game game;
  late String humanPlayerIdWithFleets;

  setUpAll(() async {
    await setUpNinePatchAssets();
    game = buildNavalPanelTestGame();
    humanPlayerIdWithFleets = game.players.isNotEmpty
        ? game.players.first.id
        : kPanelTestHumanPlayerId;
  });

  group('NavalUnitsPanel', () {
    testWidgets(
      'AC: Missing Home Fleet entity does not render synthetic Home Fleet row',
      (WidgetTester tester) async {
        final (bus, events) = wireNavalLocateCaptureBus();
        await pumpNavalPanel(
          tester,
          game: withoutNavalPanelCapitalHomeFleets(
            game,
            humanPlayerIdWithFleets,
          ),
          humanPlayerId: humanPlayerIdWithFleets,
          bus: bus,
        );
        expect(navalFleetTileFinder('Home Fleet'), findsNothing);
        expect(events, isEmpty);
      },
    );

    testWidgets(
      'AC: Home Fleet row has checkbox; Split shown; Combine stays in header only',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;
        await pumpNavalPanel(tester, game: game, humanPlayerId: humanId);
        final home = navalFleetTileFinder('Home Fleet');
        expect(home, findsOneWidget);
        expect(
          find.descendant(of: home, matching: find.byType(Checkbox)),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(CtActionTextButton, 'Combine'),
          findsOneWidget,
        );
        await expandAndExpectNavalSplit(tester, home);
        expect(
          find.descendant(
            of: home,
            matching: find.widgetWithText(CtActionTextButton, 'Combine'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AC: Split on home/non-home opens Split Fleet dialog; non-home shows Split',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;
        final homeId = homeFleetIdFor(humanId);
        final nonHome = game.worldState.fleets.firstWhere(
          (f) =>
              f.ownerId == humanId &&
              f.shipTypeIds.isNotEmpty &&
              f.id != homeId,
        );
        await pumpNavalPanel(tester, game: game, humanPlayerId: humanId);
        final home = navalFleetTileFinder('Home Fleet');
        await expandAndTapNavalSplit(tester, home);
        expect(find.text('Split Fleet'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        final nonHomeFinder = navalFleetTileFinder(
          navalFleetTileLabel(nonHome, humanId),
        );
        await expandAndExpectNavalSplit(tester, nonHomeFinder);
        await expandAndTapNavalSplit(tester, nonHomeFinder);
        expect(find.text('Split Fleet'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: NavalFleetsUpdatedEvent is emitted when fleet split completes',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;
        final (bus, latest) = wireNavalSplitUpdatedBus(
          gameSnapshot: () => game,
        );
        final targetFleet = game.worldState.fleets.firstWhere(
          (f) => f.ownerId == humanId && f.shipTypeIds.length >= 2,
        );
        await pumpNavalPanel(
          tester,
          game: game,
          humanPlayerId: humanId,
          bus: bus,
        );
        final fleet = navalFleetTileFinder(
          navalFleetTileLabel(targetFleet, humanId),
        );
        await expandAndTapNavalSplit(tester, fleet);
        await confirmNavalSplitMovingFirstShip(tester, targetFleet);
        expect(latest(), isNotNull);
        expect(latest()!.game.worldState.fleets, isNotEmpty);
      },
    );

    testWidgets(
      'split event can drive external watcher updates (cross-panel style)',
      (WidgetTester tester) async {
        await pumpNavalSplitWatcherPin(
          tester,
          game: game,
          humanId: humanPlayerIdWithFleets,
        );
      },
    );

    testWidgets('AC: scoped auto-close emits only when move empties scope', (
      WidgetTester tester,
    ) async {
      for (final case_ in navalPanelAutocloseCases()) {
        await pumpNavalAutocloseScenario(tester, case_);
      }
    });

    testWidgets(
      'AC: Move/narrow actions — Home no Move; non-home opens dialog',
      (WidgetTester tester) async {
        await pumpNavalMoveAndNarrowActionsPin(
          tester,
          game: game,
          humanPlayerIdWithFleets: humanPlayerIdWithFleets,
        );
      },
    );

    testWidgets(
      'AC: Home Fleet is never deleted even when empty after combine',
      pumpNavalHomeNeverDeletedPin,
    );

    testWidgets(
      'AC: Non-Home fleet split cannot empty original (Confirm Split disabled)',
      pumpNavalNonHomeSplitEmptyBlockedPin,
    );
  });
}
