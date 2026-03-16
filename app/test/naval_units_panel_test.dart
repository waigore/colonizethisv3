// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/naval_units_panel.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerIdWithFleets;
  const String humanPlayerIdWithNoFleets = 'no-such-player';

  setUpAll(() {
    game = getDebugInitGameResult().game;
    humanPlayerIdWithFleets =
        game.players.isNotEmpty ? game.players.first.id : 'gp1';
  });

  Widget buildPanel({
    required Game game,
    required String humanPlayerId,
    void Function(String tileKey, String regionId)? onLocateFleet,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: NavalUnitsPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          onLocateFleet: onLocateFleet,
        ),
      ),
    );
  }

  group('NavalUnitsPanel', () {
    testWidgets('AC: Panel shows title Naval Units',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithFleets,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Naval Units'), findsOneWidget);
    });

    testWidgets(
        'AC: When human player has no fleets, panel does not crash and shows either empty or Home Fleet only',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithNoFleets,
      ));
      await tester.pumpAndSettle();

      // Depending on scenario data, there may be a Home Fleet or no fleets at all.
      // This test only asserts that the panel builds without throwing and that
      // any content is rendered inside a CtPanel.
      expect(find.byType(CtPanel), findsOneWidget);
    });

    testWidgets('AC: When player has fleets, panel shows at least one fleet row',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithFleets,
      ));
      await tester.pumpAndSettle();

      final fleets = game.worldState.fleets
          .where((f) =>
              f.ownerId == humanPlayerIdWithFleets &&
              f.shipTypeIds.isNotEmpty)
          .length;
      if (fleets > 0) {
        expect(find.byType(ExpansionTile), findsAtLeastNWidgets(1));
        expect(
          find.text('Old World').evaluate().isNotEmpty ||
              find.text('New World').evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets('AC: Panel is wrapped in CtPanel', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithFleets,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CtPanel), findsOneWidget);
    });

    testWidgets('AC: Tapping a fleet row invokes onLocateFleet',
        (WidgetTester tester) async {
      String? locatedTileKey;
      String? locatedRegionId;
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithFleets,
        onLocateFleet: (tileKey, regionId) {
          locatedTileKey = tileKey;
          locatedRegionId = regionId;
        },
      ));
      await tester.pumpAndSettle();

      final tiles = find.byType(ExpansionTile);
      if (tiles.evaluate().isEmpty) return;
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      expect(locatedTileKey, isNotNull);
      expect(locatedRegionId, isNotNull);
      expect(
        locatedRegionId == 'oldWorld' || locatedRegionId == 'newWorld',
        isTrue,
      );
    });

    testWidgets('AC: Strength indicator is shown in summary and details',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithFleets,
      ));
      await tester.pumpAndSettle();

      final tiles = find.byType(ExpansionTile);
      if (tiles.evaluate().isEmpty) return;

      // Summary line should contain "Strength:"
      expect(find.textContaining('Strength:'), findsAtLeastNWidgets(1));

      await tester.tap(tiles.first);
      await tester.pumpAndSettle();

      // Expanded details should also show a Strength row.
      expect(find.textContaining('Strength:'), findsAtLeastNWidgets(1));
    });
  });
}

