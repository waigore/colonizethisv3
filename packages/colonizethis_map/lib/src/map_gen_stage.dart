import 'tile_map_grid.dart';
import 'tile_map_land_seed_contract.dart';

/// Common contract for tile-map generation service families (Refs #3459).
///
/// Each service owns one or more grid-in/grid-out passes over a row-major
/// `[height][width]` tile grid. All four generator service families (land seeds,
/// lakes/provinces, join-sea, terrain/resources) implement this interface so
/// pass orchestration shares a uniform params + grid contract.
/// SPEC/program/tile-map-gen-algorithm.md.
abstract interface class MapGenStage {
  /// Shared generation parameters (width, height, seed, and pass-specific knobs).
  TileMapLandSeedParams get params;
}

/// Shared grid-pass helpers for [MapGenStage] service implementations.
extension MapGenGridPass on MapGenStage {
  /// Returns an independent deep copy of [grid] before a mutating pass.
  List<List<T>> snapshotGrid<T>(List<List<T>> grid) => TileMapGrid.copy(grid);

  /// Emits a human-readable pass line when [onLog] is non-null.
  void emitPassLog(void Function(String)? onLog, String message) {
    onLog?.call(message);
  }
}
