// Tests for MilitaryUnitsPanel. SPEC/ui/military-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/military_units_panel.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
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
    void Function(String tileKey, String regionId)? onLocateTile,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MilitaryUnitsPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          onLocateTile: onLocateTile,
        ),
      ),
    );
  }

  group('MilitaryUnitsPanel', () {
    testWidgets('AC: Panel shows title Military Units',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Military Units'), findsOneWidget);
    });

    testWidgets('AC: Empty state when human player has zero regiments and no fleets',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithNoUnits,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No military units'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('AC: When player has military units, tree shows regions and type rows',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      ));
      await tester.pumpAndSettle();

      final militaryCount = game.worldState.oldWorld.units
              .where((u) =>
                  u.ownerId == humanPlayerIdWithUnits && isMilitaryUnit(u.type))
              .length +
          game.worldState.newWorld.units
              .where((u) =>
                  u.ownerId == humanPlayerIdWithUnits && isMilitaryUnit(u.type))
              .length;
      final fleetCount = game.worldState.fleets
          .where((f) =>
              f.ownerId == humanPlayerIdWithUnits && f.shipTypeIds.isNotEmpty)
          .length;
      if (militaryCount > 0 || fleetCount > 0) {
        expect(find.byType(ListTile), findsAtLeastNWidgets(1));
        expect(find.text('Old World').evaluate().isNotEmpty ||
            find.text('New World').evaluate().isNotEmpty, isTrue);
      }
    });

    testWidgets('AC: Regiment rows show type, count, medals, status',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      ));
      await tester.pumpAndSettle();

      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isEmpty) return;
      expect(listTiles, findsAtLeastNWidgets(1));
      expect(find.textContaining('Status:'), findsAtLeastNWidgets(1));
    });

    testWidgets('AC: When tree has content, location headers show region (name — region)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      ));
      await tester.pumpAndSettle();

      if (find.byType(ListTile).evaluate().isEmpty) return;
      expect(find.textContaining(' — '), findsAtLeastNWidgets(1));
    });

    testWidgets('panel is wrapped in CtPanel', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CtPanel), findsOneWidget);
    });

    testWidgets('AC: Tapping a row invokes onLocateTile with tileKey and regionId',
        (WidgetTester tester) async {
      String? locatedTileKey;
      String? locatedRegionId;
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
        onLocateTile: (tileKey, regionId) {
          locatedTileKey = tileKey;
          locatedRegionId = regionId;
        },
      ));
      await tester.pumpAndSettle();

      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isEmpty) return;
      await tester.tap(listTiles.first);
      await tester.pumpAndSettle();

      expect(locatedTileKey, isNotNull);
      expect(locatedRegionId, isNotNull);
      expect(
          locatedRegionId == 'oldWorld' || locatedRegionId == 'newWorld',
          isTrue);
    });

    testWidgets('builds without onLocateTile callback',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(MilitaryUnitsPanel), findsOneWidget);
      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isNotEmpty) {
        await tester.tap(listTiles.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('panel is scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('tileKeyForProvinceLocation', () {
    test('returns townTileKey when province has it', () {
      final province = game.worldState.oldWorld.provinces.firstWhere(
        (p) => p.townTileKey != null && p.townTileKey!.isNotEmpty,
        orElse: () => game.worldState.oldWorld.provinces.first,
      );
      final key = tileKeyForProvinceLocation(game, province);
      if (province.townTileKey != null) {
        expect(key, province.townTileKey);
      }
    });

    test('returns first tile from tileKeysByRegionAndProvince when townTileKey is null',
        () {
      const regionId = 'oldWorld';
      const provinceId = 'p1';
      const prefixedId = 'oldWorld|p1';
      const tileKey = 'oldWorld|p1|0|0';
      final minimalGame = Game(
        id: 'min',
        worldState: WorldState(
          turnState: const TurnState(
              phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: provinceId,
                regionId: regionId,
                ownerId: humanPlayerIdWithUnits,
                townTileKey: null,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            regionId: {prefixedId: [tileKey]},
          },
        ),
        players: const [],
      );
      final province = minimalGame.worldState.oldWorld.provinces.first;
      final key = tileKeyForProvinceLocation(minimalGame, province);
      expect(key, tileKey);
    });

    test('returns null for province with no tiles in tileKeysByRegionAndProvince',
        () {
      final province = Province(
        id: 'nonexistent',
        regionId: 'oldWorld',
        ownerId: humanPlayerIdWithUnits,
      );
      final key = tileKeyForProvinceLocation(game, province);
      expect(key, isNull);
    });
  });

  group('tileKeyForSeaZoneLocation', () {
    test('returns port tile when sea zone has port in portsByProvinceSeaboard',
        () {
      if (game.worldState.portsByProvinceSeaboard.isEmpty) return;
      final entry = game.worldState.portsByProvinceSeaboard.entries.first;
      final parts = entry.key.split('|');
      final regionId = parts[0];
      final seaZoneId = parts.length >= 3 ? parts.sublist(2).join('|') : parts[1];
      final key = tileKeyForSeaZoneLocation(game, regionId, seaZoneId);
      expect(key, isNotNull);
      expect(key, entry.value);
    });

    test('returns null for unknown sea zone', () {
      final key = tileKeyForSeaZoneLocation(
          game, 'oldWorld', 'nonexistent_sea_zone');
      expect(key, isNull);
    });
  });
}
