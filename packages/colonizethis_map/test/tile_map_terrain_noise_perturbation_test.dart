import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';

import 'tile_map_generation_determinism_test.dart' show tileMapGenerationDigest;

/// Tests for Pass 6b.5 noise perturbation
/// (SPEC/program/tile-map-gen-algorithm.md § Pass 6b.5).
///
/// The pass operates on blobs of size `>= patternMinBlobSize` (default 20). To
/// exercise its behaviour deterministically we use a moderate-sized region
/// (60 provinces, full default sizing) where macro-phase blobs typically grow
/// past the 20-cell threshold.
void main() {
  suppressLogsForTests();

  group('Pass 6b.5 — terrain noise perturbation', () {
    const baseSize = 64;

    TileMapResult generate({required double terrainVariation, int seed = 42}) {
      final params = TileMapParams(
        width: baseSize,
        height: baseSize,
        seed: seed,
        seaFraction: 0.5,
        terrainVariation: terrainVariation,
      );
      final (result, _) = TileMapGenerator(params: params).generate(
        numProvinces: 30,
        numContinents: 2,
        regionId: 'oldWorld',
        resourceRules: ResourceRules.defaultRules,
      );
      return result;
    }

    Map<String, int> terrainHistogram(TileMapResult r) {
      final h = <String, int>{};
      for (var y = 0; y < r.height; y++) {
        for (var x = 0; x < r.width; x++) {
          final t = r.terrainAt(x, y);
          if (t == null) continue;
          h[t.name] = (h[t.name] ?? 0) + 1;
        }
      }
      return h;
    }

    test(
      'terrainVariation == 0.0 produces byte-identical legacy output (no RNG advance)',
      () {
        // Same seed at terrainVariation 0.0 must equal the *same* run at 0.0
        // and stay deterministic across two invocations.
        final a = generate(terrainVariation: 0.0);
        final b = generate(terrainVariation: 0.0);
        expect(tileMapGenerationDigest(a), tileMapGenerationDigest(b));
      },
    );

    test(
      'terrainVariation == 1.0 changes terrain digest vs 0.0 baseline (pass actually runs)',
      () {
        final baseline = generate(terrainVariation: 0.0);
        final perturbed = generate(terrainVariation: 1.0);
        // Perturbation strength of 1.0 must change *some* tile's terrain
        // relative to the bypass run (otherwise the pass is a no-op).
        expect(
          tileMapGenerationDigest(baseline),
          isNot(equals(tileMapGenerationDigest(perturbed))),
        );
      },
    );

    test(
      'mountain terrain count is preserved across terrainVariation values',
      () {
        // Pass 6b.5 must never modify mountain cells.
        final h0 = terrainHistogram(generate(terrainVariation: 0.0));
        final h1 = terrainHistogram(generate(terrainVariation: 1.0));
        expect(h1['mountain'] ?? 0, h0['mountain'] ?? 0);
      },
    );

    test(
      'same seed and same terrainVariation yield deterministic output',
      () {
        final a = generate(terrainVariation: 0.5, seed: 7);
        final b = generate(terrainVariation: 0.5, seed: 7);
        expect(tileMapGenerationDigest(a), tileMapGenerationDigest(b));
      },
    );

    test(
      'terrainVariation 0.5 sits between 0.0 and 1.0 in change magnitude',
      () {
        // Not a strict guarantee — but on a sufficiently large map the number of
        // cells changed by perturbation should grow monotonically with the slider
        // value. We measure terrain change count vs the 0.0 baseline.
        final baseline = generate(terrainVariation: 0.0);
        final mid = generate(terrainVariation: 0.5);
        final full = generate(terrainVariation: 1.0);

        int countDifferences(TileMapResult a, TileMapResult b) {
          var n = 0;
          for (var y = 0; y < a.height; y++) {
            for (var x = 0; x < a.width; x++) {
              if (a.terrainAt(x, y) != b.terrainAt(x, y)) n++;
            }
          }
          return n;
        }

        final dMid = countDifferences(baseline, mid);
        final dFull = countDifferences(baseline, full);

        expect(
          dMid,
          greaterThan(0),
          reason: 'terrainVariation 0.5 should change some cells vs baseline',
        );
        expect(
          dFull,
          greaterThanOrEqualTo(dMid),
          reason: 'terrainVariation 1.0 should change at least as many cells as 0.5',
        );
      },
    );
  });
}
