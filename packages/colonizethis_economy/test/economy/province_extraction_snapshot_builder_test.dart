import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void runProvinceExtractionSnapshotScenario(
  ProvinceExtractionSnapshotScenario scenario,
) {
  assertProvinceExtractionSnapshot(scenario);
}

void runProvinceImprovableCountsScenario(
  ProvinceImprovableCountsScenario scenario,
) {
  assertProvinceImprovableCounts(scenario.pin);
}

void runProvinceExtractionProjectionScenario(
  ProvinceExtractionProjectionScenario scenario,
) {
  assertProvinceExtractionProjection(scenario);
}

void main() {
  group('computeProvinceExtractionSnapshots (Refs #4002)', () {
    runLabeledScenarios(
      provinceExtractionSnapshotScenarios(),
      runProvinceExtractionSnapshotScenario,
      labelOf: (s) => s.label,
    );
  });

  group('provinceImprovableResourceTileCounts (Refs #4002)', () {
    runLabeledScenarios(
      provinceImprovableCountsScenarios(),
      runProvinceImprovableCountsScenario,
      labelOf: (s) => s.label,
    );
  });

  group('projectProvinceExtraction (Refs #4064)', () {
    runLabeledScenarios(
      provinceExtractionProjectionScenarios(),
      runProvinceExtractionProjectionScenario,
      labelOf: (s) => s.label,
    );
  });
}
