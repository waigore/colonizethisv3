// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart'
    show kCtE2EFleetMissionActionKey;
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import 'naval_units_panel_locate_pins.dart';
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
    // Full fixture (home + non-home fleets, both regions) so locate / Split
    // cases are non-vacuous. Refs #4013 densify of part1.
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
      final namedSeaGame = buildNavalPanelNamedSeaZoneGame(humanId: humanId);
      await pumpNavalPanel(tester, game: namedSeaGame, humanPlayerId: humanId);
      expect(find.textContaining('Caribbean Sea'), findsWidgets);
    });

    testWidgets(
      'AC: expanded composition lists ship display names not raw ids',
      (WidgetTester tester) async {
        const humanId = 'gp_ship_display';
        final shipLabelGame = buildNavalPanelCapitalHomeAndPeersGame(
          humanId: humanId,
          gameId: 'g_ship_labels',
          displayName: 'Ship Label Tester',
          peerFleets: const [],
          homeShips: const [ShipInstance(id: 'h1', typeId: 'carrack')],
        );

        await pumpNavalPanel(
          tester,
          game: shipLabelGame,
          humanPlayerId: humanId,
        );

        final homeTile = navalFleetTileFinder('Home Fleet');
        expect(homeTile, findsOneWidget);
        await expandNavalFleetTile(tester, homeTile);
        expect(find.text('Carrack'), findsOneWidget);
        expect(find.text('×1'), findsAtLeastNWidgets(1));
        expect(find.textContaining('carrack:'), findsNothing);
      },
    );

    testWidgets(
      'AC: Missing Home Fleet entity does not render synthetic Home Fleet row',
      (WidgetTester tester) async {
        final (bus, events) = wireNavalLocateCaptureBus();

        final gameWithoutHome = withoutNavalPanelCapitalHomeFleets(
          game,
          humanPlayerIdWithFleets,
        );

        await pumpNavalPanel(
          tester,
          game: gameWithoutHome,
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
        expect(home, findsOneWidget);
        await expandAndTapNavalSplit(tester, home);
        expect(find.text('Split Fleet'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        final nonHomeFinder = navalFleetTileFinder(navalFleetTileLabel(nonHome, humanId));
        expect(nonHomeFinder, findsOneWidget);
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
        final fleet = navalFleetTileFinder(navalFleetTileLabel(targetFleet, humanId));
        expect(fleet, findsOneWidget);
        await expandAndTapNavalSplit(tester, fleet);
        await confirmNavalSplitMovingFirstShip(tester, targetFleet);
        expect(latest(), isNotNull);
        expect(latest()!.game.worldState.fleets, isNotEmpty);
      },
    );

    testWidgets(
      'split event can drive external watcher updates (cross-panel style)',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;
        final observedFleetCount = ValueNotifier<int>(
          game.worldState.fleets.length,
        );
        final bus = AppEventBus.create();
        final sub = bus.on<NavalFleetsUpdatedEvent>().listen((e) {
          observedFleetCount.value = e.game.worldState.fleets.length;
        });
        final subSplit = wireNavalSplitForWidgetTest(
          bus: bus,
          gameSnapshot: () => game,
        );
        addTearDown(() async {
          await sub.cancel();
          await subSplit.cancel();
          observedFleetCount.dispose();
        });

        final targetFleet = game.worldState.fleets.firstWhere(
          (f) => f.ownerId == humanId && f.shipTypeIds.length >= 2,
        );
        await pumpNavalPanel(
          tester,
          game: game,
          humanPlayerId: humanPlayerIdWithFleets,
          widget: buildNavalPanelWithFleetCountWatcher(
            game: game,
            humanPlayerId: humanId,
            bus: bus,
            observedFleetCount: observedFleetCount,
          ),
        );
        expect(
          find.text('observed-fleet-count:${game.worldState.fleets.length}'),
          findsOneWidget,
        );
        final fleet = navalFleetTileFinder(navalFleetTileLabel(targetFleet, humanId));
        expect(fleet, findsOneWidget);
        await expandAndTapNavalSplit(tester, fleet);
        await confirmNavalSplitMovingFirstShip(tester, targetFleet);
        expect(
          find.text(
            'observed-fleet-count:${game.worldState.fleets.length + 1}',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('AC: Beachhead status and empty-naval empty-state pins', (
      WidgetTester tester,
    ) async {
      await pumpNavalPanel(
        tester,
        game: buildNavalPanelBeachheadMissionGame(humanId: 'p_beach'),
        humanPlayerId: 'p_beach',
      );
      expect(find.textContaining('Beachhead'), findsWidgets);

      await pumpNavalPanel(
        tester,
        game: buildNavalPanelEmptyHumanGame(humanId: 'p_empty'),
        humanPlayerId: 'p_empty',
      );
      expect(find.text('No naval units'), findsOneWidget);
    });

    testWidgets(
      'AC: Marker-scoped capital port view shows Home Fleet and not empty state',
      (WidgetTester tester) async {
        const humanId = 'gp_marker_scope';
        const capital = 'oldWorld|p1';
        await pumpNavalPanel(
          tester,
          game: buildNavalPanelMarkerScopeCapitalGame(humanId: humanId),
          humanPlayerId: humanId,
          locationScopeKey: 'port:$capital',
        );
        expect(
          find.widgetWithText(ExpansionTile, 'Home Fleet'),
          findsOneWidget,
        );
        expect(find.text('No naval units'), findsNothing);
      },
    );

    testWidgets(
      'AC: Cross-region projected marker scope shows destination region rows',
      (WidgetTester tester) async {
        const humanId = 'gp_cross_region_scope';
        await pumpNavalPanel(
          tester,
          game: buildNavalPanelSingleSeaFleetGame(
            humanId: humanId,
            gameId: 'g_cross_region_scope',
            displayName: 'Cross Scope',
          ),
          humanPlayerId: humanId,
          topology: buildNavalTwoSeaZonesTopology(
            fromZoneId: 'oldWorld|s1',
            toZoneId: 'newWorld|s2',
          ),
          draftOrders: const Orders(
            navalMoveOrdersByPlayerId: {
              humanId: [
                NavalMoveOrder(
                  fleetId: 'f1',
                  destinationSeaZoneId: 'newWorld|s2',
                ),
              ],
            },
          ),
          locationScopeKey: 'sea:newWorld|s2',
        );
        expect(find.text('NEW WORLD'), findsOneWidget);
        expect(find.text('OLD WORLD'), findsNothing);
        expect(find.textContaining('Fleet f1'), findsOneWidget);
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
        const homeId = 'gp_move_home';
        await pumpNavalPanel(
          tester,
          game: buildNavalPanelCapitalHomeAndPeersGame(
            humanId: homeId,
            gameId: 'g_move_home',
            displayName: 'Move Home Test',
            peerFleets: const [],
            homeShips: const [ShipInstance(id: 'home_ship', typeId: 'carrack')],
          ),
          humanPlayerId: homeId,
        );
        expect(
          find.descendant(
            of: find.widgetWithText(ExpansionTile, 'Home Fleet'),
            matching: find.byTooltip('Move'),
          ),
          findsNothing,
        );

        final humanId = humanPlayerIdWithFleets;
        final nonHomeFleets = navalNonHomeFleetsWithShips(game, humanId);
        if (nonHomeFleets.isEmpty) return;
        final fleetTile = find.widgetWithText(
          ExpansionTile,
          'Fleet ${nonHomeFleets.first.id}',
        );

        await pumpNavalPanel(tester, game: game, humanPlayerId: humanId);
        expect(fleetTile, findsOneWidget);
        await tester.ensureVisible(fleetTile);
        final moveButton = find.descendant(
          of: fleetTile,
          matching: find.byTooltip('Move'),
        );
        expect(moveButton, findsOneWidget);
        await tester.ensureVisible(moveButton);
        await tester.tap(moveButton);
        await tester.pumpAndSettle();
        expect(find.byType(MoveFleetDialog), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(320, 800));
        await pumpNavalPanel(tester, game: game, humanPlayerId: humanId);
        expect(fleetTile, findsOneWidget);
        expect(
          find.descendant(of: fleetTile, matching: find.byIcon(Icons.route)),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: fleetTile,
            matching: find.byKey(kCtE2EFleetMissionActionKey),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: fleetTile,
            matching: find.byIcon(Icons.call_split),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: fleetTile, matching: find.text('Move')),
          findsNothing,
        );
        expect(
          find.descendant(of: fleetTile, matching: find.text('Mission')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AC: Home Fleet is never deleted even when empty after combine',
      (WidgetTester tester) async {
        const humanId = 'gp_home_never_deleted';
        final homeId = homeFleetIdFor(humanId);
        final g = buildNavalPanelCapitalHomeAndPeersGame(
          humanId: humanId,
          gameId: 'g_home_never_deleted',
          displayName: 'Home never deleted tester',
          nextShipInstanceSeq: 3,
          peerFleets: [
            navalPanelPortPeer(
              id: 'donor',
              humanId: humanId,
              ships: const [ShipInstance(id: 'ship_d', typeId: 'fluyte')],
            ),
          ],
        );
        final updated = await pumpNavalHomeFleetTransferAll(
          tester,
          game: g,
          humanId: humanId,
          fleetLabels: const ['Home Fleet', 'Fleet donor'],
          transferTypeId: 'fluyte',
        );
        final fleets = updated!.game.worldState.fleets;
        expect(fleets.where((f) => f.id == homeId), isNotEmpty);
        expect(
          (fleets.firstWhere((f) => f.id == homeId).ships.map((s) => s.id).toList()
                ..sort()),
          ['home_1', 'ship_d'],
        );
        expect(fleets.any((f) => f.id == 'donor'), isFalse);
      },
    );

    testWidgets(
      'AC: Non-Home fleet split cannot empty original (Confirm Split disabled)',
      (WidgetTester tester) async {
        const humanId = 'gp_nonhome_removed';
        final g = buildNavalPanelCapitalHomeAndPeersGame(
          humanId: humanId,
          gameId: 'g_nonhome_removed',
          displayName: 'Non-home removed tester',
          nextShipInstanceSeq: 3,
          peerFleets: [
            navalPanelPortPeer(
              id: 'split_me',
              humanId: humanId,
              ships: const [ShipInstance(id: 'ship_s1', typeId: 'fluyte')],
            ),
          ],
        );
        final (bus, updated) = wireNavalFleetBusWithWire(
          wire: (b) => wireNavalSplitForWidgetTest(bus: b, gameSnapshot: () => g),
        );
        await pumpNavalPanel(tester, game: g, humanPlayerId: humanId, bus: bus);
        final fleetTile = find.widgetWithText(ExpansionTile, 'Fleet split_me');
        await expandAndTapNavalSplit(tester, fleetTile);
        final typeId = g.worldState.fleets
            .firstWhere((f) => f.id == 'split_me')
            .ships
            .single
            .typeId;
        await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne(typeId)));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<CtNinePatchButton>(
                find.widgetWithText(CtNinePatchButton, 'Confirm Split'),
              )
              .enabled,
          isFalse,
        );
        expect(updated(), isNull);
      },
    );
  });

  group('Draft naval move subtitle', () {
    testWidgets('shows Moving to line when draft order present', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_draft_line';
      final draftGame = buildNavalPanelDraftMoveSubtitleGame(humanId: humanId);
      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          humanId: [
            const NavalMoveOrder(
              fleetId: 'f_at_sea',
              destinationSeaZoneId: 'sz1',
            ),
          ],
        },
      );

      await tester.pumpWidget(
        buildNavalPanel(
          game: draftGame,
          humanPlayerId: humanId,
          draftOrders: orders,
        ),
      );
      await tester.pump();

      expect(find.textContaining('Moving to: Target Sea'), findsOneWidget);
    });
  });
}
