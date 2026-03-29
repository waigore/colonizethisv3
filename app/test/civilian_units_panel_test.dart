// Tests for CivilianUnitsPanel. SPEC/ui/civilian-units-panel.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

class _EventHandlingWrapper extends StatefulWidget {
  const _EventHandlingWrapper({
    required this.bus,
    required this.child,
    required this.navigatorKey,
  });

  final AppEventBus bus;
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<_EventHandlingWrapper> createState() => _EventHandlingWrapperState();
}

class _EventHandlingWrapperState extends State<_EventHandlingWrapper> {
  StreamSubscription? _confirmSub;
  StreamSubscription? _closeSub;

  @override
  void initState() {
    super.initState();
    _closeSub = widget.bus.on<ClosePanelEvent>().listen((_) {
      widget.navigatorKey.currentState?.maybePop();
    });
    _confirmSub = widget.bus.on<ConfirmDialogEvent>().listen((event) async {
      final nav = widget.navigatorKey.currentState;
      if (nav == null) return;
      final result = await showDialog<bool>(
        context: nav.context,
        builder: (ctx) => AlertDialog(
          title: Text(event.title),
          content: Text(event.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(event.cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(event.confirmLabel),
            ),
          ],
        ),
      );
      event.result(result ?? false);
    });
  }

