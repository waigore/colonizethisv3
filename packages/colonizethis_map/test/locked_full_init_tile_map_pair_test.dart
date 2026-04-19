import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_map/colonizethis_map.dart';

void main() {
  test(
    'generateLockedFullInitTileMapPair satisfies OW/NW partition gates',
    () {
      final cfg = GameSetupConfig.defaultConfig;
      expect(cfg.isLockedFullInitProfile, isTrue);
      final r = generateLockedFullInitTileMapPair(
        config: cfg,
        effectiveSeed: cfg.seed,
      );
      final owN = provincePpNeighbours(r.topoOw);
      expect(oldWorldPartitionMatchesLockedProfile(r.topoOw), isTrue);
      expect(
        lockedOldWorldRoleFeasibilityHolds(
          topology: r.topoOw,
          neighbours: owN,
        ),
        isTrue,
      );
      final nwN = provincePpNeighbours(r.topoNw);
      expect(newWorldPartitionMatchesLockedProfile(r.topoNw), isTrue);
      expect(
        lockedNewWorldRoleFeasibilityHolds(
          topology: r.topoNw,
          neighbours: nwN,
        ),
        isTrue,
      );
    },
    timeout: Timeout.factor(4),
  );
}
