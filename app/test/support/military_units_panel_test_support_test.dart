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

import 'package:colonizethis_app/features/game/widgets/units/military/military_units_panel.dart';

import 'military_units_panel_test_support.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_assets.dart';

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

  test('buildMilitarySeaFleetDisplayGame seeds one fleet at the sea zone', () {
    final game = buildMilitarySeaFleetDisplayGame(
      id: 'sea_smoke',
      playerId: 'p_sea',
      shipTypeIds: const ['galleon'],
      mission: FleetMission.patrol,
      includeLisbonProvince: true,
    );
    expect(game.worldState.fleets, hasLength(1));
    expect(game.worldState.fleets.single.seaZoneId, 'atlantic');
    expect(game.worldState.oldWorld.provinces, hasLength(1));
  });

  test(
    'buildMilitarySeaFleetDisplayGame omits land province when not requested',
    () {
      final game = buildMilitarySeaFleetDisplayGame(
        id: 'sea_empty_land',
        playerId: 'p_sea',
        shipTypeIds: const ['fluyte'],
        mission: FleetMission.defend,
      );
      expect(game.worldState.oldWorld.provinces, isEmpty);
      expect(game.worldState.fleets.single.mission, FleetMission.defend);
    },
  );

  test('buildMilitaryArmyAtLisbonDisplayGame wires regiment ids onto the army', () {
    const playerId = 'p_land';
    final game = buildMilitaryArmyAtLisbonDisplayGame(
      id: 'army_smoke',
      playerId: playerId,
      armyId: 'army_x',
      units: [
        Unit(
          id: 'u1',
          type: 'musketeers',
          ownerId: playerId,
          locationProvinceId: 'oldWorld|lisbon',
        ),
        Unit(
          id: 'u2',
          type: 'musketeers',
          ownerId: playerId,
          locationProvinceId: 'oldWorld|lisbon',
        ),
      ],
    );
    expect(game.worldState.armies.single.regimentUnitIds, ['u1', 'u2']);
    expect(game.worldState.oldWorld.units, hasLength(2));
  });

  test('buildMilitaryProvinceTileLookupGame exposes tile keys without townTileKey', () {
    final game = buildMilitaryProvinceTileLookupGame(tileKey: 'oldWorld|p1|1|1');
    final province = game.worldState.oldWorld.provinces.single;
    expect(province.townTileKey, isNull);
    expect(
      game.worldState.tileKeysByRegionAndProvince['oldWorld']!['oldWorld|p1'],
      ['oldWorld|p1|1|1'],
    );
  });

  testWidgets(
    'ArmySplitTestHarness renders the panel and applies a bus-driven split',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);

      await pumpArmySplitHarness(
        tester,
        initialGame: buildMilitaryHomeArmyAtCapitalGame(
          id: 'g_military_support_smoke',
          playerId: kPanelTestHumanPlayerId,
          regimentIds: const ['r1', 'r2'],
        ),
        humanPlayerId: kPanelTestHumanPlayerId,
        bus: bus,
      );

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
