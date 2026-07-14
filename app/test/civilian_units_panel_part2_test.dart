// Tests for CivilianUnitsPanel. SPEC/ui/civilian-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_circular_locate_button.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_danger_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_sort.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement, kWorkTargetExplore;

import 'support/civilian_units_panel_test_support.dart';

Unit? _firstIdleCivilian(Game game, String humanId) {
  final units = [
    ...game.worldState.oldWorld.units,
    ...game.worldState.newWorld.units,
  ];
  for (final u in units) {
    if (u.ownerId == humanId &&
        u.tileKey != null &&
        isCivilianUnit(u) &&
        u.currentWork == null) {
      return u;
    }
  }
  return null;
}

Orders _pendingExploreOrders(String humanId, Unit unit) {
  final pendingOrder = WorkOrder(
    unitId: unit.id,
    target: kWorkTargetExplore,
    targetTileKey: '${unit.tileKey!.split('|').take(2).join('|')}|0|0',
  );
  return Orders(
    workOrdersByPlayerId: {
      humanId: [pendingOrder],
    },
  );
}

Future<void> _invokePendingCancel(
  WidgetTester tester,
  Unit unit,
) async {
  final pendingRow = find.byKey(
    ValueKey('civilian-unit-card-${unit.id}'),
    skipOffstage: false,
  );
  expect(pendingRow, findsOneWidget);
  final cancelOnPendingRow = find.descendant(
    of: pendingRow,
    matching: find.byType(CtDangerTextButton, skipOffstage: false),
  );
  expect(cancelOnPendingRow, findsOneWidget);
  final cancelBtn = tester.widget<CtDangerTextButton>(cancelOnPendingRow);
  expect(cancelBtn.onPressed, isNotNull);
  cancelBtn.onPressed!();
  await tester.pumpAndSettle();
}

