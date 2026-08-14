// Ported from colonizethis_logic (Refs #4090 Slice C).
import 'package:colonizethis_test/test.dart';

import 'support/game_setup_variants_and_naming_additional_relations_scenarios.dart';
import 'support/game_setup_variants_and_naming_additional_sea_zone_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('GameSetup (additional naming coverage)', () {
    runLabeledScenarios([
      ...gameSetupVariantsAndNamingAdditionalRelationsScenarios(),
      ...gameSetupVariantsAndNamingAdditionalSeaZoneScenarios(),
    ], runRunnableScenario);
  });
}
