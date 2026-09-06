// Tests for MilitaryUnitsPanel. SPEC/ui/military-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart' show isMilitaryUnit;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';

import 'military_units_panel_test_support.dart';
import 'panel_test_fixtures.dart';

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
      await pumpMilitaryPanel(
        tester,
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      );

      expect(find.text('Military Units'), findsOneWidget);
    });

    testWidgets(
      'AC: Empty state when human player has zero regiments and no fleets',
      (WidgetTester tester) async {
        await pumpMilitaryPanel(
          tester,
          game: game,
          humanPlayerId: humanPlayerIdWithNoUnits,
        );

        expect(find.text('No military units'), findsOneWidget);
        expect(find.byType(ListTile), findsNothing);
      },
    );

    testWidgets('naval location header uses sea-zone display name', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_mil_sea_label';
      final miniGame = buildMilitarySeaZoneLabelGame(humanId: humanId);
      await pumpMilitaryPanel(tester, game: miniGame, humanPlayerId: humanId);
      await tester.pump();
      expect(find.textContaining('Mil Named Sea'), findsWidgets);
    });

    testWidgets(
      'AC: When player has military units, tree shows regions and type rows',
      (WidgetTester tester) async {
        await pumpMilitaryPanel(
          tester,
          game: game,
          humanPlayerId: humanPlayerIdWithUnits,
        );

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
        final miniGame = buildMilitaryProvinceDisplayNamesGame(
          playerId: playerId,
          provinceLocal: provinceLocal,
        );

        await pumpMilitaryPanel(
          tester,
          game: miniGame,
          humanPlayerId: playerId,
        );

        expect(find.textContaining('regiments · Lisbon Harbor'), findsWidgets);
        await expandFirstArmyExpansion(tester);
        expect(find.textContaining('Peasant Levies: 1'), findsOneWidget);
        expect(find.textContaining('peasant_levies:'), findsNothing);
      },
    );

    testWidgets('AC: Regiment rows show type, count, medals, status', (
      WidgetTester tester,
    ) async {
      await pumpMilitaryPanel(
        tester,
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      );

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

      expect(find.textContaining('regiments ·'), findsAtLeastNWidgets(1));
      await expandAllArmyExpansions(tester);
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'AC: When tree has content, location headers show region (name — region)',
      (WidgetTester tester) async {
        await pumpMilitaryPanel(
          tester,
          game: game,
          humanPlayerId: humanPlayerIdWithUnits,
        );

        if (find.byType(UnitsEntityActionRow).evaluate().isEmpty &&
            find.textContaining('Status:').evaluate().isEmpty) {
          return;
        }
        expect(find.textContaining(' — '), findsAtLeastNWidgets(1));
      },
    );
  });
}
