import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'resolveTileKeyResourceContext',
    resolveTileKeyResourceContextScenarios(),
    runResolveTileKeyResourceContextScenario,
    labelOf: (s) => s.label,
  );

  runLabeledScenarioGroup(
    'resolveTileKeyExtractionContext',
    resolveTileKeyExtractionContextScenarios(),
    runResolveTileKeyExtractionContextScenario,
    labelOf: (s) => s.label,
  );
}
