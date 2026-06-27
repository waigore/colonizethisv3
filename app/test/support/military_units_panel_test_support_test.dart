// Smoke tests for the shared `MilitaryUnitsPanel` widget-test scaffolding.
//
// Verifies the consolidated helpers in `military_units_panel_test_support.dart`
// (extracted from the `military_units_panel_*_test.dart` family, Refs #3730)
// build the canonical panel host, drive the `ExpansionTile` tree helpers, and
// bridge `ArmySplitRequestedEvent` the same way the running shell does, so the
// family's test files keep their behavior.
//
// SPEC: SPEC/ui/military-units-panel.md, SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/military_units_panel.dart';

import 'military_units_panel_test_support.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_assets.dart';

/// Minimal game with one home army of two regiments, sized so the split-UI can
/// produce a second army when one regiment is moved.
Game _buildHomeArmyGame() {
  const playerId = kPanelTestHumanPlayerId;
  const cap = 'oldWorld|cap';
  return Game(
    id: 'g_military_support_smoke',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: cap,
            regionId: 'oldWorld',
            ownerId: playerId,
            displayName: 'Capital',
            townTileKey: 'tk_cap',
          ),
        ],
        units: [
          Unit(
            id: 'r1',
            type: 'musketeers',
            ownerId: playerId,
            locationProvinceId: cap,
          ),
          Unit(
            id: 'r2',
            type: 'musketeers',
            ownerId: playerId,
            locationProvinceId: cap,
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: [
        Army(
          id: 'home_army',
          ownerId: playerId,
          regionId: 'oldWorld',
          stationedProvinceId: cap,
          regimentUnitIds: const ['r1', 'r2'],
          isHomeArmy: true,
        ),
      ],
      nextArmySeq: 1,
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          cap: const ['tk_cap'],
        },
      },
    ),
    players: const [
      Player(
        id: playerId,
        displayName: 'Splitter',
        isHuman: true,
        capitalProvinceId: cap,
      ),
    ],
  );
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets(
    'buildMilitaryPanel hosts MilitaryUnitsPanel inside a MaterialApp scaffold',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildMilitaryPanel(
          game: buildMilitaryPanelTestGame(),
          humanPlayerId: kPanelTestHumanPlayerId,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(MilitaryUnitsPanel), findsOneWidget);
    },
  );

  testWidgets(
    'expandAllArmyExpansions expands every ExpansionTile without throwing',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildMilitaryPanel(
          game: buildMilitaryPanelTestGame(),
          humanPlayerId: kPanelTestHumanPlayerId,
        ),
      );
      await tester.pumpAndSettle();

      // The military fixture renders at least one army group as an ExpansionTile.
      expect(find.byType(ExpansionTile), findsAtLeastNWidgets(1));
      await expandFirstArmyExpansion(tester);
      await expandAllArmyExpansions(tester);
      expect(find.byType(MilitaryUnitsPanel), findsOneWidget);
    },
  );

  testWidgets(
    'ArmySplitTestHarness renders the panel and applies a bus-driven split',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 900,
              width: 480,
              child: ArmySplitTestHarness(
                initialGame: _buildHomeArmyGame(),
                humanPlayerId: kPanelTestHumanPlayerId,
                bus: bus,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MilitaryUnitsPanel), findsOneWidget);

      // Drive a split through the bus; the harness mirrors the shell handler by
      // applying it and rebuilding, so a second army surfaces in the tree.
      bus.emit(
        ArmySplitRequestedEvent(
          humanPlayerId: kPanelTestHumanPlayerId,
          sourceArmyId: 'home_army',
          unitIdsToMove: const ['r2'],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('Army army_1'), findsOneWidget);
    },
  );
}
