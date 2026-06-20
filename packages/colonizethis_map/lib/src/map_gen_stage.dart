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

/// Context handed to a [MapGenPass.run] invocation (Refs #3574, slice 4).
///
/// Carries the shared generation [params], the pass-specific typed [payload],
/// and an optional [onLog] hook so each family shares the same logging
/// boilerplate while keeping its own input shape via [P].
class MapGenPassContext<P> {
  const MapGenPassContext({
    required this.params,
    required this.payload,
    this.onLog,
  });

  /// Shared generation parameters for the run.
  final TileMapLandSeedParams params;

  /// Pass-specific typed inputs for the family's [MapGenPass.run].
  final P payload;

  /// Optional per-pass log sink; `null` disables logging.
  final void Function(String message)? onLog;

  /// Emits [message] to [onLog] when a listener is attached.
  void log(String message) => onLog?.call(message);
}

/// Uniform pass entry point for tile-map generation service families
/// (Refs #3574, slice 4).
///
/// Families that own a cohesive grid-in/grid-out pass implement this protocol
/// so [TileMapGenerator] can drive them through a single [run] call,
/// parameterized over a typed [payload] ([P]) and result ([R]) while sharing
/// orchestration/logging boilerplate. Families with heterogeneous, multi-pass
/// shapes (for example join-sea: continent joining + terrain jitter + sea-zone
/// subdivision are three distinct passes) remain [MapGenStage]-only and are
/// documented as exempt; at least three of the four families adopt [MapGenPass].
abstract interface class MapGenPass<P, R> implements MapGenStage {
  /// Runs the family's primary generation pass for [ctx].
  R run(MapGenPassContext<P> ctx);
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
