// Densified via scenario table (Refs #4349 Slice C).
import 'package:colonizethis_test/test.dart';

import 'support/game_setup_landmass_visibility_and_gp_scenarios.dart'
    show gameSetupLandmassVisibilityAndGpScenarios;
import 'support/scenario_runner.dart';

void main() {
  group('GameSetup', () {
    runLabeledScenarios(
      gameSetupLandmassVisibilityAndGpScenarios(),
      runRunnableScenario,
    );
  });
}
