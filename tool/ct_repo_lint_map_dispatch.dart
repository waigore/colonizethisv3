// In-process dispatch for `repo.*` map / colonizethis_map manifest rules.
// Extracted from `ct_repo_lint_lib.dart` so that library stays under the
// `repo.dart_file_non_comment_line_size` 1000-NCL ceiling (Refs #4022).

import 'check_colonizethis_map_lib_pipe_split.dart';
import 'check_map_gen_no_image_import.dart';
import 'check_map_gen_stage_protocol.dart';
import 'check_map_grid_cell_iteration_central.dart';
import 'check_map_grid_ops_central.dart';
import 'check_map_lib_file_size.dart';
import 'check_map_lib_file_size_headroom.dart';
import 'check_map_no_partfile_classes.dart';
import 'check_map_public_barrel_surface.dart';
import 'check_map_region_data_access_central.dart';
import 'check_map_region_dispatch_central.dart';
import 'check_map_render_legend_layout_dedup.dart';
import 'check_map_tile_marker_sort_sot.dart';
import 'check_map_test_file_size.dart';
import 'check_map_test_minimal_game_shared.dart';
import 'check_map_test_no_duplicate_view_fixtures.dart';
import 'check_map_test_run_generation_harness.dart';
import 'check_map_test_shared_topology_fixtures.dart';
import 'check_map_test_view_builder_file_count.dart';
import 'check_tile_map_inline_cardinal_directions.dart';

/// Dispatch helper for `colonizethis_map` package manifest rules. Keeps the
/// main `_tryRunDartRuleInProcess` switch under the
/// `repo.dart_long_string_switches` 49-case ceiling as new map-scoped rules are
/// added (Refs #3574). Returns `null` for non-map rule ids so the caller falls
/// back to the generic dispatch.
int? tryRunMapRuleInProcess({
  required String ruleId,
  required String repoRoot,
}) {
  switch (ruleId) {
    case 'repo.colonizethis_map_lib_pipe_split':
      return runCheckColonizethisMapLibPipeSplit(repoRoot);
    case 'repo.tile_map_inline_cardinal_directions':
      return runCheckTileMapInlineCardinalDirections(repoRoot);
    case 'repo.map_gen_no_image_import':
      return runCheckMapGenNoImageImport(repoRoot);
    case 'repo.map_grid_ops_central':
      return runCheckMapGridOpsCentral(repoRoot);
    case 'repo.map_grid_cell_iteration_central':
      return runCheckMapGridCellIterationCentral(repoRoot);
    case 'repo.map_gen_stage_protocol':
      return runCheckMapGenStageProtocol(repoRoot);
    case 'repo.map_gen_no_new_partfiles':
      return runCheckMapGenNoNewPartfiles(repoRoot);
    case 'repo.map_lib_file_size':
      return runCheckMapLibFileSize(repoRoot);
    case 'repo.map_lib_file_size_headroom':
      return runCheckMapLibFileSizeHeadroom(repoRoot);
    case 'repo.map_public_barrel_surface':
      return runCheckMapPublicBarrelSurface(repoRoot);
    case 'repo.map_region_data_access_central':
      return runCheckMapRegionDataAccessCentral(repoRoot);
    case 'repo.map_region_dispatch_central':
      return runCheckMapRegionDispatchCentral(repoRoot);
    case 'repo.map_test_no_duplicate_view_fixtures':
      return runCheckMapTestNoDuplicateViewFixtures(repoRoot);
    case 'repo.map_test_view_builder_file_count':
      return runCheckMapTestViewBuilderFileCount(repoRoot);
    case 'repo.map_test_shared_topology_fixtures':
      return runCheckMapTestSharedTopologyFixtures(repoRoot);
    case 'repo.map_test_run_generation_harness':
      return runCheckMapTestRunGenerationHarness(repoRoot);
    case 'repo.map_test_minimal_game_shared':
      return runCheckMapTestMinimalGameShared(repoRoot);
    case 'repo.map_test_file_size':
      return runCheckMapTestFileSize(repoRoot);
    case 'repo.map_render_legend_layout_dedup':
      return runCheckMapRenderLegendLayoutDedup(repoRoot);
    case 'repo.map_tile_marker_sort_sot':
      return runCheckMapTileMarkerSortSot(repoRoot);
    default:
      return null;
  }
}