Widget _watcherHost({
  required AppEventBus bus,
  required GlobalKey<NavigatorState> navigatorKey,
  required ValueNotifier<int> counter,
  required String labelPrefix,
  required Game game,
  required String humanId,
  required Orders orders,
}) {
  return ProviderScope(
    overrides: [
      availableWorkTargetIdsForUnitProvider.overrideWith(
        (ref, _) => const <String>[],
      ),
    ],
    child: MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        body: Column(
          children: [
            ValueListenableBuilder<int>(
              valueListenable: counter,
              builder: (_, count, _) => Text('$labelPrefix:$count'),
            ),
            Expanded(
              child: CivilianPanelBusDialogHost(
                bus: bus,
                navigatorKey: navigatorKey,
                child: CivilianUnitsPanel(
                  game: game,
                  humanPlayerId: humanId,
                  currentOrders: orders,
                  bus: bus,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

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
      'AC: per-row locate icon emits LocateMapTileEvent without ClosePanelEvent',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        final miniGame = buildCivilianSingleUnitOwGame(
          id: 'g_civ_locate_icon',
          humanId: human,
          unitId: 'civ1',
          unitType: kUnitTypeBuilder,
          tileKey: tileKey,
        );
        var closeCount = 0;
        LocateMapTileEvent? locateEvent;
        final bus = AppEventBus.create();
        bus.on<ClosePanelEvent>().listen((_) => closeCount++);
        bus.on<LocateMapTileEvent>().listen((e) => locateEvent = e);

        await tester.pumpWidget(
          buildCivilianPanel(game: miniGame, humanPlayerId: human, bus: bus),
        );
        await tester.pumpAndSettle();

        // R30 (#3514): Locate is the rightmost circular CtCircularLocateButton
        // (icon-only) in the action cluster per SPEC/ui/civilian-units-panel.md.
        final locateBtn = find.byType(CtCircularLocateButton);
        expect(locateBtn, findsOneWidget);
        final locatePressed = tester
            .widget<CtCircularLocateButton>(locateBtn.first)
            .onPressed;
        expect(locatePressed, isNotNull);
        locatePressed!();
        await tester.pump();

        expect(closeCount, 0);
        expect(locateEvent, isNotNull);
        expect(locateEvent!.tileKey, tileKey);
        expect(locateEvent!.regionId, 'oldWorld');
      },
    );

    testWidgets(
      'AC: tile-scoped locate icon on non-selected row emits LocateMapTileEvent',
      (WidgetTester tester) async {
        const human = 'h1';
        const tileKey = 'oldWorld|p1|0|0';
        final miniGame = buildCivilianOwUnitsGame(
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
        );
        var closeCount = 0;
        LocateMapTileEvent? locateEvent;
        final bus = AppEventBus.create();
        bus.on<ClosePanelEvent>().listen((_) => closeCount++);
        bus.on<LocateMapTileEvent>().listen((e) => locateEvent = e);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              availableWorkTargetIdsForUnitProvider.overrideWith(
                (ref, _) => const <String>[],
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: CivilianUnitsPanel(
                  game: miniGame,
                  humanPlayerId: human,
                  currentOrders: const Orders(),
                  bus: bus,
                  tileScopeTileKey: tileKey,
                  initialSelectedUnitId: 'civ_a',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // R30 (#3514): every visible row exposes a circular
        // CtCircularLocateButton in the action cluster (per
        // SPEC/ui/civilian-units-panel.md), even rows that are not the
        // tile-scope selection.
        final locateIcons = find.byType(CtCircularLocateButton);
        expect(locateIcons, findsNWidgets(2));
        final locatePressed = tester
            .widget<CtCircularLocateButton>(locateIcons.at(1))
            .onPressed;
        expect(locatePressed, isNotNull);
        locatePressed!();
        await tester.pump();

        expect(closeCount, 0);
        expect(locateEvent, isNotNull);
        expect(locateEvent!.tileKey, tileKey);
        expect(locateEvent!.regionId, 'oldWorld');
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
        final orders = const Orders(
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

        // Work-target menu rows render through InkWell over palette-token
        // chrome (Refs #2914 S8 — no Material ListTile); an enabled row has a
        // non-null onTap.
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
      'Cancel on pending row shows confirm dialog; Yes emits RemovePendingWorkOrderRequestedEvent',
      (WidgetTester tester) async {
        final idleCivilian = _firstIdleCivilian(game, humanPlayerIdWithUnits);
        if (idleCivilian == null) return;

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
            currentOrders: _pendingExploreOrders(
              humanPlayerIdWithUnits,
              idleCivilian,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // R30 (#3514): pending rows expose the destructive Cancel pill
        // (CtDangerTextButton) + circular Locate in the action cluster.
        await _invokePendingCancel(tester, idleCivilian);
        expect(find.text('Cancel work order?'), findsOneWidget);
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(removeEvent, isNotNull);
        expect(removeEvent!.playerId, humanPlayerIdWithUnits);
        expect(removeEvent!.index, 0);
      },
    );

    testWidgets(
      'Cancel on pending row then No dismisses dialog without RemovePendingWorkOrder event',
      (WidgetTester tester) async {
        final idleCivilian = _firstIdleCivilian(game, humanPlayerIdWithUnits);
        if (idleCivilian == null) return;

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
            currentOrders: _pendingExploreOrders(
              humanPlayerIdWithUnits,
              idleCivilian,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _invokePendingCancel(tester, idleCivilian);
        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        expect(removeEvent, isNull);
      },
    );

    testWidgets(
      'pending cancel event can drive external watcher updates (cross-panel style)',
      (WidgetTester tester) async {
        final idleCivilian = _firstIdleCivilian(game, humanPlayerIdWithUnits);
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
          _watcherHost(
            bus: bus,
            navigatorKey: navigatorKey,
            counter: observedRemovals,
            labelPrefix: 'observed-removals',
            game: game,
            humanId: humanPlayerIdWithUnits,
            orders: _pendingExploreOrders(humanPlayerIdWithUnits, idleCivilian),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('observed-removals:0'), findsOneWidget);

        await _invokePendingCancel(tester, idleCivilian);
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
          _watcherHost(
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
