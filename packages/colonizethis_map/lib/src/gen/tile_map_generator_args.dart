// Generate-argument validation for [TileMapGenerator].
// SPEC/program/tile-map-gen-algorithm.md.

import '../map_validation_exception.dart';
import 'tile_map_generator_types.dart';

void validateTileMapGenerateArgs(int numProvinces, int numContinents) {
  if (numProvinces < 1) {
    throw MapValidationException('numProvinces must be at least 1');
  }
  if (numContinents < 1) {
    throw MapValidationException('numContinents must be at least 1');
  }
}

Map<String, int> resolveProvinceToContinentForGenerate({
  required int numProvinces,
  required int numContinents,
  List<int>? continentProvinceSizes,
}) {
  if (continentProvinceSizes == null) {
    return buildProvinceToContinentMap(numProvinces, numContinents);
  }
  if (continentProvinceSizes.length != numContinents) {
    throw MapValidationException(
      'continentProvinceSizes.length (${continentProvinceSizes.length}) '
      'must equal numContinents ($numContinents)',
    );
  }
  final sum = continentProvinceSizes.fold<int>(0, (a, b) => a + b);
  if (sum != numProvinces) {
    throw MapValidationException(
      'continentProvinceSizes sum ($sum) must equal numProvinces ($numProvinces)',
    );
  }
  return buildProvinceToContinentMapFromCounts(continentProvinceSizes);
}
