// Table-driven tile extraction pipeline scenarios (Refs #3939 phase 3, #3979).

/// Pins for [resolveTileKeyResourceContext] rows.
enum ResolveTileKeyResourceContextTarget { validGrain, ironCommodityMapping, invalidKeys }

ResolveTileKeyResourceContextScenario resolveTileKeyResourceContextScenario({required String label, required ResolveTileKeyResourceContextTarget target, String? refs}) => (label: label, target: target, refs: refs);

/// One row in [resolveTileKeyResourceContextScenarios] (Refs #3979).
typedef ResolveTileKeyResourceContextScenario = ({
  String label,
  ResolveTileKeyResourceContextTarget target,
  String? refs,
});

/// Canonical scenarios for [resolveTileKeyResourceContext].
// dart format off
List<ResolveTileKeyResourceContextScenario> resolveTileKeyResourceContextScenarios() => [
  resolveTileKeyResourceContextScenario(label: 'returns resource context for valid tile key', target: ResolveTileKeyResourceContextTarget.validGrain),
  resolveTileKeyResourceContextScenario(label: 'maps commodity id via resource.name consistently', target: ResolveTileKeyResourceContextTarget.ironCommodityMapping),
  resolveTileKeyResourceContextScenario(label: 'returns null for invalid or out-of-range keys', target: ResolveTileKeyResourceContextTarget.invalidKeys),
];

/// Pins for [resolveTileKeyExtractionContext] rows.
enum ResolveTileKeyExtractionContextTarget { fromIndex, fallbackGame, missingProvince }

ResolveTileKeyExtractionContextScenario resolveTileKeyExtractionContextScenario({required String label, required ResolveTileKeyExtractionContextTarget target, String? refs}) => (label: label, target: target, refs: refs);

/// One row in [resolveTileKeyExtractionContextScenarios] (Refs #3979).
typedef ResolveTileKeyExtractionContextScenario = ({String label, ResolveTileKeyExtractionContextTarget target, String? refs});

/// Canonical scenarios for [resolveTileKeyExtractionContext].
List<ResolveTileKeyExtractionContextScenario> resolveTileKeyExtractionContextScenarios() => [
  resolveTileKeyExtractionContextScenario(label: 'resolves province from provincesByFullId index', target: ResolveTileKeyExtractionContextTarget.fromIndex),
  resolveTileKeyExtractionContextScenario(label: 'falls back to game.worldState when index misses', target: ResolveTileKeyExtractionContextTarget.fallbackGame),
  resolveTileKeyExtractionContextScenario(label: 'returns null when province row is missing', target: ResolveTileKeyExtractionContextTarget.missingProvince),
];
// dart format on
