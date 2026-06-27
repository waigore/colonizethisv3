// Tests for MilitaryUnitsPanel. SPEC/ui/military-units-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/utils/map_location_resolver.dart';

import 'support/military_units_panel_test_support.dart';
import 'support/panel_test_fixtures.dart';

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
        const regionId = 'oldWorld';
        const provinceId = 'p1';
        const prefixedId = 'oldWorld|p1';
        const tileKey = 'oldWorld|p1|0|0';
        final minimalGame = Game(
          id: 'min',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
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
              regionId: {
                prefixedId: [tileKey],
              },
            },
          ),
          players: const [],
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
      const seaZoneId = 'atlantic';
      final gameWithSeaFleet = Game(
        id: 'sea_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            units: [],
            provinces: [
              Province(id: 'lisbon', regionId: 'oldWorld', ownerId: playerId),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'fleet1',
              ownerId: playerId,
              regionId: 'oldWorld',
              seaZoneId: seaZoneId,
              shipTypeIds: ['galleon', 'carrack'],
              mission: FleetMission.patrol,
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
        players: [Player(id: playerId, displayName: 'Test', isHuman: true)],
      );

      await tester.pumpWidget(
        buildMilitaryPanel(game: gameWithSeaFleet, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('atlantic — Old World'), findsOneWidget);
      expect(find.textContaining('Galleon: 1'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Carrack: 1'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Status: Patrol'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows multiple ships of same type aggregated', (
      WidgetTester tester,
    ) async {
      const playerId = 'test_player';
      final gameWithMultipleShips = Game(
        id: 'multi_ship_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(units: []),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'fleet1',
              ownerId: playerId,
              regionId: 'oldWorld',
              seaZoneId: 'atlantic',
              shipTypeIds: ['galleon', 'galleon', 'galleon'],
              mission: FleetMission.blockade,
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
        players: [Player(id: playerId, displayName: 'Test', isHuman: true)],
      );

      await tester.pumpWidget(
        buildMilitaryPanel(game: gameWithMultipleShips, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Galleon: 3'), findsOneWidget);
      expect(find.textContaining('Status: Blockade'), findsOneWidget);
    });

    testWidgets('fleet with defend mission shows Defend status', (
      WidgetTester tester,
    ) async {
      const playerId = 'test_player';
      final gameWithDefendFleet = Game(
        id: 'defend_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(units: []),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'fleet1',
              ownerId: playerId,
              regionId: 'oldWorld',
              seaZoneId: 'atlantic',
              shipTypeIds: ['fluyte'],
              mission: FleetMission.defend,
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
        players: [Player(id: playerId, displayName: 'Test', isHuman: true)],
      );

      await tester.pumpWidget(
        buildMilitaryPanel(game: gameWithDefendFleet, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Status: Defend'), findsOneWidget);
    });
  });

  group('Medals range display', () {
    testWidgets('shows medal range when regiment has multiple medal values', (
      WidgetTester tester,
    ) async {
      const playerId = 'multi_medal_player';
      final gameWithMixedMedals = Game(
        id: 'mixed_medals_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
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
            provinces: [
              Province(
                id: 'oldWorld|lisbon',
                regionId: 'oldWorld',
                ownerId: playerId,
                townTileKey: 'oldWorld|lisbon|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [],
          armies: [
            Army(
              id: 'army_mixed',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: 'oldWorld|lisbon',
              regimentUnitIds: const ['u1', 'u2', 'u3'],
              isHomeArmy: false,
            ),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|lisbon': ['oldWorld|lisbon|0|0'],
            },
          },
        ),
        players: [Player(id: playerId, displayName: 'Test', isHuman: true)],
      );

      await tester.pumpWidget(
        buildMilitaryPanel(game: gameWithMixedMedals, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();
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
      final gameWithWorkingUnit = Game(
        id: 'working_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
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
            provinces: [
              Province(
                id: 'oldWorld|lisbon',
                regionId: 'oldWorld',
                ownerId: playerId,
                townTileKey: 'oldWorld|lisbon|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [],
          armies: [
            Army(
              id: 'army_w',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: 'oldWorld|lisbon',
              regimentUnitIds: const ['u1', 'u2'],
              isHomeArmy: false,
            ),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|lisbon': ['oldWorld|lisbon|0|0'],
            },
          },
        ),
        players: [Player(id: playerId, displayName: 'Test', isHuman: true)],
      );

      await tester.pumpWidget(
        buildMilitaryPanel(game: gameWithWorkingUnit, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Army army_w'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Status: Working'), findsOneWidget);
    });

    testWidgets('shows Idle status when units are idle and none working', (
      WidgetTester tester,
    ) async {
      const playerId = 'idle_status_player';
      final gameWithIdleUnit = Game(
        id: 'idle_test',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
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
            provinces: [
              Province(
                id: 'oldWorld|lisbon',
                regionId: 'oldWorld',
                ownerId: playerId,
                townTileKey: 'oldWorld|lisbon|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [],
          armies: [
            Army(
              id: 'army_d',
              ownerId: playerId,
              regionId: 'oldWorld',
              stationedProvinceId: 'oldWorld|lisbon',
              regimentUnitIds: const ['u1'],
              isHomeArmy: false,
            ),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|lisbon': ['oldWorld|lisbon|0|0'],
            },
          },
        ),
        players: [Player(id: playerId, displayName: 'Test', isHuman: true)],
      );

      await tester.pumpWidget(
        buildMilitaryPanel(game: gameWithIdleUnit, humanPlayerId: playerId),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Army army_d'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Status: Idle'), findsOneWidget);
    });
  });
}
