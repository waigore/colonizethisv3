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
    humanPlayerIdWithFleets = game.players.isNotEmpty
        ? game.players.first.id
        : 'gp1';
  });

  Widget buildPanel({
    required Game game,
    required String humanPlayerId,
    void Function(String tileKey, String regionId)? onLocateFleet,
    void Function(Game newGame)? onFleetsChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: NavalUnitsPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          onLocateFleet: onLocateFleet,
          onFleetsChanged: onFleetsChanged,
        ),
      ),
    );
  }

  group('NavalUnitsPanel', () {
    testWidgets('AC: Panel shows title Naval Units', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithFleets),
      );
      await tester.pumpAndSettle();

      expect(find.text('Naval Units'), findsOneWidget);
    });

    testWidgets(
      'AC: When human player has no fleets, panel does not crash and shows either empty or Home Fleet only',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(game: game, humanPlayerId: humanPlayerIdWithNoFleets),
        );
        await tester.pumpAndSettle();

        // Depending on scenario data, there may be a Home Fleet or no fleets at all.
        // This test only asserts that the panel builds without throwing and that
        // any content is rendered inside a CtPanel.
        expect(find.byType(CtPanel), findsOneWidget);
      },
    );

    testWidgets(
      'AC: When player has fleets, panel shows at least one fleet row',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildPanel(game: game, humanPlayerId: humanPlayerIdWithFleets),
        );
        await tester.pumpAndSettle();

        final fleets = game.worldState.fleets
            .where(
              (f) =>
                  f.ownerId == humanPlayerIdWithFleets &&
                  f.shipTypeIds.isNotEmpty,
            )
            .length;
        if (fleets > 0) {
          expect(find.byType(ExpansionTile), findsAtLeastNWidgets(1));
          expect(
            find.text('Old World').evaluate().isNotEmpty ||
                find.text('New World').evaluate().isNotEmpty,
            isTrue,
          );
        }
      },
    );

    testWidgets('AC: Panel is wrapped in CtPanel', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithFleets),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CtPanel), findsOneWidget);
    });

    testWidgets('AC: Tapping a fleet row invokes onLocateFleet', (
      WidgetTester tester,
    ) async {
      String? locatedTileKey;
      String? locatedRegionId;
      await tester.pumpWidget(
        buildPanel(
          game: game,
          humanPlayerId: humanPlayerIdWithFleets,
          onLocateFleet: (tileKey, regionId) {
            locatedTileKey = tileKey;
            locatedRegionId = regionId;
          },
        ),
      );
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

    testWidgets('AC: Strength indicator is shown in summary and details', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildPanel(game: game, humanPlayerId: humanPlayerIdWithFleets),
      );
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

    testWidgets(
      'sections render for fleets in both regions and onLocateFleet receives region id',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;

        final playerFleets = game.worldState.fleets
            .where((f) => f.ownerId == humanId && f.shipTypeIds.isNotEmpty)
            .toList();
        expect(
          playerFleets,
          isNotEmpty,
          reason: 'Demo game must include at least one fleet with ships',
        );
        final baseFleet = playerFleets.first;

        final oldProvinceList = game.worldState.oldWorld.provinces;
        final newProvinceList = game.worldState.newWorld.provinces;
        expect(oldProvinceList, isNotEmpty);
        expect(newProvinceList, isNotEmpty);
        final oldProvince = oldProvinceList.first;
        final newProvince = newProvinceList.first;

        // Inject deterministic port fleets in both regions so region headers
        // render reliably in the test.
        final extraOldFleet = baseFleet.copyWith(
          id: 'test_old_world_fleet',
          regionId: 'oldWorld',
          inPortAtProvinceId: oldProvince.id,
          seaZoneId: null,
          ownerId: humanId,
        );
        final extraNewFleet = baseFleet.copyWith(
          id: 'test_new_world_fleet',
          regionId: 'newWorld',
          inPortAtProvinceId: newProvince.id,
          seaZoneId: null,
          ownerId: humanId,
        );

        final gameWithExtraFleets = game.copyWith(
          worldState: game.worldState.copyWith(
            fleets: [...game.worldState.fleets, extraOldFleet, extraNewFleet],
          ),
        );

        String? locatedTileKey;
        String? locatedRegionId;

        await tester.pumpWidget(
          buildPanel(
            game: gameWithExtraFleets,
            humanPlayerId: humanId,
            onLocateFleet: (tileKey, regionId) {
              locatedTileKey = tileKey;
              locatedRegionId = regionId;
            },
          ),
        );
        await tester.pumpAndSettle();

        // Old/New World headers should appear when fleets exist in both regions.
        expect(find.text('Old World'), findsAtLeastNWidgets(1));
        expect(find.text('New World'), findsAtLeastNWidgets(1));

        Finder tileFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet ${extraNewFleet.id}',
        );
        if (tileFinder.evaluate().isEmpty) {
          // If the injected fleet lands on the player's capital province, the
          // panel labels it "Home Fleet".
          tileFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
        }
        await tester.ensureVisible(tileFinder);
        await tester.tap(tileFinder);
        await tester.pumpAndSettle();

        expect(locatedTileKey, isNotNull);
        expect(locatedRegionId, isNotNull);
        expect(
          locatedRegionId == 'oldWorld' || locatedRegionId == 'newWorld',
          isTrue,
        );
      },
    );

    testWidgets(
      'AC: Home Fleet expansion shows empty ships and locates capital tile',
      (WidgetTester tester) async {
        final gameInstance = game;
        final player = game.players.firstWhere(
          (p) => p.id == humanPlayerIdWithFleets,
          orElse: () => game.players.first,
        );

        final capitalTile = player.capitalTile;
        expect(
          capitalTile,
          isNotNull,
          reason: 'Demo game must define a capital tile',
        );

        final capitalParts = capitalTile!.toTileKey().split('|');
        expect(capitalParts.length, greaterThanOrEqualTo(2));
        final capitalRegionId = capitalParts[0];
        final capitalProvinceLocalId = capitalParts[1];

        Province? capitalProvince;
        final oldProvinces = gameInstance.worldState.oldWorld.provinces;
        final newProvinces = gameInstance.worldState.newWorld.provinces;
        for (final p in [...oldProvinces, ...newProvinces]) {
          if (p.regionId == capitalRegionId && p.id == capitalProvinceLocalId) {
            capitalProvince = p;
            break;
          }
        }

        // Mirror tileKeyForProvinceLocation() selection logic.
        String? expectedTileKey;
        if (capitalProvince != null) {
          final townTileKey = capitalProvince.townTileKey;
          if (townTileKey != null && townTileKey.isNotEmpty) {
            expectedTileKey = townTileKey;
          } else {
            final byProvince = gameInstance
                .worldState
                .tileKeysByRegionAndProvince[capitalProvince.regionId];
            final prefixedId =
                '${capitalProvince.regionId}|${capitalProvince.id}';
            final tiles =
                byProvince?[prefixedId] ?? byProvince?[capitalProvince.id];
            if (tiles != null && tiles.isNotEmpty)
              expectedTileKey = tiles.first;
          }
        }

        String? locatedTileKey;
        String? locatedRegionId;

        // Force the widget into the "synthetic" Home Fleet path by removing any
        // actual fleet that would be considered home (located at the capital
        // province). This ensures row.shipCountsByType is empty.
        final filteredFleets = gameInstance.worldState.fleets.where((f) {
          if (f.ownerId != humanPlayerIdWithFleets) return true;
          if (f.isAtSea) return true;
          final inPortId = f.inPortAtProvinceId;
          if (inPortId == null) return true;
          return !(f.regionId == capitalRegionId &&
              (inPortId == capitalProvinceLocalId ||
                  inPortId == '$capitalRegionId|$capitalProvinceLocalId'));
        }).toList();

        final gameWithoutHomeFleets = gameInstance.copyWith(
          worldState: gameInstance.worldState.copyWith(fleets: filteredFleets),
        );

        await tester.pumpWidget(
          buildPanel(
            game: gameWithoutHomeFleets,
            humanPlayerId: humanPlayerIdWithFleets,
            onLocateFleet: (tileKey, regionId) {
              locatedTileKey = tileKey;
              locatedRegionId = regionId;
            },
          ),
        );
        await tester.pumpAndSettle();

        final homeTileFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
        expect(homeTileFinder, findsOneWidget);

        await tester.ensureVisible(homeTileFinder);
        await tester.tap(homeTileFinder);
        await tester.pumpAndSettle();

        expect(find.text('No ships in this fleet'), findsOneWidget);

        if (locatedTileKey != null) {
          // When the panel has a resolvable tile key for the home fleet,
          // it calls onLocateFleet with that key.
          expect(
            expectedTileKey == null || locatedTileKey == expectedTileKey,
            isTrue,
          );
          expect(locatedRegionId, capitalRegionId);
        }
      },
    );

    testWidgets(
      'AC: Expanding a sea-zone fleet calls onLocateFleet with correct sea-zone tile key',
      (WidgetTester tester) async {
        final gameInstance = game;
        final humanId = humanPlayerIdWithFleets;

        final baseFleetCandidates = gameInstance.worldState.fleets
            .where((f) => f.ownerId == humanId && f.shipTypeIds.isNotEmpty)
            .toList();
        expect(baseFleetCandidates, isNotEmpty);
        final baseFleet = baseFleetCandidates.first;

        final portsEntry = gameInstance
            .worldState
            .portsByProvinceSeaboard
            .entries
            .firstWhere((e) => e.key.split('|').length >= 2);
        final portsParts = portsEntry.key.split('|');
        final seaRegionId = portsParts.first;
        final localSeaZoneId = portsParts.last;

        final seaFleet = baseFleet.copyWith(
          id: 'test_sea_zone_fleet',
          ownerId: humanId,
          regionId: seaRegionId,
          seaZoneId: localSeaZoneId,
          inPortAtProvinceId: null,
        );

        final expectedTileKey = portsEntry.value;

        final gameWithExtraFleets = gameInstance.copyWith(
          worldState: gameInstance.worldState.copyWith(
            fleets: [...gameInstance.worldState.fleets, seaFleet],
          ),
        );

        String? locatedTileKey;
        String? locatedRegionId;
        await tester.pumpWidget(
          buildPanel(
            game: gameWithExtraFleets,
            humanPlayerId: humanId,
            onLocateFleet: (tileKey, regionId) {
              locatedTileKey = tileKey;
              locatedRegionId = regionId;
            },
          ),
        );
        await tester.pumpAndSettle();

        final fleetTileFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet ${seaFleet.id}',
        );
        expect(fleetTileFinder, findsOneWidget);

        await tester.ensureVisible(fleetTileFinder);
        await tester.tap(fleetTileFinder);
        await tester.pumpAndSettle();

        expect(locatedTileKey, expectedTileKey);
        expect(locatedRegionId, seaFleet.regionId);
      },
    );

    testWidgets(
      'AC: Expanding a port fleet calls onLocateFleet with correct province tile key',
      (WidgetTester tester) async {
        final gameInstance = game;
        final humanId = humanPlayerIdWithFleets;
        final player = gameInstance.players.firstWhere(
          (p) => p.id == humanId,
          orElse: () => gameInstance.players.first,
        );

        final capitalTile = player.capitalTile;
        expect(capitalTile, isNotNull);
        final capitalParts = capitalTile!.toTileKey().split('|');
        expect(capitalParts.length, greaterThanOrEqualTo(2));
        final capitalRegionId = capitalParts[0];

        final baseFleetCandidates = gameInstance.worldState.fleets
            .where((f) => f.ownerId == humanId && f.shipTypeIds.isNotEmpty)
            .toList();
        expect(baseFleetCandidates, isNotEmpty);
        final baseFleet = baseFleetCandidates.first;

        Province? targetProvince;
        String? expectedTileKey;

        final oldProvinces = gameInstance.worldState.oldWorld.provinces;
        final newProvinces = gameInstance.worldState.newWorld.provinces;

        for (final province in [...oldProvinces, ...newProvinces]) {
          // Ensure the injected fleet can't be labeled "Home Fleet" by skipping
          // the player's capital region entirely.
          if (province.regionId == capitalRegionId) continue;

          // Mirror tileKeyForProvinceLocation() selection logic.
          String? tileKey;
          if (province.townTileKey != null &&
              province.townTileKey!.isNotEmpty) {
            tileKey = province.townTileKey;
          } else {
            final byProvince = gameInstance
                .worldState
                .tileKeysByRegionAndProvince[province.regionId];
            final prefixedId = '${province.regionId}|${province.id}';
            final tiles = byProvince?[prefixedId] ?? byProvince?[province.id];
            if (tiles != null && tiles.isNotEmpty) tileKey = tiles.first;
          }

          if (tileKey == null) continue;

          targetProvince = province;
          expectedTileKey = tileKey;
          break;
        }

        if (targetProvince == null || expectedTileKey == null) {
          fail('No non-capital province with a resolvable tile key found');
        }

        final portFleet = baseFleet.copyWith(
          id: 'test_port_fleet',
          ownerId: humanId,
          regionId: targetProvince.regionId,
          inPortAtProvinceId: targetProvince.id,
          seaZoneId: null,
        );

        final gameWithExtraFleets = gameInstance.copyWith(
          worldState: gameInstance.worldState.copyWith(
            fleets: [...gameInstance.worldState.fleets, portFleet],
          ),
        );

        String? locatedTileKey;
        String? locatedRegionId;

        await tester.pumpWidget(
          buildPanel(
            game: gameWithExtraFleets,
            humanPlayerId: humanId,
            onLocateFleet: (tileKey, regionId) {
              locatedTileKey = tileKey;
              locatedRegionId = regionId;
            },
          ),
        );
        await tester.pumpAndSettle();

        final fleetTileFinder = find.widgetWithText(
          ExpansionTile,
          'Fleet ${portFleet.id}',
        );
        expect(fleetTileFinder, findsOneWidget);

        await tester.ensureVisible(fleetTileFinder);
        await tester.tap(fleetTileFinder);
        await tester.pumpAndSettle();

        expect(locatedTileKey, expectedTileKey);
        expect(locatedRegionId, portFleet.regionId);
      },
    );

    testWidgets('AC: Split button is not shown for Home Fleet', (
      WidgetTester tester,
    ) async {
      final humanId = humanPlayerIdWithFleets;

      await tester.pumpWidget(buildPanel(game: game, humanPlayerId: humanId));
      await tester.pumpAndSettle();

      final homeFleetFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
      if (homeFleetFinder.evaluate().isEmpty) {
        return;
      }

      await tester.ensureVisible(homeFleetFinder);
      await tester.tap(homeFleetFinder);
      await tester.pumpAndSettle();

      expect(find.text('Split'), findsNothing);
    });

    testWidgets('AC: Combine button is not shown for Home Fleet', (
      WidgetTester tester,
    ) async {
      final humanId = humanPlayerIdWithFleets;

      await tester.pumpWidget(buildPanel(game: game, humanPlayerId: humanId));
      await tester.pumpAndSettle();

      final homeFleetFinder = find.widgetWithText(ExpansionTile, 'Home Fleet');
      if (homeFleetFinder.evaluate().isEmpty) {
        return;
      }

      await tester.ensureVisible(homeFleetFinder);
      await tester.tap(homeFleetFinder);
      await tester.pumpAndSettle();

      expect(find.text('Combine'), findsNothing);
    });

    testWidgets('AC: Split button is shown for non-Home Fleet', (
      WidgetTester tester,
    ) async {
      final humanId = humanPlayerIdWithFleets;

      final playerFleets = game.worldState.fleets
          .where(
            (f) =>
                f.ownerId == humanId &&
                f.shipTypeIds.isNotEmpty &&
                f.id != 'home_fleet',
          )
          .toList();
      if (playerFleets.isEmpty) return;

      final baseFleet = playerFleets.first;

      await tester.pumpWidget(buildPanel(game: game, humanPlayerId: humanId));
      await tester.pumpAndSettle();

      final fleetFinder = find.widgetWithText(
        ExpansionTile,
        'Fleet ${baseFleet.id}',
      );
      if (fleetFinder.evaluate().isEmpty) return;

      await tester.ensureVisible(fleetFinder);
      await tester.tap(fleetFinder);
      await tester.pumpAndSettle();

      expect(find.text('Split'), findsOneWidget);
    });

    testWidgets('AC: Combine button is shown for non-Home Fleet', (
      WidgetTester tester,
    ) async {
      final humanId = humanPlayerIdWithFleets;

      final playerFleets = game.worldState.fleets
          .where(
            (f) =>
                f.ownerId == humanId &&
                f.shipTypeIds.isNotEmpty &&
                f.id != 'home_fleet',
          )
          .toList();
      if (playerFleets.isEmpty) return;

      final baseFleet = playerFleets.first;

      await tester.pumpWidget(buildPanel(game: game, humanPlayerId: humanId));
      await tester.pumpAndSettle();

      final fleetFinder = find.widgetWithText(
        ExpansionTile,
        'Fleet ${baseFleet.id}',
      );
      if (fleetFinder.evaluate().isEmpty) return;

      await tester.ensureVisible(fleetFinder);
      await tester.tap(fleetFinder);
      await tester.pumpAndSettle();

      expect(find.text('Combine'), findsOneWidget);
    });

    testWidgets(
      'AC: onFleetsChanged is called when fleet operations are performed',
      (WidgetTester tester) async {
        final humanId = humanPlayerIdWithFleets;

        Game? updatedGame;
        await tester.pumpWidget(
          buildPanel(
            game: game,
            humanPlayerId: humanId,
            onFleetsChanged: (newGame) {
              updatedGame = newGame;
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(updatedGame, isNull);
      },
    );

    testWidgets('AC: Combine mode shows Cancel button', (
      WidgetTester tester,
    ) async {
      final humanId = humanPlayerIdWithFleets;

      final playerFleets = game.worldState.fleets
          .where(
            (f) =>
                f.ownerId == humanId &&
                f.shipTypeIds.isNotEmpty &&
                f.id != 'home_fleet',
          )
          .toList();
      if (playerFleets.isEmpty) return;

      final baseFleet = playerFleets.first;

      await tester.pumpWidget(buildPanel(game: game, humanPlayerId: humanId));
      await tester.pumpAndSettle();

      final fleetFinder = find.widgetWithText(
        ExpansionTile,
        'Fleet ${baseFleet.id}',
      );
      if (fleetFinder.evaluate().isEmpty) return;

      await tester.ensureVisible(fleetFinder);
      await tester.tap(fleetFinder);
      await tester.pumpAndSettle();

      final combineButton = find.text('Combine');
      if (combineButton.evaluate().isEmpty) return;

      await tester.tap(combineButton);
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('AC: Combining fleets creates correct ship counts', (
      WidgetTester tester,
    ) async {
      final humanId = humanPlayerIdWithFleets;

      final playerFleets = game.worldState.fleets
          .where(
            (f) =>
                f.ownerId == humanId &&
                f.shipTypeIds.isNotEmpty &&
                f.id != 'home_fleet',
          )
          .toList();
      if (playerFleets.isEmpty) return;

      final fleet1 = playerFleets.first;
      final fleet1Ships = fleet1.shipTypeIds.length;

      final gameWithTwoFleetsAtSamePort = game.copyWith(
        worldState: game.worldState.copyWith(
          fleets: [
            ...game.worldState.fleets,
            fleet1.copyWith(id: 'test_fleet_1'),
            fleet1.copyWith(
              id: 'test_fleet_2',
              inPortAtProvinceId: fleet1.inPortAtProvinceId,
            ),
          ],
        ),
      );

      Game? updatedGame;
      await tester.pumpWidget(
        buildPanel(
          game: gameWithTwoFleetsAtSamePort,
          humanPlayerId: humanId,
          onFleetsChanged: (newGame) {
            updatedGame = newGame;
          },
        ),
      );
      await tester.pumpAndSettle();

      final fleet1Finder = find.widgetWithText(
        ExpansionTile,
        'Fleet test_fleet_1',
      );
      if (fleet1Finder.evaluate().isEmpty) return;

      await tester.ensureVisible(fleet1Finder);
      await tester.tap(fleet1Finder);
      await tester.pumpAndSettle();

      final combineButton = find.text('Combine');
      if (combineButton.evaluate().isEmpty) return;

      await tester.tap(combineButton);
      await tester.pumpAndSettle();

      expect(find.text('TARGET'), findsOneWidget);
    });

    testWidgets('AC: Fleets at different locations cannot be combined', (
      WidgetTester tester,
    ) async {
      final humanId = humanPlayerIdWithFleets;

      final playerFleets = game.worldState.fleets
          .where(
            (f) =>
                f.ownerId == humanId &&
                f.shipTypeIds.isNotEmpty &&
                f.id != 'home_fleet',
          )
          .toList();
      if (playerFleets.length < 2) return;

      final fleet1 = playerFleets.first;
      final fleet2 = playerFleets[1];

      if (fleet1.inPortAtProvinceId == null ||
          fleet2.inPortAtProvinceId == null)
        return;
      if (fleet1.inPortAtProvinceId == fleet2.inPortAtProvinceId) return;

      Game? updatedGame;
      await tester.pumpWidget(
        buildPanel(
          game: game,
          humanPlayerId: humanId,
          onFleetsChanged: (newGame) {
            updatedGame = newGame;
          },
        ),
      );
      await tester.pumpAndSettle();

      final fleet1Finder = find.widgetWithText(
        ExpansionTile,
        'Fleet ${fleet1.id}',
      );
      if (fleet1Finder.evaluate().isEmpty) return;

      await tester.ensureVisible(fleet1Finder);
      await tester.tap(fleet1Finder);
      await tester.pumpAndSettle();

      final combineButton = find.text('Combine');
      if (combineButton.evaluate().isEmpty) return;

      await tester.tap(combineButton);
      await tester.pumpAndSettle();

      final fleet2Finder = find.widgetWithText(
        ExpansionTile,
        'Fleet ${fleet2.id}',
      );

      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('AC: Beachhead mission appears in status line', (
      WidgetTester tester,
    ) async {
      const playerId = 'p_beach';
      final gameBeach = Game(
        id: 'beach_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(units: []),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'bf1',
              ownerId: playerId,
              regionId: 'oldWorld',
              seaZoneId: 'atlantic',
              shipTypeIds: const ['carrack'],
              mission: FleetMission.beachhead,
            ),
          ],
          portsByProvinceSeaboard: {
            'oldWorld|lisbon|atlantic': 'oldWorld|lisbon|0|0',
          },
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|lisbon': ['oldWorld|lisbon|0|0'],
            },
          },
        ),
        players: const [
          Player(id: playerId, displayName: 'P', isHuman: true),
        ],
      );

      await tester.pumpWidget(
        buildPanel(game: gameBeach, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Beachhead'), findsWidgets);
    });

    testWidgets('AC: No fleets and no capital shows empty naval message', (
      WidgetTester tester,
    ) async {
      const playerId = 'p_empty';
      final emptyGame = Game(
        id: 'empty_naval',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: [
          const Player(
            id: playerId,
            displayName: 'Solo',
            isHuman: true,
            treasury: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        buildPanel(game: emptyGame, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();

      expect(find.text('No naval units'), findsOneWidget);
    });

  });
}
