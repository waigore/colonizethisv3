// Table-driven tile extraction pipeline scenarios (Refs #3939 phase 3).

import 'tile_extraction_pipeline_expectations.dart';

/// One row in [resolveTileKeyResourceContextScenarios] (Refs #3939 slice 64).
typedef ResolveTileKeyResourceContextScenario = ({
  String label,
  void Function() run,
  String? refs,
});

void runResolveTileKeyResourceContextScenario(
  ResolveTileKeyResourceContextScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for [resolveTileKeyResourceContext].
List<ResolveTileKeyResourceContextScenario>
resolveTileKeyResourceContextScenarios() => [
  resolveTileKeyResourceContextScenario(
    label: 'returns resource context for valid tile key',
    target: ResolveTileKeyResourceContextTarget.validGrain,
  ),
  resolveTileKeyResourceContextScenario(
    label: 'maps commodity id via resource.name consistently',
    target: ResolveTileKeyResourceContextTarget.ironCommodityMapping,
  ),
  resolveTileKeyResourceContextScenario(
    label: 'returns null for invalid or out-of-range keys',
    target: ResolveTileKeyResourceContextTarget.invalidKeys,
  ),
];

/// One row in [resolveTileKeyExtractionContextScenarios] (Refs #3939 slice 64).
typedef ResolveTileKeyExtractionContextScenario = ({
  String label,
  void Function() run,
  String? refs,
});

void runResolveTileKeyExtractionContextScenario(
  ResolveTileKeyExtractionContextScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for [resolveTileKeyExtractionContext].
List<ResolveTileKeyExtractionContextScenario>
resolveTileKeyExtractionContextScenarios() => [
  resolveTileKeyExtractionContextScenario(
    label: 'resolves province from provincesByFullId index',
    target: ResolveTileKeyExtractionContextTarget.fromIndex,
  ),
  resolveTileKeyExtractionContextScenario(
    label: 'falls back to game.worldState when index misses',
    target: ResolveTileKeyExtractionContextTarget.fallbackGame,
  ),
  resolveTileKeyExtractionContextScenario(
    label: 'returns null when province row is missing',
    target: ResolveTileKeyExtractionContextTarget.missingProvince,
  ),
];
