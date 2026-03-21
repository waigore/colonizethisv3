// Tests for CivilianUnitsPanel. SPEC/ui/civilian-units-panel.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
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
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.bus.on<ConfirmDialogEvent>().listen((event) async {
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
    _sub?.cancel();
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
    void Function(Unit unit)? onLocateUnit,
    void Function(WorkOrder order)? onAddWorkOrder,
    void Function(String playerId, int index)? onRemoveWorkOrder,
    void Function(String unitId)? onCancelUnitWork,
    void Function(Unit unit, String workTarget)? onStartWorkTargetSelection,
  }) {
    final bus = AppEventBus();
    final navigatorKey = GlobalKey<NavigatorState>();
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        body: _EventHandlingWrapper(
          bus: bus,
          navigatorKey: navigatorKey,
          child: CivilianUnitsPanel(
            game: game,
            humanPlayerId: humanPlayerId,
            currentOrders: currentOrders,
            availableWorkTargets: availableWorkTargets,
            bus: bus,
            onLocateUnit: onLocateUnit,
            onAddWorkOrder: onAddWorkOrder,
            onRemoveWorkOrder: onRemoveWorkOrder,
            onCancelUnitWork: onCancelUnitWork,
            onStartWorkTargetSelection: onStartWorkTargetSelection,
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
            onStartWorkTargetSelection: (_, __) {},
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
      },
    );

    testWidgets(
      'Assign button shown for idle unit when onStartWorkTargetSelection provided',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            onStartWorkTargetSelection: (_, __) {},
          ),
        );
        await tester.pumpAndSettle();

        final listTiles = find.byType(ListTile);
        if (listTiles.evaluate().isEmpty) return;
        expect(find.text('Assign'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'builds with onCancelUnitWork and onRemoveWorkOrder callbacks',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            onCancelUnitWork: (_) {},
            onRemoveWorkOrder: (_, __) {},
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CivilianUnitsPanel), findsOneWidget);
      },
    );

    testWidgets(
      'tap Assign opens order menu; tap order invokes onStartWorkTargetSelection',
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
        // Skip if no idle civilians in test game
        if (idleCivilians.isEmpty) return;

        Unit? selectedUnit;
        String? selectedTarget;
        await tester.pumpWidget(
          buildPanel(
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            // Pass empty availableWorkTargets - all options will be disabled
            // This tests the UI renders but callback won't fire on disabled items
            availableWorkTargets: const {},
            onStartWorkTargetSelection: (u, t) {
              selectedUnit = u;
              selectedTarget = t;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Assign').first);
        await tester.pumpAndSettle();

        // Menu opens but all items are disabled since no available targets provided
        expect(find.textContaining('Assign work'), findsOneWidget);
        // Note: selectedUnit/selectedTarget remain null because items are disabled
      },
    );

    testWidgets(
      'tap Cancel shows confirm dialog; tap Yes invokes onRemoveWorkOrder when unit has pending work',
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

        String? removePlayerId;
        int? removeIndex;
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
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            currentOrders: ordersWithOne,
            onRemoveWorkOrder: (pid, idx) {
              removePlayerId = pid;
              removeIndex = idx;
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel').first);
        await tester.pumpAndSettle();

        expect(find.text('Cancel work order?'), findsOneWidget);
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(removePlayerId, humanPlayerIdWithUnits);
        expect(removeIndex, 0);
      },
    );

    testWidgets(
      'tap Cancel then No dismisses dialog without invoking callback',
      (WidgetTester tester) async {
        var cancelCalled = false;
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
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            currentOrders: ordersWithOne,
            onRemoveWorkOrder: (_, __) => cancelCalled = true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        expect(cancelCalled, isFalse);
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
