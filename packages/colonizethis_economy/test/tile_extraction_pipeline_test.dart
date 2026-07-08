import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'resolveTileKeyResourceContext',
    resolveTileKeyResourceContextScenarios(),
    runResolveTileKeyResourceContextScenario,
  );

  runLabeledScenarioGroup(
    'resolveTileKeyExtractionContext',
    resolveTileKeyExtractionContextScenarios(),
    runResolveTileKeyExtractionContextScenario,
  );
}
