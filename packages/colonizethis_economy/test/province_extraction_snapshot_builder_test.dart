import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  group('computeProvinceExtractionSnapshots (Refs #4002)', () {
    runLabeledScenarios(
      provinceExtractionSnapshotScenarios(),
      runProvinceExtractionSnapshotScenario,
      labelOf: (s) => s.label,
    );
  });

  group('provinceImprovableResourceTileCounts (Refs #4002)', () {
    runLabeledScenarios(
      provinceImprovableCountsScenarios(),
      runProvinceImprovableCountsScenario,
      labelOf: (s) => s.label,
    );
  });

  test(
    'negative: out-of-bounds improvement keys do not throw during snapshot build',
    () {
      // Combat-style stub maps can list improvements outside the grid
      // (e.g. y=1 on a height-1 map). Snapshot scan must skip them.
      const inBounds = 'oldWorld|p1|0|0';
      const outOfBounds = 'oldWorld|p1|0|1';
      final tileState = tileStateFromSpecs([
        const TileImprovementSpec(inBounds, 2, 1),
        const TileImprovementSpec(outOfBounds, 2, 1),
      ]);
      final game = resourceExtractorGame(tileState: tileState);
      final map = TileMapResult(
        width: 2,
        height: 1,
        grid: const [
          ['p1', 'p1'],
        ],
        resourceGrid: const [
          [Resource.grain, Resource.grain],
        ],
      );
      final snaps = computeProvinceExtractionSnapshots(
        game: game,
        tileMapByRegion: {'oldWorld': map},
        connectivityResult: {
          'pl1': ConnectivityResult(
            connected: {inBounds},
            pathTransportCap: const {inBounds: 4},
          ),
        },
        techCapForPlayer: (_) => 4,
      );
      final grain = snaps['oldWorld|p1']!.byCommodity['grain']!;
      expect(grain.effective, 2);
      expect(grain.full, 2);
      expect(grain.tileKeys, [inBounds]);
    },
  );
}
