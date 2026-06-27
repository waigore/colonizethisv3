// Tests for MilitaryUnitsPanel. SPEC/ui/military-units-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/utils/map_location_resolver.dart';

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
}
