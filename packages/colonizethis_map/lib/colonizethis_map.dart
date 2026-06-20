/// Topology and tile map generation and visualization.
/// SPEC/program/tile-map-gen-algorithm.md, SPEC/program/tile-map-gen-resources.md, SPEC/program/map-data.md.
library;

// Internal-only generation primitives are not re-exported from the public
// barrel (Refs #3459 AC4): `grid_voronoi.dart` (deterministicNoise /
// assignCellsToNearestSeed), `topology_inference.dart` (inferTopologyFromTileMap),
// and `tile_map_grid_graph.dart` (TileMapGridGraph) are implementation details
// of the generation passes. Same-package tests import them from `src/` directly.
// The `repo.map_public_barrel_surface` lint rule guards against re-export.
export 'src/topology_generator.dart';
export 'src/tile_map_topology_validation.dart';
export 'src/tile_map_generator.dart';
export 'src/tile_map_generator_land_seeds.dart';
export 'src/tile_map_generation_fn.dart';
export 'src/map_partition_gates_exhausted.dart';
export 'src/locked_full_init_tile_map_pair.dart';
export 'src/tile_map_visualization.dart';
export 'src/tile_map_visualization_shared.dart'
    show
        continentSeedMarkerRgb,
        factionOwnershipColorMapForGame,
        factionOwnershipColorMapForNewWorld,
        factionOwnershipColorMapForOldWorld,
        geographicGameWorldLegendResources,
        geographicGameWorldResourceGlyphLetter,
        geographicGameWorldResourceGlyphs,
        kGameWorldMapOwnershipLegendBlurb,
        landSeedMarkerRgb,
        resourceIdToLegendLetter,
        seaZoneLocalIdsFromRegionCells,
        tileMapResourceGlyphs;
export 'src/init_game_map_view_data.dart';
export 'src/sea_zone_centroid_tile.dart';
export 'src/port_icon_placement.dart';
export 'src/gp_ownership_tint.dart';
export 'src/province_label_plate_tint.dart';
export 'src/init_game_map_view_builder.dart';
export 'src/game_world_state_map_visualizer.dart';
export 'src/multi_region_map_rendering.dart';
export 'src/map_format_util.dart';
