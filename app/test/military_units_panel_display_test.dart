// Tests for MilitaryUnitsPanel. SPEC/ui/military-units-panel.md.

import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/map_state/map_location_resolver.dart';

import 'military_units_panel_test_support.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerIdWithUnits;

  setUpAll(() {
    game = buildMilitaryPanelTestGame();
    humanPlayerIdWithUnits = game.players.first.id;
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

    test(
      'returns first tile from tileKeysByRegionAndProvince when townTileKey is null',
      () {
        const tileKey = 'oldWorld|p1|0|0';
        final minimalGame = buildMilitaryProvinceTileLookupGame(
          ownerId: humanPlayerIdWithUnits,
          tileKey: tileKey,
        );
        final province = minimalGame.worldState.oldWorld.provinces.first;
        final key = tileKeyForProvinceLocation(minimalGame, province);
        expect(key, tileKey);
      },
    );

    test(
      'returns null for province with no tiles in tileKeysByRegionAndProvince',
      () {
        final province = Province(
          id: 'nonexistent',
          regionId: 'oldWorld',
          ownerId: humanPlayerIdWithUnits,
        );
        final key = tileKeyForProvinceLocation(game, province);
        expect(key, isNull);
      },
    );
  });

  group('tileKeyForSeaZoneLocation', () {
    test(
      'returns port tile when sea zone has port in portsByProvinceSeaboard',
      () {
        if (game.worldState.portsByProvinceSeaboard.isEmpty) return;
        final entry = game.worldState.portsByProvinceSeaboard.entries.first;
        final parts = entry.key.split('|');
        final regionId = parts[0];
        final seaZoneId = parts.length >= 3
            ? parts.sublist(2).join('|')
            : parts[1];
        final key = tileKeyForSeaZoneLocation(game, regionId, seaZoneId);
        expect(key, isNotNull);
        expect(key, entry.value);
      },
    );

    test('returns null for unknown sea zone', () {
      final key = tileKeyForSeaZoneLocation(
        game,
        'oldWorld',
        'nonexistent_sea_zone',
      );
      expect(key, isNull);
    });
  });

  group('Sea zone fleet display', () {
    testWidgets('shows ship rows for fleet at sea', (
      WidgetTester tester,
    ) async {
      const playerId = 'test_player';
      final gameWithSeaFleet = buildMilitarySeaFleetDisplayGame(
        id: 'sea_test',
        playerId: playerId,
        shipTypeIds: const ['galleon', 'carrack'],
        mission: FleetMission.patrol,
        includeLisbonProvince: true,
      );

      await pumpMilitaryPanel(
        tester,
        game: gameWithSeaFleet,
        humanPlayerId: playerId,
      );

      expect(find.textContaining('atlantic — Old World'), findsOneWidget);
      expect(find.textContaining('Galleon: 1'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Carrack: 1'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Status: Patrol'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows multiple ships of same type aggregated', (
      WidgetTester tester,
    ) async {
      const playerId = 'test_player';
      final gameWithMultipleShips = buildMilitarySeaFleetDisplayGame(
        id: 'multi_ship_test',
        playerId: playerId,
        shipTypeIds: const ['galleon', 'galleon', 'galleon'],
        mission: FleetMission.blockade,
      );

      await pumpMilitaryPanel(
        tester,
        game: gameWithMultipleShips,
        humanPlayerId: playerId,
      );

      expect(find.textContaining('Galleon: 3'), findsOneWidget);
      expect(find.textContaining('Status: Blockade'), findsOneWidget);
    });

    testWidgets('fleet with defend mission shows Defend status', (
      WidgetTester tester,
    ) async {
      const playerId = 'test_player';
      final gameWithDefendFleet = buildMilitarySeaFleetDisplayGame(
        id: 'defend_test',
        playerId: playerId,
        shipTypeIds: const ['fluyte'],
        mission: FleetMission.defend,
      );

      await pumpMilitaryPanel(
        tester,
        game: gameWithDefendFleet,
        humanPlayerId: playerId,
      );

      expect(find.textContaining('Status: Defend'), findsOneWidget);
    });
  });

  group('Medals range display', () {
    testWidgets('shows medal range when regiment has multiple medal values', (
      WidgetTester tester,
    ) async {
      const playerId = 'multi_medal_player';
      final gameWithMixedMedals = buildMilitaryArmyAtLisbonDisplayGame(
        id: 'mixed_medals_test',
        playerId: playerId,
        armyId: 'army_mixed',
        units: [
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: playerId,
            locationProvinceId: 'oldWorld|lisbon',
            medals: 1,
            status: UnitStatus.idle,
          ),
          Unit(
            id: 'u2',
            type: 'musketeers',
            ownerId: playerId,
            locationProvinceId: 'oldWorld|lisbon',
            medals: 2,
            status: UnitStatus.idle,
          ),
          Unit(
            id: 'u3',
            type: 'musketeers',
            ownerId: playerId,
            locationProvinceId: 'oldWorld|lisbon',
            medals: 3,
            status: UnitStatus.idle,
          ),
        ],
      );

      await pumpMilitaryPanel(
        tester,
        game: gameWithMixedMedals,
        humanPlayerId: playerId,
      );
      await tester.tap(find.text('Army army_mixed'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Medals: 1–3'), findsOneWidget);
    });
  });

  group('Unit status display', () {
    testWidgets('shows Working status when any unit is working', (
      WidgetTester tester,
    ) async {
      const playerId = 'working_status_player';
      final gameWithWorkingUnit = buildMilitaryArmyAtLisbonDisplayGame(
        id: 'working_test',
        playerId: playerId,
        armyId: 'army_w',
        units: [
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: playerId,
            locationProvinceId: 'oldWorld|lisbon',
            medals: 1,
            status: UnitStatus.idle,
          ),
          Unit(
            id: 'u2',
            type: 'musketeers',
            ownerId: playerId,
            locationProvinceId: 'oldWorld|lisbon',
            medals: 1,
            status: UnitStatus.working,
          ),
        ],
      );

      await pumpMilitaryPanel(
        tester,
        game: gameWithWorkingUnit,
        humanPlayerId: playerId,
      );
      await tester.tap(find.text('Army army_w'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Status: Working'), findsOneWidget);
    });

    testWidgets('shows Idle status when units are idle and none working', (
      WidgetTester tester,
    ) async {
      const playerId = 'idle_status_player';
      final gameWithIdleUnit = buildMilitaryArmyAtLisbonDisplayGame(
        id: 'idle_test',
        playerId: playerId,
        armyId: 'army_d',
        units: [
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: playerId,
            locationProvinceId: 'oldWorld|lisbon',
            medals: 1,
            status: UnitStatus.idle,
          ),
        ],
      );

      await pumpMilitaryPanel(
        tester,
        game: gameWithIdleUnit,
        humanPlayerId: playerId,
      );
      await tester.tap(find.text('Army army_d'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Status: Idle'), findsOneWidget);
    });
  });

  group('Counsel entry (Refs #4307)', () {
    testWidgets(
      'header Counsel emits NavigateToRouteEvent for Military tab on GAME90001',
      (WidgetTester tester) async {
        const playerId = 'gp_counsel_entry';
        final bus = AppEventBus.create();
        NavigateToRouteEvent? navigateEvent;
        bus.on<NavigateToRouteEvent>().listen((event) {
          navigateEvent = event;
        });

        final panelGame = buildMilitaryArmyAtLisbonDisplayGame(
          id: 'counsel_entry',
          playerId: playerId,
          armyId: 'army_counsel',
          units: [
            Unit(
              id: 'u_counsel',
              type: 'musketeers',
              ownerId: playerId,
              locationProvinceId: 'oldWorld|lisbon',
            ),
          ],
        );

        await pumpMilitaryPanel(
          tester,
          game: panelGame,
          humanPlayerId: playerId,
          bus: bus,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('military_units_counsel_button')),
        );
        await tester.pumpAndSettle();

        expect(navigateEvent, isNotNull);
        expect(navigateEvent!.route, Routes.counsel);
        final args = navigateEvent!.arguments as Map<String, Object?>?;
        expect(args?['counselTab'], 'military');
        expect(args?['humanPlayerId'], playerId);
      },
    );
  });
}