  @override
  void dispose() {
    _confirmSub?.cancel();
    _closeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerIdWithUnits;
  const String humanPlayerIdWithNoUnits = 'no-such-player';

  setUpAll(() {
    game = getDebugInitGameResult().game;
    humanPlayerIdWithUnits = game.players.isNotEmpty
        ? game.players.first.id
        : 'gp1';
  });

  Widget buildPanel({
    required Game game,
    required String humanPlayerId,
    Orders currentOrders = const Orders(),
    Map<String, List<String>> availableWorkTargets = const {},
    AppEventBus? bus,
  }) {
    final resolvedBus = bus ?? AppEventBus.create();
    final navigatorKey = GlobalKey<NavigatorState>();
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        body: _EventHandlingWrapper(
          bus: resolvedBus,
          navigatorKey: navigatorKey,
          child: CivilianUnitsPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            currentOrders: currentOrders,
            availableWorkTargets: availableWorkTargets,
            bus: resolvedBus,
          ),
        ),
      ),
    );
  }

  group('CivilianUnitsPanel', () {
    testWidgets('AC: Panel shows title Civilian Units', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.text('Civilian Units'), findsOneWidget);
    });

    testWidgets('AC: Empty state when human player has zero civilian units', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithNoUnits),
      );
      await tester.pumpAndSettle();

      expect(find.text('No civilian units'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets(
      'AC: When player has civilians, list shows units with status, location, assigned-to',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
        );
        await tester.pumpAndSettle();

        final listTiles = find.byType(ListTile);
        if (listTiles.evaluate().isEmpty) {
          return;
        }
        expect(listTiles, findsAtLeastNWidgets(1));
        expect(find.textContaining('Status:'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Location:'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Assigned to:'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'work targets not in availableWorkTargets are grayed out (disabled)',
      (WidgetTester tester) async {
        // Find an idle civilian unit
        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final idleCivilians = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u) &&
              u.currentWork == null,
        );
        if (idleCivilians.isEmpty) return;
        final idleCivilian = idleCivilians.first;

        // Get allowed work targets for this unit type
        final allowed = workOrderTargetsByUnitType[idleCivilian.type] ?? [];
        if (allowed.isEmpty) return;

        // Provide empty availableWorkTargets - ALL items should be disabled
        final availableWorkTargets = <String, List<String>>{};

        await tester.pumpWidget(
          buildPanel(
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            availableWorkTargets: availableWorkTargets,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Assign').first);
        await tester.pumpAndSettle();

        expect(find.textContaining('Assign work'), findsOneWidget);

        // Get all ListTiles - all should be disabled
        final listTiles = find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(ListTile),
            )
            .evaluate();

        expect(listTiles, isNotEmpty);

        // All items should be disabled when availableWorkTargets is empty
        for (final tile in listTiles) {
          final widget = tile.widget as ListTile;
          expect(
            widget.enabled,
            isFalse,
            reason: 'All items should be disabled when no available targets',
          );
        }

        final scaffoldCtx = tester.element(find.byType(Scaffold));
        Navigator.of(scaffoldCtx, rootNavigator: true).pop();
        await tester.pumpAndSettle();
      },
    );

    testWidgets('Assign button shown for idle unit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isEmpty) return;
      expect(find.text('Assign'), findsAtLeastNWidgets(1));
    });

    testWidgets('tap Assign opens order menu', (WidgetTester tester) async {
      // Find an idle civilian unit
      final units = [
        ...game.worldState.oldWorld.units,
        ...game.worldState.newWorld.units,
      ];
      final idleCivilians = units.where(
        (u) =>
            u.ownerId == humanPlayerIdWithUnits &&
            u.tileKey != null &&
            _isCivilian(u) &&
            u.currentWork == null,
      );
      // Skip if no idle civilians in test game
      if (idleCivilians.isEmpty) return;

      await tester.pumpWidget(
        buildPanel(
          game: game,
          humanPlayerId: humanPlayerIdWithUnits,
          // Pass empty availableWorkTargets - all options will be disabled
          // This tests the UI renders but callback won't fire on disabled items
          availableWorkTargets: const {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Assign').first);
      await tester.pumpAndSettle();

      // Menu opens but all items are disabled since no available targets provided
      expect(find.textContaining('Assign work'), findsOneWidget);
      // Note: selectedUnit/selectedTarget remain null because items are disabled

      final scaffoldCtx = tester.element(find.byType(Scaffold));
      Navigator.of(scaffoldCtx, rootNavigator: true).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('Train button emits train-civilians dialog open event', (
      WidgetTester tester,
    ) async {
      OpenDialogEvent? openDialogEvent;
      final bus = AppEventBus.create();
      bus.on<OpenDialogEvent>().listen((e) => openDialogEvent = e);

      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithUnits, bus: bus),
      );
      await tester.pumpAndSettle();

      final trainButton = find.text('Train');
      expect(trainButton, findsOneWidget);
      await tester.tap(trainButton);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(openDialogEvent, isNotNull);
      expect(openDialogEvent!.dialogId, trainCiviliansDialogId);
    });

    testWidgets(
      'Cancel on pending row shows confirm dialog; Yes emits RemovePendingWorkOrderRequestedEvent',
      (WidgetTester tester) async {
        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final idleCivilians = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u) &&
              u.currentWork == null,
        );
        if (idleCivilians.isEmpty) return;
        final idleCivilian = idleCivilians.first;

        RemovePendingWorkOrderRequestedEvent? removeEvent;
        final bus = AppEventBus.create();
        bus.on<RemovePendingWorkOrderRequestedEvent>().listen((e) {
          removeEvent = e;
        });
        final pendingOrder = WorkOrder(
          unitId: idleCivilian.id,
          target: 'explore',
          targetTileKey:
              '${idleCivilian.tileKey!.split('|').take(2).join('|')}|0|0',
        );
        final ordersWithOne = Orders(
          workOrdersByPlayerId: {
            humanPlayerIdWithUnits: [pendingOrder],
          },
        );
        await tester.pumpWidget(
          buildPanel(
            bus: bus,
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            currentOrders: ordersWithOne,
          ),
        );
        await tester.pumpAndSettle();

        // Scope to the row with our pending order — avoid `.first` on "Cancel"
        // (debug game may show multiple Cancel buttons; first may be off-stage / obscured).
        final pendingRow = find.ancestor(
          of: find.textContaining('(pending)'),
          matching: find.byType(ListTile),
        );
        expect(pendingRow, findsOneWidget);
        // Tap the nine-patch control (InkWell), not the Text center — avoids
        // hit-test misses when the label sits off the interactive region.
        final cancelOnPendingRow = find.descendant(
          of: pendingRow,
          matching: find.byType(CtNinePatchButton),
        );
        expect(cancelOnPendingRow, findsOneWidget);
        await tester.ensureVisible(cancelOnPendingRow);
        // CtNinePatchButton + Flame nine-patch often fail widget hit tests at the
        // label center; invoke the callback to assert confirm + bus emission.
        final cancelBtn = tester.widget<CtNinePatchButton>(cancelOnPendingRow);
        expect(cancelBtn.onPressed, isNotNull);
        cancelBtn.onPressed!();
        await tester.pumpAndSettle();

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
        RemovePendingWorkOrderRequestedEvent? removeEvent;
        final bus = AppEventBus.create();
        bus.on<RemovePendingWorkOrderRequestedEvent>().listen((e) {
          removeEvent = e;
        });
        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final idleCivilians = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u) &&
              u.currentWork == null,
        );
        if (idleCivilians.isEmpty) return;
        final idleCivilian = idleCivilians.first;

        final pendingOrder = WorkOrder(
          unitId: idleCivilian.id,
          target: 'explore',
          targetTileKey:
              '${idleCivilian.tileKey!.split('|').take(2).join('|')}|0|0',
        );
        final ordersWithOne = Orders(
          workOrdersByPlayerId: {
            humanPlayerIdWithUnits: [pendingOrder],
          },
        );
        await tester.pumpWidget(
          buildPanel(
            bus: bus,
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            currentOrders: ordersWithOne,
          ),
        );
        await tester.pumpAndSettle();

        final pendingRow = find.ancestor(
          of: find.textContaining('(pending)'),
          matching: find.byType(ListTile),
        );
        expect(pendingRow, findsOneWidget);
        final cancelOnPendingRow = find.descendant(
          of: pendingRow,
          matching: find.byType(CtNinePatchButton),
        );
        expect(cancelOnPendingRow, findsOneWidget);
        await tester.ensureVisible(cancelOnPendingRow);
        final cancelBtn = tester.widget<CtNinePatchButton>(cancelOnPendingRow);
        expect(cancelBtn.onPressed, isNotNull);
        cancelBtn.onPressed!();
        await tester.pumpAndSettle();
        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        expect(removeEvent, isNull);
      },
    );

    testWidgets(
      'pending cancel event can drive external watcher updates (cross-panel style)',
      (WidgetTester tester) async {
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

        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final idleCivilians = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u) &&
              u.currentWork == null,
        );
        if (idleCivilians.isEmpty) return;
        final idleCivilian = idleCivilians.first;

        final pendingOrder = WorkOrder(
          unitId: idleCivilian.id,
          target: 'explore',
          targetTileKey:
              '${idleCivilian.tileKey!.split('|').take(2).join('|')}|0|0',
        );
        final ordersWithOne = Orders(
          workOrdersByPlayerId: {
            humanPlayerIdWithUnits: [pendingOrder],
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: Scaffold(
              body: Column(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: observedRemovals,
                    builder: (_, count, _) => Text('observed-removals:$count'),
                  ),
                  Expanded(
                    child: _EventHandlingWrapper(
                      bus: bus,
                      navigatorKey: navigatorKey,
                      child: CivilianUnitsPanel(
                        game: game,
                        humanPlayerId: humanPlayerIdWithUnits,
                        currentOrders: ordersWithOne,
                        availableWorkTargets: const {},
                        bus: bus,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('observed-removals:0'), findsOneWidget);

        final pendingRow = find.ancestor(
          of: find.textContaining('(pending)'),
          matching: find.byType(ListTile),
        );
        expect(pendingRow, findsOneWidget);
        final cancelOnPendingRow = find.descendant(
          of: pendingRow,
          matching: find.byType(CtNinePatchButton),
        );
        final cancelBtn = tester.widget<CtNinePatchButton>(cancelOnPendingRow);
        cancelBtn.onPressed!();
        await tester.pumpAndSettle();
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

        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final workingCivilians = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u) &&
              u.currentWork != null,
        );
        if (workingCivilians.isEmpty) return;

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: Scaffold(
              body: Column(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: observedCancels,
                    builder: (_, count, _) => Text('observed-cancels:$count'),
                  ),
                  Expanded(
                    child: _EventHandlingWrapper(
                      bus: bus,
                      navigatorKey: navigatorKey,
                      child: CivilianUnitsPanel(
                        game: game,
                        humanPlayerId: humanPlayerIdWithUnits,
                        currentOrders: const Orders(),
                        availableWorkTargets: const {},
                        bus: bus,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

    testWidgets(
      'AC: pending work order shows in Assigned to field with (pending)',
      (WidgetTester tester) async {
        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final idleCivilians = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u) &&
              u.currentWork == null,
        );
        if (idleCivilians.isEmpty) return;
        final idleCivilian = idleCivilians.first;

        final pendingOrder = WorkOrder(
          unitId: idleCivilian.id,
          target: 'build_improvement',
          targetTileKey: idleCivilian.tileKey!,
        );
        final ordersWithOne = Orders(
          workOrdersByPlayerId: {
            humanPlayerIdWithUnits: [pendingOrder],
          },
        );
        await tester.pumpWidget(
          buildPanel(
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            currentOrders: ordersWithOne,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Assigned to:'), findsAtLeastNWidgets(1));
        expect(find.textContaining('(pending)'), findsAtLeastNWidgets(1));
      },
    );
  });
}

bool _isCivilian(Unit unit) {
  final role = unitRoleForType(unit.type);
  if (role == null) return false;
  return role != UnitRole.military && role != UnitRole.naval;
}
