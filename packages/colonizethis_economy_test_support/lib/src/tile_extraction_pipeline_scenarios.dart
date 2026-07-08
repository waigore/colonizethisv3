// Table-driven tile extraction pipeline scenarios (Refs #3939 phase 3).

import 'scenario_runner.dart';
import 'tile_extraction_pipeline_expectations.dart';

/// One row in [resolveTileKeyResourceContextScenarios].
class ResolveTileKeyResourceContextScenario implements RefsScenario {
  const ResolveTileKeyResourceContextScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

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

/// One row in [resolveTileKeyExtractionContextScenarios].
class ResolveTileKeyExtractionContextScenario implements RefsScenario {
  const ResolveTileKeyExtractionContextScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

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
