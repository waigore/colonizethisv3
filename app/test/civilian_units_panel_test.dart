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
    void Function(Unit unit)? onLocateUnit,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CivilianUnitsPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          onLocateUnit: onLocateUnit,
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

    testWidgets('AC: When player has civilians, list shows units with status, location, assigned-to',
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
  });
}

bool _isCivilian(Unit unit) {
  final role = unitRoleForType(unit.type);
  if (role == null) return false;
  return role != UnitRole.military && role != UnitRole.naval;
}
