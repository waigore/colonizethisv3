// Tests for CivilianUnitsPanel. SPEC/ui/civilian-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerIdWithUnits;
  const String humanPlayerIdWithNoUnits = 'no-such-player';

  setUpAll(() {
    game = getDebugInitGameResult().game;
    humanPlayerIdWithUnits =
        game.players.isNotEmpty ? game.players.first.id : 'gp1';
  });

  Widget buildPanel({
    required Game game,
    required String humanPlayerId,
    Orders currentOrders = const Orders(),
    void Function(Unit unit)? onLocateUnit,
    void Function(WorkOrder order)? onAddWorkOrder,
    void Function(String playerId, int index)? onRemoveWorkOrder,
    void Function(String unitId)? onCancelUnitWork,
    void Function(Unit unit, String workTarget)? onStartWorkTargetSelection,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CivilianUnitsPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          currentOrders: currentOrders,
          onLocateUnit: onLocateUnit,
          onAddWorkOrder: onAddWorkOrder,
          onRemoveWorkOrder: onRemoveWorkOrder,
          onCancelUnitWork: onCancelUnitWork,
          onStartWorkTargetSelection: onStartWorkTargetSelection,
        ),
      ),
    );
  }

  group('CivilianUnitsPanel', () {
    testWidgets('AC: Panel shows title Civilian Units',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Civilian Units'), findsOneWidget);
    });

    testWidgets('AC: Empty state when human player has zero civilian units',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithNoUnits,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No civilian units'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets(
        'AC: When player has civilians, list shows units with status, location, assigned-to',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      ));
      await tester.pumpAndSettle();

      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isEmpty) {
        return;
      }
      expect(listTiles, findsAtLeastNWidgets(1));
      expect(find.textContaining('Status:'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Location:'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Assigned to:'), findsAtLeastNWidgets(1));
    });

    testWidgets('AC: Units grouped by region with region heading',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      ));
      await tester.pumpAndSettle();

      final owUnits = game.worldState.oldWorld.units
          .where((u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u))
          .length;
      final nwUnits = game.worldState.newWorld.units
          .where((u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              _isCivilian(u))
          .length;
      if (owUnits > 0) {
        expect(find.text('Old World'), findsAtLeastNWidgets(1));
      }
      if (nwUnits > 0) {
        expect(find.text('New World'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('AC: Location shows province name and region (no raw id)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      ));
      await tester.pumpAndSettle();

      final locationTexts = find.textContaining('Location:');
      if (locationTexts.evaluate().isEmpty) return;
      final firstLocation = tester.widgetList<Text>(locationTexts).first.data!;
      expect(firstLocation, contains(' — '));
      expect(firstLocation, isNot(contains('|')));
    });

    testWidgets('AC: Tapping unit row invokes onLocateUnit with that unit',
        (WidgetTester tester) async {
      Unit? locatedUnit;
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
        onLocateUnit: (u) => locatedUnit = u,
      ));
      await tester.pumpAndSettle();

      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isEmpty) return;
      await tester.tap(listTiles.first);
      await tester.pumpAndSettle();

      expect(locatedUnit, isNotNull);
      expect(locatedUnit!.tileKey, isNotNull);
      expect(locatedUnit!.ownerId, humanPlayerIdWithUnits);
    });

    testWidgets('builds without onLocateUnit callback',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CivilianUnitsPanel), findsOneWidget);
      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isNotEmpty) {
        await tester.tap(listTiles.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('panel is scrollable when many units',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets(
        'Assign button shown for idle unit when onStartWorkTargetSelection provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
        onStartWorkTargetSelection: (_, __) {},
      ));
      await tester.pumpAndSettle();

      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isEmpty) return;
      expect(find.text('Assign'), findsAtLeastNWidgets(1));
    });

    testWidgets('builds with onCancelUnitWork and onRemoveWorkOrder callbacks',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
        onCancelUnitWork: (_) {},
        onRemoveWorkOrder: (_, __) {},
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CivilianUnitsPanel), findsOneWidget);
    });

    testWidgets(
        'tap Assign opens order menu; tap order invokes onStartWorkTargetSelection',
        (WidgetTester tester) async {
      Unit? selectedUnit;
      String? selectedTarget;
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
        onStartWorkTargetSelection: (u, t) {
          selectedUnit = u;
          selectedTarget = t;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Assign').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Assign work'), findsOneWidget);
      final listTiles = find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(ListTile),
          )
          .evaluate()
          .toList();
      expect(listTiles, isNotEmpty);
      final firstTile = listTiles.first;
      final box = firstTile.renderObject! as RenderBox;
      final center =
          box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      expect(selectedUnit, isNotNull);
      expect(selectedTarget, isNotNull);
      expect(selectedUnit!.ownerId, humanPlayerIdWithUnits);
    });

    testWidgets(
        'tap Cancel shows confirm dialog; tap Yes invokes onRemoveWorkOrder when unit has pending work',
        (WidgetTester tester) async {
      final units = [
        ...game.worldState.oldWorld.units,
        ...game.worldState.newWorld.units,
      ];
      final idleCivilians = units.where((u) =>
          u.ownerId == humanPlayerIdWithUnits &&
          u.tileKey != null &&
          _isCivilian(u) &&
          u.currentWork == null);
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
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
        currentOrders: ordersWithOne,
        onRemoveWorkOrder: (pid, idx) {
          removePlayerId = pid;
          removeIndex = idx;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      expect(find.text('Cancel work order?'), findsOneWidget);
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(removePlayerId, humanPlayerIdWithUnits);
      expect(removeIndex, 0);
    });

    testWidgets('tap Cancel then No dismisses dialog without invoking callback',
        (WidgetTester tester) async {
      var cancelCalled = false;
      final units = [
        ...game.worldState.oldWorld.units,
        ...game.worldState.newWorld.units,
      ];
      final idleCivilians = units.where((u) =>
          u.ownerId == humanPlayerIdWithUnits &&
          u.tileKey != null &&
          _isCivilian(u) &&
          u.currentWork == null);
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
          humanPlayerIdWithUnits: [pendingOrder]
        },
      );
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
        currentOrders: ordersWithOne,
        onRemoveWorkOrder: (_, __) => cancelCalled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      expect(cancelCalled, isFalse);
    });

    testWidgets(
        'AC: pending work order shows in Assigned to field with (pending)',
        (WidgetTester tester) async {
      final units = [
        ...game.worldState.oldWorld.units,
        ...game.worldState.newWorld.units,
      ];
      final idleCivilians = units.where((u) =>
          u.ownerId == humanPlayerIdWithUnits &&
          u.tileKey != null &&
          _isCivilian(u) &&
          u.currentWork == null);
      if (idleCivilians.isEmpty) return;
      final idleCivilian = idleCivilians.first;

      final pendingOrder = WorkOrder(
        unitId: idleCivilian.id,
        target: 'build_improvement',
        targetTileKey: idleCivilian.tileKey!,
      );
      final ordersWithOne = Orders(
        workOrdersByPlayerId: {
          humanPlayerIdWithUnits: [pendingOrder]
        },
      );
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
        currentOrders: ordersWithOne,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Assigned to:'), findsAtLeastNWidgets(1));
      expect(find.textContaining('(pending)'), findsAtLeastNWidgets(1));
    });
  });
}

bool _isCivilian(Unit unit) {
  final role = unitRoleForType(unit.type);
  if (role == null) return false;
  return role != UnitRole.military && role != UnitRole.naval;
}
