import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/src/gen/terrain_dominance.dart';
import 'package:colonizethis_test/test.dart';

/// Unit tests for the shared terrain dominance helper that deduplicates the
/// argmax previously implemented separately in the terrain-assignment cleanup
/// and the terrain-jitter pass (Refs #3588).
void main() {
  group('mostFrequentTerrain', () {
    test('returns the terrain with the strictly greatest count', () {
      final counts = <TerrainType, int>{
        TerrainType.plains: 2,
        TerrainType.desert: 5,
        TerrainType.hills: 1,
      };

      expect(mostFrequentTerrain(counts), TerrainType.desert);
    });

    test('returns the only key for a single-entry map', () {
      final counts = <TerrainType, int>{TerrainType.hills: 7};

      expect(mostFrequentTerrain(counts), TerrainType.hills);
    });

    test('on a tie returns the first-inserted key among the maxima', () {
      final desertFirst = <TerrainType, int>{
        TerrainType.desert: 3,
        TerrainType.plains: 3,
        TerrainType.hills: 1,
      };
      final plainsFirst = <TerrainType, int>{
        TerrainType.plains: 3,
        TerrainType.desert: 3,
        TerrainType.hills: 1,
      };

      expect(mostFrequentTerrain(desertFirst), TerrainType.desert);
      expect(mostFrequentTerrain(plainsFirst), TerrainType.plains);
    });

    test('does not pick a later key that merely equals the running max', () {
      final counts = <TerrainType, int>{
        TerrainType.plains: 4,
        TerrainType.desert: 4,
      };

      expect(mostFrequentTerrain(counts), TerrainType.plains);
    });
  });
}
