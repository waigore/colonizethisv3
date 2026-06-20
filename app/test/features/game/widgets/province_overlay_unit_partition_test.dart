import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_overlay_unit_partition.dart';

void main() {
  suppressLogsForTests();

  group('partitionProvinceOverlayUnits', () {
    test('partitions military and counts visible foreign civilians', () {
      const provinceId = 'oldWorld|p1';
      const humanPlayerId = 'gp1';
      const other = 'gp2';
      const visibleTile = 'oldWorld|p1|0|0';
      const view = MapTopology();
      final playerView = buildPlayerView(
        Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            playerVisibilityByTile: {
              humanPlayerId: {visibleTile: VisibilityLevel.fullyVisible.name},
            },
          ),
          players: const [
            Player(id: humanPlayerId, displayName: 'Human', isHuman: true),
            Player(id: other, displayName: 'Other', isHuman: false),
          ],
        ),
        view,
        humanPlayerId,
      );
      final units = [
        Unit(
          id: 'm1',
          type: 'peasant_levies',
          ownerId: humanPlayerId,
          locationProvinceId: provinceId,
        ),
        Unit(
          id: 'c1',
          type: kUnitTypeExplorer,
          ownerId: humanPlayerId,
          locationProvinceId: provinceId,
        ),
        Unit(
          id: 'c2',
          type: kUnitTypeMerchant,
          ownerId: other,
          locationProvinceId: provinceId,
          tileKey: visibleTile,
        ),
        Unit(
          id: 'other-prov',
          type: kUnitTypeExplorer,
          ownerId: humanPlayerId,
          locationProvinceId: 'oldWorld|p2',
        ),
      ];

      final result = partitionProvinceOverlayUnits(
        regionUnits: units,
        provinceId: provinceId,
        humanPlayerId: humanPlayerId,
        playerView: playerView,
      );

      expect(result.military.map((u) => u.id), ['m1']);
      expect(result.civilian.map((u) => u.id), ['c1', 'c2']);
      expect(result.visibleCivilianCount, 2);
    });
  });
}
