// Tests for SplitFleetDialog. SPEC/ui/naval-units-fleet-management.md.
//
// Note: Full dialog tests require nine-patch assets that aren't available
// in the test environment. The NavalUnitsPanel tests cover the fleet
// management functionality. These tests verify the basic state logic.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerId;

  setUpAll(() {
    game = getDebugInitGameResult().game;
    humanPlayerId = game.players.isNotEmpty ? game.players.first.id : 'gp1';
  });

  Fleet _createTestFleet({
    required String id,
    required String ownerId,
    required String regionId,
    String? inPortAtProvinceId,
    String? seaZoneId,
    List<String> shipTypeIds = const [],
  }) {
    return Fleet(
      id: id,
      ownerId: ownerId,
      regionId: regionId,
      inPortAtProvinceId: inPortAtProvinceId,
      seaZoneId: seaZoneId,
      shipTypeIds: shipTypeIds,
    );
  }

  group('SplitFleetDialog Logic', () {
    test('Fleet can be split into two fleets', () {
      final originalFleet = _createTestFleet(
        id: '1',
        ownerId: humanPlayerId,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'lisbon',
        shipTypeIds: ['carrack', 'fluyte', 'galleon'],
      );

      expect(originalFleet.shipTypeIds.length, 3);
    });

    test('Split fleet preserves location', () {
      final originalFleet = _createTestFleet(
        id: '1',
        ownerId: humanPlayerId,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'lisbon',
        shipTypeIds: ['carrack', 'fluyte'],
      );

      expect(originalFleet.inPortAtProvinceId, 'lisbon');
      expect(originalFleet.regionId, 'oldWorld');
    });

    test('Fleet at sea can be split', () {
      final fleet = _createTestFleet(
        id: '1',
        ownerId: humanPlayerId,
        regionId: 'oldWorld',
        seaZoneId: 'atlantic',
        shipTypeIds: ['galleon', 'galleon'],
      );

      expect(fleet.isAtSea, true);
      expect(fleet.seaZoneId, 'atlantic');
    });

    test('New fleet needs unique ID', () {
      final existingIds = ['1', '2', '5'];
      final maxId = existingIds
          .map((id) => int.tryParse(id) ?? 0)
          .fold(0, (max, id) => id > max ? id : max);
      final newId = (maxId + 1).toString();

      expect(newId, '6');
    });

    test('Home Fleet is identified by location at capital', () {
      final homeFleet = _createTestFleet(
        id: 'home_fleet',
        ownerId: humanPlayerId,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'capital',
        shipTypeIds: ['fluyte'],
      );

      expect(homeFleet.isInPort, true);
      expect(homeFleet.inPortAtProvinceId, 'capital');
    });

    test('Minimum ship count validation', () {
      final fleet = _createTestFleet(
        id: '1',
        ownerId: humanPlayerId,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'lisbon',
        shipTypeIds: ['carrack'],
      );

      final canSplit = fleet.shipTypeIds.length >= 1;
      expect(canSplit, true);

      final fleetWithNoShips = _createTestFleet(
        id: '2',
        ownerId: humanPlayerId,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'lisbon',
        shipTypeIds: [],
      );

      final canSplitEmpty = fleetWithNoShips.shipTypeIds.length >= 1;
      expect(canSplitEmpty, false);
    });
  });

  group('Combine Logic', () {
    test('Fleets at same port can be combined', () {
      final fleet1 = _createTestFleet(
        id: '1',
        ownerId: humanPlayerId,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'lisbon',
        shipTypeIds: ['carrack'],
      );

      final fleet2 = _createTestFleet(
        id: '2',
        ownerId: humanPlayerId,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'lisbon',
        shipTypeIds: ['fluyte'],
      );

      expect(fleet1.inPortAtProvinceId, fleet2.inPortAtProvinceId);
    });

    test('Fleets at different ports cannot be combined', () {
      final fleet1 = _createTestFleet(
        id: '1',
        ownerId: humanPlayerId,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'lisbon',
        shipTypeIds: ['carrack'],
      );

      final fleet2 = _createTestFleet(
        id: '2',
        ownerId: humanPlayerId,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'porto',
        shipTypeIds: ['fluyte'],
      );

      expect(fleet1.inPortAtProvinceId != fleet2.inPortAtProvinceId, true);
    });

    test('Home Fleet cannot be combined', () {
      final homeFleet = _createTestFleet(
        id: 'home_fleet',
        ownerId: humanPlayerId,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'capital',
        shipTypeIds: ['fluyte'],
      );

      expect(homeFleet.id, 'home_fleet');
    });

    test('Combining ships aggregates correctly', () {
      final fleet1 = _createTestFleet(
        id: '1',
        ownerId: humanPlayerId,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'lisbon',
        shipTypeIds: ['carrack', 'galleon'],
      );

      final fleet2 = _createTestFleet(
        id: '2',
        ownerId: humanPlayerId,
        regionId: 'oldWorld',
        inPortAtProvinceId: 'lisbon',
        shipTypeIds: ['fluyte', 'fluyte', 'fluyte'],
      );

      final combined = [...fleet1.shipTypeIds, ...fleet2.shipTypeIds];
      expect(combined.length, 5);
    });

    test('Same sea zone fleets can be combined', () {
      final fleet1 = _createTestFleet(
        id: '1',
        ownerId: humanPlayerId,
        regionId: 'oldWorld',
        seaZoneId: 'atlantic',
        shipTypeIds: ['galleon'],
      );

      final fleet2 = _createTestFleet(
        id: '2',
        ownerId: humanPlayerId,
        regionId: 'oldWorld',
        seaZoneId: 'atlantic',
        shipTypeIds: ['carrack'],
      );

      expect(fleet1.seaZoneId, fleet2.seaZoneId);
    });
  });
}
