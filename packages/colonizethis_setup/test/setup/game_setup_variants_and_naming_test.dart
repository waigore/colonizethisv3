// Densified via scenario table (Refs #4349 Slice C).
import 'package:colonizethis_test/test.dart';

import 'support/game_setup_variants_and_naming_scenarios.dart'
    show gameSetupVariantsAndNamingScenarios;
import 'support/scenario_runner.dart';

void main() {
  group('GameSetup', () {
    runLabeledScenarios(
      gameSetupVariantsAndNamingScenarios(),
      runRunnableScenario,
    );
  });
}
