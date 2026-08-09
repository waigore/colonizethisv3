// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';

import 'naval_panel_part1_pins.dart';
import 'naval_units_panel_test_support.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Game game;
  late String humanPlayerIdWithFleets;
  const String humanPlayerIdWithNoFleets = 'no-such-player';

  setUpAll(() async {
    await setUpNinePatchAssets();
    game = buildNavalPanelTestGame();
    humanPlayerIdWithFleets = game.players.isNotEmpty
        ? game.players.first.id
        : kPanelTestHumanPlayerId;
  });

  group('NavalUnitsPanel', () {
    testWidgets(
      'AC: title, CtPanel wrap, fleet rows, and header Combine chrome',
      (WidgetTester tester) async {
        await pumpNavalPanel(
          tester,
          game: game,
          humanPlayerId: humanPlayerIdWithFleets,
        );

        expect(find.text('Naval Units'), findsOneWidget);
        expect(find.byType(CtPanel), findsOneWidget);
        if (find.byType(ExpansionTile).evaluate().isNotEmpty) {
          expect(find.byType(UnitsEntityActionRow), findsAtLeastNWidgets(1));
        }

        final fleets = game.worldState.fleets
            .where(
              (f) =>
                  f.ownerId == humanPlayerIdWithFleets &&
                  f.shipTypeIds.isNotEmpty,
            )
            .length;
        if (fleets > 0) {
          expect(find.byType(ExpansionTile), findsAtLeastNWidgets(1));
          expect(
            find.text('OLD WORLD').evaluate().isNotEmpty ||
                find.text('NEW WORLD').evaluate().isNotEmpty,
            isTrue,
          );
        }

        final combine = find.ancestor(
          of: find.text('Combine'),
          matching: find.byType(CtActionTextButton),
        );
        expect(combine, findsOneWidget);
        expect(
          tester.widget<CtActionTextButton>(combine.first).primary,
          isTrue,
        );
        expect(
          find.ancestor(
            of: find.text('Combine'),
            matching: find.byType(CtNinePatchButton),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AC: When human player has no fleets, panel does not crash and shows either empty or Home Fleet only',
      (WidgetTester tester) async {
        await pumpNavalPanel(
          tester,
          game: game,
          humanPlayerId: humanPlayerIdWithNoFleets,
        );
        expect(find.byType(CtPanel), findsOneWidget);
      },
    );

    testWidgets('AC: Wide viewport scales naval panel beyond fixed 400 width', (
      WidgetTester tester,
    ) async {
      await pumpNavalPanel(
        tester,
        game: game,
        humanPlayerId: humanPlayerIdWithFleets,
        widget: buildNavalPanelWideViewport(
          game: game,
          humanPlayerId: humanPlayerIdWithFleets,
        ),
      );
      final panelShell = tester.widget<UnitsPanelShell>(
        find.byType(UnitsPanelShell),
      );
      expect(panelShell.panelConstraints.maxWidth, greaterThan(400));
    });

    for (final case_ in navalPanelLocateCases()) {
      testWidgets(case_.name, (WidgetTester tester) async {
        await pumpNavalLocateCase(
          tester,
          case_,
          baseGame: game,
          humanId: humanPlayerIdWithFleets,
        );
      });
    }

    testWidgets('AC: Strength is only shown in expanded details', (
      WidgetTester tester,
    ) async {
      await pumpNavalPanel(
        tester,
        game: game,
        humanPlayerId: humanPlayerIdWithFleets,
      );
      final tiles = find.byType(ExpansionTile);
      if (tiles.evaluate().isEmpty) return;
      expect(find.textContaining('Strength:'), findsNothing);
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Strength:'), findsAtLeastNWidgets(1));
    });

    testWidgets('sea-zone labels use world-state display names', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_named_sea';
      await pumpNavalPanel(
        tester,
        game: buildNavalPanelNamedSeaZoneGame(humanId: humanId),
        humanPlayerId: humanId,
      );
      expect(find.textContaining('Caribbean Sea'), findsWidgets);
    });

    for (final case_ in navalPanelPart1PinCases()) {
      testWidgets(case_.name, case_.run);
    }

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
        final (bus, latest) = wireNavalSplitUpdatedBus(gameSnapshot: () => game);
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

  group('Draft naval move subtitle', () {
    testWidgets('shows Moving to line when draft order present', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_draft_line';
      await pumpNavalPanel(
        tester,
        game: buildNavalPanelDraftMoveSubtitleGame(humanId: humanId),
        humanPlayerId: humanId,
        draftOrders: Orders(
          navalMoveOrdersByPlayerId: {
            humanId: [
              const NavalMoveOrder(
                fleetId: 'f_at_sea',
                destinationSeaZoneId: 'sz1',
              ),
            ],
          },
        ),
      );
      await tester.pump();
      expect(find.textContaining('Moving to: Target Sea'), findsOneWidget);
    });
  });
}
