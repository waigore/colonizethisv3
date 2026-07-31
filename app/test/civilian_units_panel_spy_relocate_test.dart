// Spy Relocate row actions and status labels (Refs #4219).
// SPEC: SPEC/ui/civilian-units-panel.md, SPEC/ui/ux-design-decisions.md UXD-002.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show kUnitTypeExplorer;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';

import 'civilian_units_panel_test_support.dart';

const _human = 'h1';

void main() {
  suppressLogsForTests();

  group('CivilianUnitsPanel Spy relocate (Refs #4219)', () {
    testWidgets('idle Spy in owned province shows Relocate and Reserve status', (
      WidgetTester tester,
    ) async {
      final game = buildCivilianSpyFixtureGame(id: 'g_spy_reserve');
      await tester.pumpWidget(
        buildCivilianPanel(game: game, humanPlayerId: _human),
      );
      await tester.pumpAndSettle();

      expect(find.text('Relocate'), findsOneWidget);
      expect(find.textContaining('Status: Reserve'), findsOneWidget);
      expect(find.text('Assign'), findsOneWidget);
    });

    testWidgets(
      'idle Spy in foreign province shows Holding intel status',
      (WidgetTester tester) async {
        final game = buildCivilianSpyFixtureGame(
          id: 'g_spy_foreign',
          foreignStation: true,
        );
        await tester.pumpWidget(
          buildCivilianPanel(game: game, humanPlayerId: _human),
        );
        await tester.pumpAndSettle();

        expect(find.text('Relocate'), findsOneWidget);
        expect(find.textContaining('Holding intel:'), findsOneWidget);
      },
    );

    testWidgets(
      'Spy with pending counter-spy shows Counter-espionage status',
      (WidgetTester tester) async {
        const spyId = 'spy1';
        const homeTile = 'oldWorld|p1|0|0';
        final game = buildCivilianSpyFixtureGame(id: 'g_spy_counter');
        final orders = civilianSpyPendingCounterSpyOrder(
          humanId: _human,
          spyId: spyId,
          targetTileKey: homeTile,
        );
        await tester.pumpWidget(
          buildCivilianPanel(
            game: game,
            humanPlayerId: _human,
            currentOrders: orders,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Relocate'), findsNothing);
        expect(
          find.textContaining('Status: Counter-espionage'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Relocate tap emits StartCivilianRelocateSelectionEvent',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final events = <StartCivilianRelocateSelectionEvent>[];
        bus.on<StartCivilianRelocateSelectionEvent>().listen(events.add);

        final game = buildCivilianSpyFixtureGame(id: 'g_spy_relocate_bus');
        await tester.pumpWidget(
          buildCivilianPanel(
            game: game,
            humanPlayerId: _human,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Relocate'));
        await tester.pumpAndSettle();

        expect(events, hasLength(1));
        expect(events.single.unitId, 'spy1');
      },
    );

    testWidgets(
      'Spy with pending MoveOrder shows relocating destination row copy',
      (WidgetTester tester) async {
        const spyId = 'spy1';
        const destTile = 'oldWorld|p1|1|0';
        final game = buildCivilianSpyFixtureGame(id: 'g_spy_pending_move');
        final orders = civilianSpyPendingMoveOrder(
          humanId: _human,
          spyId: spyId,
          destinationTileKey: destTile,
        );
        await tester.pumpWidget(
          buildCivilianPanel(
            game: game,
            humanPlayerId: _human,
            currentOrders: orders,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Relocating to: Old World — Home'),
          findsOneWidget,
        );
      },
    );

    testWidgets('idle Explorer shows Assign but not Relocate', (
      WidgetTester tester,
    ) async {
      final game = buildCivilianSingleUnitOwGame(
        id: 'g_explorer_only',
        unitId: 'e1',
        unitType: kUnitTypeExplorer,
      );
      await tester.pumpWidget(
        buildCivilianPanel(game: game, humanPlayerId: _human),
      );
      await tester.pumpAndSettle();

      expect(find.text('Assign'), findsOneWidget);
      expect(find.text('Relocate'), findsNothing);
    });
  });
}
