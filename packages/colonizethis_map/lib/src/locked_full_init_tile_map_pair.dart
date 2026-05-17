import 'package:colonizethis_data/colonizethis_data.dart';

import 'map_partition_gates_exhausted.dart';
import 'region_constants.dart';
import 'tile_map_generator.dart';

const double _kDefaultSeaFraction = 0.6;

/// Maximum generator-side retries for locked full-init OW+NW partition gates (#1834).
const int kMaxLockedFullInitPartitionAttempts = 1024;

/// Generates Old World and New World tile maps whose P–P landmass multisets and
/// feasibility gates match the locked full-init profile (#1830 / #1834).
///
/// Call only when [config.isLockedFullInitProfile] is true.
({TileMapResult tileOw, MapTopology topoOw, TileMapResult tileNw, MapTopology topoNw})
generateLockedFullInitTileMapPair({
  required GameSetupConfig config,
  required int effectiveSeed,
  bool skipFillLakes = false,
  void Function(String)? onLog,
  int maxAttempts = kMaxLockedFullInitPartitionAttempts,
}) {
  if (!config.isLockedFullInitProfile) {
    throw LockedFullInitProfileRequiredException(
      'generateLockedFullInitTileMapPair requires isLockedFullInitProfile',
    );
  }

  final mapGenParams = MapGenerationParams(
    numContinents: config.continentCount,
    seed: effectiveSeed,
    seaFraction: _kDefaultSeaFraction,
  );
  final sizeOW = computeGridSizeFromParams(
    config.numProvincesOldWorld,
    mapGenParams,
  );
  final sizeNW = computeGridSizeFromParams(
    config.numProvincesNewWorld,
    mapGenParams,
  );

  List<int>? lastOw;
  List<int>? lastNw;

  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final owSeed = effectiveSeed + attempt * 9973;
    final nwSeed = effectiveSeed + 1 + attempt * 10007;
    final paramsOW = TileMapParams(
      width: sizeOW.width,
      height: sizeOW.height,
      seed: owSeed,
      seaFraction: _kDefaultSeaFraction,
      skipFillLakes: skipFillLakes,
    );
    final (tileOw, topoOw) = TileMapGenerator(params: paramsOW).generate(
      numProvinces: config.numProvincesOldWorld,
      numContinents: config.continentCount,
      regionId: kRegionOldWorld,
      resourceRules: ResourceRules.defaultRules,
      onLog: onLog,
      continentProvinceSizes: const [13, 13, 17, 17],
    );

    final owNbr = provincePpNeighbours(topoOw);
    lastOw = ppLandComponentSizesSorted(topoOw);
    if (!oldWorldPartitionMatchesLockedProfile(topoOw) ||
        !lockedOldWorldRoleFeasibilityHolds(
          topology: topoOw,
          neighbours: owNbr,
        )) {
      continue;
    }

    final paramsNW = TileMapParams(
      width: sizeNW.width,
      height: sizeNW.height,
      seed: nwSeed,
      seaFraction: _kDefaultSeaFraction,
      skipFillLakes: skipFillLakes,
    );
    final (tileNw, topoNw) = TileMapGenerator(params: paramsNW).generate(
      numProvinces: config.numProvincesNewWorld,
      numContinents: config.continentCount.clamp(
        1,
        config.numProvincesNewWorld,
      ),
      regionId: kRegionNewWorld,
      resourceRules: ResourceRules.defaultRules,
      onLog: onLog,
      continentProvinceSizes: const [6, 6, 9, 9],
    );

    final nwNbr = provincePpNeighbours(topoNw);
    lastNw = ppLandComponentSizesSorted(topoNw);
    if (!newWorldPartitionMatchesLockedProfile(topoNw) ||
        !lockedNewWorldRoleFeasibilityHolds(
          topology: topoNw,
          neighbours: nwNbr,
        )) {
      continue;
    }

    return (tileOw: tileOw, topoOw: topoOw, tileNw: tileNw, topoNw: topoNw);
  }

  throw MapPartitionGatesExhaustedException(
    attempts: maxAttempts,
    lastOwPartition: lastOw,
    lastNwPartition: lastNw,
  );
}
