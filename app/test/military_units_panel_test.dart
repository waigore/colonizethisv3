// Tests for MilitaryUnitsPanel. SPEC/ui/military-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart' show isMilitaryUnit;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart'
    show trainMilitaryDialogId;
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';

import 'support/military_units_panel_test_support.dart';
import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerIdWithUnits;
  const String humanPlayerIdWithNoUnits = 'no-such-player';

  setUpAll(() {
    game = buildMilitaryPanelTestGame();
    humanPlayerIdWithUnits = game.players.first.id;
  });

  group('MilitaryUnitsPanel', () {
    testWidgets('AC: Panel shows title Military Units', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildMilitaryPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.text('Military Units'), findsOneWidget);
    });

    testWidgets(
      'AC: Empty state when human player has zero regiments and no fleets',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildMilitaryPanel(game: game, humanPlayerId: humanPlayerIdWithNoUnits),
        );
        await tester.pumpAndSettle();

        expect(find.text('No military units'), findsOneWidget);
        expect(find.byType(ListTile), findsNothing);
      },
    );

    testWidgets('header Train renders as a primary CtActionTextButton pill '
        '(no CtNinePatchButton header chrome) — #3514 owner decisions #5/#15', (
      WidgetTester tester,
    ) async {
      // Empty roster isolates the header so the only button chrome is the
      // Train pill (no row Move/Split CtNinePatchButtons, no Combine).
      await tester.pumpWidget(
        buildMilitaryPanel(game: game, humanPlayerId: humanPlayerIdWithNoUnits),
      );
      await tester.pumpAndSettle();

      final headerButtons = find.descendant(
        of: find.byType(UnitsPanelShell),
        matching: find.byType(CtActionTextButton),
      );
      expect(headerButtons, findsOneWidget);
      final train = tester.widget<CtActionTextButton>(headerButtons.first);
      expect(train.primary, isTrue);
      expect(train.label, 'Train');
      expect(find.byType(CtNinePatchButton), findsNothing);
    });

    testWidgets(
      'header Combine renders as a primary CtActionTextButton pill when a '
      'combinable roster is present — #3514 owner decisions #5/#15',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildMilitaryPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
        );
        await tester.pumpAndSettle();

        final combine = find.ancestor(
          of: find.text('Combine'),
          matching: find.byType(CtActionTextButton),
        );
        // Combine only renders for a non-empty roster; when present it must be
        // a primary pill and never a CtNinePatchButton.
        if (combine.evaluate().isNotEmpty) {
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
        }
        final train = find.ancestor(
          of: find.text('Train'),
          matching: find.byType(CtActionTextButton),
        );
        expect(train, findsOneWidget);
        expect(tester.widget<CtActionTextButton>(train.first).primary, isTrue);
      },
    );

    testWidgets('naval location header uses sea-zone display name', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_mil_sea_label';
      const cap = 'oldWorld|c1';
      final miniGame = Game(
        id: 'g_mil_sea_label',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(
                id: 'c1',
                regionId: 'oldWorld',
                ownerId: humanId,
                displayName: 'Cap',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f_at_sea',
              ownerId: humanId,
              regionId: 'oldWorld',
              seaZoneId: 'zone_x',
              ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
            ),
          ],
          seaZoneDisplayNameById: const {'oldWorld|zone_x': 'Mil Named Sea'},
        ),
        players: const [
          Player(
            id: humanId,
            displayName: 'Mil Sea Tester',
            isHuman: true,
            capitalProvinceId: cap,
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: cap,
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        buildMilitaryPanel(game: miniGame, humanPlayerId: humanId),
      );
      await tester.pump();
      expect(find.textContaining('Mil Named Sea'), findsWidgets);
    });

    testWidgets(
      'AC: When player has military units, tree shows regions and type rows',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildMilitaryPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
        );
        await tester.pumpAndSettle();

        final militaryCount =
            game.worldState.oldWorld.units
                .where(
                  (u) =>
                      u.ownerId == humanPlayerIdWithUnits &&
                      isMilitaryUnit(u.type),
                )
                .length +
            game.worldState.newWorld.units
                .where(
                  (u) =>
                      u.ownerId == humanPlayerIdWithUnits &&
                      isMilitaryUnit(u.type),
                )
                .length;
        final fleetCount = game.worldState.fleets
            .where(
              (f) =>
                  f.ownerId == humanPlayerIdWithUnits &&
                  f.shipTypeIds.isNotEmpty,
            )
            .length;
        if (militaryCount > 0 || fleetCount > 0) {
          // Army/fleet entries surface their actions through the
          // UnitsEntityActionRow composite (detail sub-rows no longer use
          // Material ListTile chrome; Refs #2914 S8). The remaining ListTile
          // in the tree, if any, belongs to the ExpansionTile header, not the
          // migrated sub-rows — source-level ListTile usage is covered by the
          // repo.app_no_material_listtile gate.
          expect(find.byType(UnitsEntityActionRow), findsAtLeastNWidgets(1));
          expect(
            find.text('OLD WORLD').evaluate().isNotEmpty ||
                find.text('NEW WORLD').evaluate().isNotEmpty,
            isTrue,
          );
        }
      },
    );

    testWidgets(
      'AC: Army subtitle uses province display name; regiment titles use roster names',
      (WidgetTester tester) async {
        const playerId = 'gp_display_names';
        const provinceLocal = 'lisbon';
        const fullProvince = 'oldWorld|$provinceLocal';
        final miniGame = Game(
          id: 'g_display_mil',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              units: [
                Unit(
                  id: 'levy1',
                  type: 'peasant_levies',
                  ownerId: playerId,
                  locationProvinceId: fullProvince,
                  medals: 0,
                  status: UnitStatus.idle,
                ),
              ],
              provinces: [
                Province(
                  id: fullProvince,
                  regionId: 'oldWorld',
                  ownerId: playerId,
                  displayName: 'Lisbon Harbor',
                  townTileKey: 'oldWorld|lisbon|0|0',
                ),
              ],
            ),
            newWorld: const RegionData(),
            fleets: [],
            armies: [
              Army(
                id: 'army_field',
                ownerId: playerId,
                regionId: 'oldWorld',
                stationedProvinceId: fullProvince,
                regimentUnitIds: const ['levy1'],
                isHomeArmy: false,
              ),
            ],
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                fullProvince: ['oldWorld|lisbon|0|0'],
              },
            },
          ),
          players: const [
            Player(
              id: playerId,
              displayName: 'Tester',
              isHuman: true,
              capitalProvinceId: fullProvince,
            ),
          ],
        );

        await tester.pumpWidget(
          buildMilitaryPanel(game: miniGame, humanPlayerId: playerId),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('regiments · Lisbon Harbor'), findsWidgets);
        await expandFirstArmyExpansion(tester);
        expect(find.textContaining('Peasant Levies: 1'), findsOneWidget);
        expect(find.textContaining('peasant_levies:'), findsNothing);
      },
    );

    testWidgets('AC: Regiment rows show type, count, medals, status', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildMilitaryPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      final militaryCount =
          game.worldState.oldWorld.units
              .where(
                (u) =>
                    u.ownerId == humanPlayerIdWithUnits &&
                    isMilitaryUnit(u.type),
              )
              .length +
          game.worldState.newWorld.units
              .where(
                (u) =>
                    u.ownerId == humanPlayerIdWithUnits &&
                    isMilitaryUnit(u.type),
              )
              .length;
      if (militaryCount == 0) return;

      // Army entries use ExpansionTile; subtitle includes "regiments ·".
      expect(find.textContaining('regiments ·'), findsAtLeastNWidgets(1));
      await expandAllArmyExpansions(tester);
      // ExpansionTile headers render a framework ListTile; expanded regiment
      // detail sub-rows use non-Material chrome (Refs #2914 S8).
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'AC: When tree has content, location headers show region (name — region)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildMilitaryPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
        );
        await tester.pumpAndSettle();

        // Skip when the panel has no unit content (armies → UnitsEntityActionRow,
        // naval ship rows → "Status: …" subtitle). Detail rows no longer use
        // Material ListTile chrome (Refs #2914 S8).
        if (find.byType(UnitsEntityActionRow).evaluate().isEmpty &&
            find.textContaining('Status:').evaluate().isEmpty) {
          return;
        }
        expect(find.textContaining(' — '), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('panel is wrapped in CtPanel', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildMilitaryPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CtPanel), findsOneWidget);
    });

    testWidgets('AC: Tapping a row emits LocateMapTileEvent', (
      WidgetTester tester,
    ) async {
      LocateMapTileEvent? locateEvent;
      final bus = AppEventBus.create();
      bus.on<LocateMapTileEvent>().listen((e) => locateEvent = e);
      await tester.pumpWidget(
        buildMilitaryPanel(game: game, humanPlayerId: humanPlayerIdWithUnits, bus: bus),
      );
      await tester.pumpAndSettle();

      final locateButtons = find.byIcon(Icons.my_location);
      if (locateButtons.evaluate().isEmpty) return;
      await tester.tap(locateButtons.first);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(locateEvent, isNotNull);
      expect(
        locateEvent!.regionId == 'oldWorld' ||
            locateEvent!.regionId == 'newWorld',
        isTrue,
      );
    });

    testWidgets('builds without locate callback', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildMilitaryPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MilitaryUnitsPanel), findsOneWidget);
      // Locate-tap behavior on detail sub-rows is covered by the dedicated
      // LocateMapTileEvent test; here we only assert the panel builds without a
      // locate callback wired (Refs #2914 S8 migrated rows off Material
      // ListTile chrome).
    });

    testWidgets('Train button emits train-military dialog open event', (
      WidgetTester tester,
    ) async {
      OpenDialogEvent? openDialogEvent;
      final bus = AppEventBus.create();
      bus.on<OpenDialogEvent>().listen((e) => openDialogEvent = e);

      await tester.pumpWidget(
        buildMilitaryPanel(game: game, humanPlayerId: humanPlayerIdWithUnits, bus: bus),
      );
      await tester.pumpAndSettle();

      final trainButton = find.text('Train');
      expect(trainButton, findsOneWidget);
      await tester.tap(trainButton);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(openDialogEvent, isNotNull);
      expect(openDialogEvent!.dialogId, trainMilitaryDialogId);
    });

    testWidgets(
      'AC: Tapping locate emits ClosePanelEvent before LocateMapTileEvent',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final sequence = <Type>[];
        bus.stream.listen((e) => sequence.add(e.runtimeType));

        await tester.pumpWidget(
          buildMilitaryPanel(
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        final locateButtons = find.byIcon(Icons.my_location);
        if (locateButtons.evaluate().isEmpty) return;
        await tester.tap(locateButtons.first);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          sequence.indexOf(ClosePanelEvent),
          lessThan(sequence.indexOf(LocateMapTileEvent)),
        );
      },
    );

    testWidgets('panel is scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildMilitaryPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
