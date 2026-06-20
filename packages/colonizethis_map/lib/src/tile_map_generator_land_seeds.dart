/// Pass 2–3: land seed placement and assignment.
///
/// SPEC/program/tile-map-gen-algorithm.md.
///
/// Implementation is split across part files for review-size hygiene:
/// shared Voronoi/buffer helpers, placement (seed-before-assignment),
/// organic interleaved placement+Voronoi+coastline driver, and coastline
/// growth helpers. The public surface here is intentionally a thin facade
/// so callers continue to depend on a single import and the
/// `TileMapGenLandSeeds` class.
library tile_map_generator_land_seeds;

import 'dart:math';

import 'grid_voronoi.dart';
import 'map_gen_pass_payloads.dart';
import 'map_gen_stage.dart';
import 'tile_map_directions.dart';
import 'tile_map_distance_sentinels.dart';
import 'tile_map_land_seed_contract.dart';
import 'tile_map_grid.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_manhattan_distance_maps.dart';
import 'tile_map_manhattan_distance_transform.dart';
import 'tile_map_province_budget.dart';

part 'tile_map_generator_land_seeds_shared_part.dart';
part 'tile_map_generator_land_seeds_placement_part.dart';
part 'tile_map_generator_land_seeds_organic_part.dart';
part 'tile_map_generator_land_seeds_coast_part.dart';

/// Pass 2–3: land seed placement and assignment (organic and seed-before-assignment).
class TileMapGenLandSeeds
    implements MapGenPass<LandSeedPassPayload, LandSeedPassResult> {
  TileMapGenLandSeeds(this.params);

  @override
  final TileMapLandSeedParams params;

  /// Uniform pass entry: places land seeds and assigns land for Pass 2–3,
  /// selecting the organic or seed-before-assignment path from
  /// [LandSeedPassPayload.seedBeforeAssignment]. Behaviour matches the prior
  /// inline orchestration (Refs #3574, slice 4).
  @override
  LandSeedPassResult run(MapGenPassContext<LandSeedPassPayload> ctx) {
    final payload = ctx.payload;
    if (payload.seedBeforeAssignment) {
      final placed = placeLandSeeds(payload.provinceToContinent, payload.rnd);
      final continentSeeds = placed.$1;
      final landSeeds = placed.$2;
      final continentBySeedIndex = placed.$3;
      ctx.log(
        'Pass 2: Continent seeds ${continentSeeds.length}, '
        'land seeds ${landSeeds.length}',
      );
      final assignedGrid = assignLandByLandSeeds(
        payload.grid,
        landSeeds,
        continentBySeedIndex,
        payload.provinceToContinent,
        payload.seaZoneId,
      );
      return LandSeedPassResult(
        grid: assignedGrid,
        continentSeeds: continentSeeds,
        landSeeds: landSeeds,
        continentBySeedIndex: continentBySeedIndex,
      );
    }
    final organic = placeLandSeedsOrganic(
      payload.grid,
      payload.provinceToContinent,
      payload.seaZoneId,
      payload.rnd,
    );
    ctx.log(
      'Pass 2–3 (organic): Continent seeds ${organic.$1.length}, '
      'land seeds ${organic.$2.length}',
    );
    return LandSeedPassResult(
      grid: organic.$4,
      continentSeeds: organic.$1,
      landSeeds: organic.$2,
      continentBySeedIndex: organic.$3,
    );
  }

  /// One continent seed per continent; then a cluster of land-shape seeds per continent (K from province count). No province seeds yet.
  (List<(int x, int y)>, List<(int x, int y)>, List<int>) placeLandSeeds(
    Map<String, int> provinceToContinent,
    Random rnd,
  ) => _placeLandSeedsImpl(params, provinceToContinent, rnd);

  /// Organic land growing: interleaved seed placement + small Voronoi + coastline growth.
  /// Returns (continentSeeds, landSeeds, continentBySeedIndex, grid).
  (List<(int x, int y)>, List<(int x, int y)>, List<int>, List<List<String>>)
  placeLandSeedsOrganic(
    List<List<String>> grid,
    Map<String, int> provinceToContinent,
    String seaZoneId,
    Random rnd,
  ) => _placeLandSeedsOrganicImpl(
    params,
    grid,
    provinceToContinent,
    seaZoneId,
    rnd,
  );

  /// Per-continent land budget; assign to [kTileMapLandSentinel] by smallest effective
  /// distance (with optional Voronoi noise). Each cell at most one continent.
  List<List<String>> assignLandByLandSeeds(
    List<List<String>> grid,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    Map<String, int> provinceToContinent,
    String seaZoneId,
  ) => _assignLandByLandSeedsImpl(
    params,
    grid,
    landSeeds,
    continentBySeedIndex,
    provinceToContinent,
    seaZoneId,
  );
}
