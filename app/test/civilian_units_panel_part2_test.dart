// Tests for CivilianUnitsPanel. SPEC/ui/civilian-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_circular_locate_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_sort.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement;

import 'civilian_units_panel_part2_cancel_support.dart';
import 'civilian_units_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerIdWithUnits;

  setUpAll(() {
    game = buildCivilianPanelTestGame();
    humanPlayerIdWithUnits = game.players.first.id;
  });

  group('CivilianUnitsPanel', () {
    testWidgets(
      'AC: locate icon emits LocateMapTileEvent (full-list and tile-scoped)',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';

        Future<void> runLocateCase({
          required Widget Function(AppEventBus bus) host,
          required Matcher locateMatcher,
          required int locateIndex,
        }) async {
          var closeCount = 0;
          LocateMapTileEvent? locateEvent;
          final bus = AppEventBus.create();
          bus.on<ClosePanelEvent>().listen((_) => closeCount++);
          bus.on<LocateMapTileEvent>().listen((e) => locateEvent = e);
          await tester.pumpWidget(host(bus));
          await tester.pumpAndSettle();
          final locateIcons = find.byType(CtCircularLocateButton);
          expect(locateIcons, locateMatcher);
          final locatePressed = tester
              .widget<CtCircularLocateButton>(locateIcons.at(locateIndex))
              .onPressed;
          expect(locatePressed, isNotNull);
          locatePressed!();
          await tester.pump();
          expect(closeCount, 0);
          expect(locateEvent, isNotNull);
          expect(locateEvent!.tileKey, tileKey);
          expect(locateEvent!.regionId, 'oldWorld');
        }

        await runLocateCase(
          host: (bus) => buildCivilianPanel(
            game: buildCivilianSingleUnitOwGame(
              id: 'g_civ_locate_icon',
              humanId: human,
              unitId: 'civ1',
              unitType: kUnitTypeBuilder,
              tileKey: tileKey,
            ),
            humanPlayerId: human,
            bus: bus,
          ),
          locateMatcher: findsOneWidget,
          locateIndex: 0,
        );

        await runLocateCase(
          host: (bus) => buildCivilianPanel(
            game: buildCivilianOwUnitsGame(
              id: 'g_civ_locate_tile_scope',
              humanId: human,
              units: [
                civilianIdleUnit(
                  id: 'civ_a',
                  type: kUnitTypeBuilder,
                  ownerId: human,
                  provinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
                civilianIdleUnit(
                  id: 'civ_b',
                  type: kUnitTypeEngineer,
                  ownerId: human,
                  provinceId: 'oldWorld|p1',
                  tileKey: tileKey,
                ),
              ],
            ),
            humanPlayerId: human,
            bus: bus,
            tileScopeTileKey: tileKey,
            initialSelectedUnitId: 'civ_a',
          ),
          locateMatcher: findsNWidgets(2),
          locateIndex: 1,
        );
      },
    );

    testWidgets(
      'uses pending target tile for Location and locate event in full-list mode',
      (WidgetTester tester) async {
        const human = 'gp1';
        const standingTile = 'oldWorld|p1|0|0';
        const pendingTile = 'oldWorld|p2|0|0';
        final gameWithPending = buildCivilianPendingProjectionGame(
          humanId: human,
          standingTile: standingTile,
        );
        const orders = Orders(
          workOrdersByPlayerId: {
            human: [
              WorkOrder(
                unitId: 'u1',
                target: kWorkTargetBuildImprovement,
                targetTileKey: pendingTile,
              ),
            ],
          },
        );
        LocateMapTileEvent? locateEvent;
        final bus = AppEventBus.create();
        bus.on<LocateMapTileEvent>().listen((e) => locateEvent = e);

        await tester.pumpWidget(
          buildCivilianPanel(
            game: gameWithPending,
            humanPlayerId: human,
            currentOrders: orders,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Location: Old World — Beta'),
          findsOneWidget,
        );
        await tester.tap(find.byType(CivilianUnitRowCard).first);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(locateEvent, isNotNull);
        expect(locateEvent!.tileKey, pendingTile);
      },
    );

    testWidgets(
      'AC: assign target emits ClosePanelEvent before StartCivilianWorkTargetSelectionEvent',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final sequence = <Type>[];
        bus.stream.listen((e) => sequence.add(e.runtimeType));

        final idleCivilians = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ].where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              isCivilianUnit(u) &&
              u.currentWork == null,
        );
        if (idleCivilians.isEmpty) return;

        final availableWorkTargets = <String, List<String>>{};
        for (final u in idleCivilians) {
          final allowed =
              workOrderTargetsByUnitType[u.type] ?? const <String>[];
          if (allowed.isNotEmpty) {
            availableWorkTargets[u.id] = [allowed.first];
          }
        }
        if (availableWorkTargets.isEmpty) return;

        await tester.pumpWidget(
          buildCivilianPanel(
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            bus: bus,
            availableWorkTargets: availableWorkTargets,
          ),
        );
        await tester.pumpAndSettle();

        final assignButton = find.text('Assign');
        if (assignButton.evaluate().isEmpty) return;
        await tester.tap(assignButton.first);
        await tester.pumpAndSettle();

        final enabledTargetRow = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byWidgetPredicate(
            (w) => w is InkWell && w.onTap != null,
          ),
        );
        if (enabledTargetRow.evaluate().isEmpty) return;
        final targetRow = tester.widget<InkWell>(enabledTargetRow.first);
        expect(targetRow.onTap, isNotNull);
        targetRow.onTap!();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          sequence.indexOf(ClosePanelEvent),
          lessThan(sequence.indexOf(StartCivilianWorkTargetSelectionEvent)),
        );
      },
    );

    testWidgets(
      'Cancel on pending row: Yes removes order; No dismisses without remove',
      (WidgetTester tester) async {
        final idleCivilian = firstIdleCivilian(game, humanPlayerIdWithUnits);
        if (idleCivilian == null) return;

        Future<RemovePendingWorkOrderRequestedEvent?> confirmPending(
          String answer,
        ) async {
          RemovePendingWorkOrderRequestedEvent? removeEvent;
          final bus = AppEventBus.create();
          bus.on<RemovePendingWorkOrderRequestedEvent>().listen((e) {
            removeEvent = e;
          });
          await tester.pumpWidget(
            buildCivilianPanel(
              bus: bus,
              game: game,
              humanPlayerId: humanPlayerIdWithUnits,
              currentOrders: pendingExploreOrders(
                humanPlayerIdWithUnits,
                idleCivilian,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await invokePendingCancel(tester, idleCivilian);
          expect(find.text('Cancel work order?'), findsOneWidget);
          await tester.tap(find.text(answer));
          await tester.pumpAndSettle();
          return removeEvent;
        }

        final removed = await confirmPending('Yes');
        expect(removed, isNotNull);
        expect(removed!.playerId, humanPlayerIdWithUnits);
        expect(removed.index, 0);

        expect(await confirmPending('No'), isNull);
      },
    );

    testWidgets(
      'pending cancel event can drive external watcher updates (cross-panel style)',
      (WidgetTester tester) async {
        final idleCivilian = firstIdleCivilian(game, humanPlayerIdWithUnits);
        if (idleCivilian == null) return;

        final bus = AppEventBus.create();
        final navigatorKey = GlobalKey<NavigatorState>();
        final observedRemovals = ValueNotifier<int>(0);
        final sub = bus.on<RemovePendingWorkOrderRequestedEvent>().listen((_) {
          observedRemovals.value = observedRemovals.value + 1;
        });
        addTearDown(() async {
          await sub.cancel();
          observedRemovals.dispose();
        });

        await tester.pumpWidget(
          civilianPanelWatcherHost(
            bus: bus,
            navigatorKey: navigatorKey,
            counter: observedRemovals,
            labelPrefix: 'observed-removals',
            game: game,
            humanId: humanPlayerIdWithUnits,
            orders: pendingExploreOrders(humanPlayerIdWithUnits, idleCivilian),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('observed-removals:0'), findsOneWidget);

        await invokePendingCancel(tester, idleCivilian);
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(find.text('observed-removals:1'), findsOneWidget);
      },
    );

    testWidgets(
      'in-progress cancel event can drive external watcher updates (cross-panel style)',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final navigatorKey = GlobalKey<NavigatorState>();
        final observedCancels = ValueNotifier<int>(0);
        final sub = bus.on<CancelInProgressCivilianWorkRequestedEvent>().listen(
          (_) {
            observedCancels.value = observedCancels.value + 1;
          },
        );
        addTearDown(() async {
          await sub.cancel();
          observedCancels.dispose();
        });

        final workingCivilians = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ].where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              isCivilianUnit(u) &&
              u.currentWork != null,
        );
        if (workingCivilians.isEmpty) return;

        await tester.pumpWidget(
          civilianPanelWatcherHost(
            bus: bus,
            navigatorKey: navigatorKey,
            counter: observedCancels,
            labelPrefix: 'observed-cancels',
            game: game,
            humanId: humanPlayerIdWithUnits,
            orders: const Orders(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('observed-cancels:0'), findsOneWidget);

        final cancelButtons = find.text('Cancel');
        if (cancelButtons.evaluate().isEmpty) return;
        await tester.tap(cancelButtons.first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(find.text('observed-cancels:1'), findsOneWidget);
      },
    );
  });
}
