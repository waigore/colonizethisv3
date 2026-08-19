import 'package:colonizethis_app/core/utils/human_units_for_work_target.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('humanUnitsMatchingWorkTarget', () {
    test('returns human units whose type lists the work target', () {
      const playerId = 'h1';
      final game = TestFixtures.minimalGame(
        oldWorld: RegionData(
          units: [
            Unit(
              id: 'explorer-0',
              type: kUnitTypeExplorer,
              ownerId: playerId,
              locationProvinceId: 'oldWorld|p1',
            ),
            Unit(
              id: 'builder-0',
              type: kUnitTypeBuilder,
              ownerId: playerId,
              locationProvinceId: 'oldWorld|p1',
            ),
          ],
        ),
        newWorld: RegionData(
          units: [
            Unit(
              id: 'explorer-1',
              type: kUnitTypeExplorer,
              ownerId: playerId,
              locationProvinceId: 'newWorld|p2',
            ),
            Unit(
              id: 'foreign-explorer',
              type: kUnitTypeExplorer,
              ownerId: 'ai1',
              locationProvinceId: 'newWorld|p2',
            ),
          ],
        ),
      );

      final matched = humanUnitsMatchingWorkTarget(
        game: game,
        playerId: playerId,
        workTarget: kWorkTargetExplore,
      );
      expect(matched.map((u) => u.id), ['explorer-0', 'explorer-1']);
    });

    test('returns empty when unit type is missing from work-target map', () {
      const playerId = 'h1';
      final game = TestFixtures.minimalGame(
        oldWorld: RegionData(
          units: [
            Unit(
              id: 'militia-0',
              type: 'Militia',
              ownerId: playerId,
              locationProvinceId: 'oldWorld|p1',
            ),
          ],
        ),
      );

      expect(
        humanUnitsMatchingWorkTarget(
          game: game,
          playerId: playerId,
          workTarget: kWorkTargetExplore,
        ),
        isEmpty,
      );
    });
  });
}
