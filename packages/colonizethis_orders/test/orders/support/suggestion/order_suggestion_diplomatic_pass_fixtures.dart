// Fixtures for diplomatic-pass suggestion scenarios (Refs #3949 wave 3).

import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

Game orderSuggestionDiplomaticPassDuplicateOvertureGame() {
  return TestFixtures.minimalGame(
    overtureStates: [
      OvertureState(
        gpId: 'gp1',
        targetId: 'minor1',
        stage: OvertureStage.tradeConsulate,
        sinceTurn: 0,
      ),
      OvertureState(
        gpId: 'gp1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 1,
      ),
      OvertureState(
        gpId: 'gp2',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
}
