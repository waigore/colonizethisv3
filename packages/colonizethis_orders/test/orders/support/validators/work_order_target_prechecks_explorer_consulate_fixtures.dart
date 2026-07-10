// Explorer consulate precheck fixtures (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

const explorerConsulatePrecheckPlayerId = 'gp1';
const explorerConsulatePrecheckOw = 'oldWorld';
const explorerConsulatePrecheckTribeProvinceId = '$explorerConsulatePrecheckOw|t1';
const explorerConsulatePrecheckTileKey =
    '$explorerConsulatePrecheckTribeProvinceId|0|0';

Game explorerConsulatePrecheckGame() {
  return TestFixtures.minimalGame(
    id: 'g1',
    players: const [
      Player(
        id: explorerConsulatePrecheckPlayerId,
        displayName: 'GP One',
        isHuman: false,
      ),
    ],
    tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe One')],
    overtureStates: const [],
  );
}
