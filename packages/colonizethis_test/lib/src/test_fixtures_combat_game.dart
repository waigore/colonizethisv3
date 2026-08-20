import 'package:colonizethis_models/colonizethis_models.dart';

import 'test_fixtures_game_core.dart';
import 'test_fixtures_world_state.dart';

/// Combat-scenario [Game] factory for [TestFixtures].
abstract final class TestFixturesCombatGame {
  TestFixturesCombatGame._();

  /// Adjacent provinces with default military regiments (combat integration tests).
  static Game combatGame({
    String regionId = 'oldWorld',
    String player1Id = 'p1',
    String player2Id = 'p2',
    String localProvince1 = 'p1',
    String localProvince2 = 'p2',
    Unit? unit1,
    Unit? unit2,
  }) {
    final pid1 = '$regionId|$localProvince1';
    final pid2 = '$regionId|$localProvince2';
    final u1 = unit1 ??
        Unit(
          id: 'u1',
          type: 'grenadiers',
          ownerId: player1Id,
          locationProvinceId: pid1,
        );
    final u2 = unit2 ??
        Unit(
          id: 'u2',
          type: 'grenadiers',
          ownerId: player2Id,
          locationProvinceId: pid2,
        );
    return TestFixturesGameCore.minimalGame(
      players: [
        Player(
          id: player1Id,
          displayName: 'P1',
          isHuman: true,
        ),
        Player(
          id: player2Id,
          displayName: 'P2',
          isHuman: false,
        ),
      ],
      worldState: TestFixturesWorldState.worldStateAtOrdersPhase(
        oldWorld: RegionData(
          provinces: [
            Province(id: pid1, regionId: regionId, ownerId: player1Id),
            Province(id: pid2, regionId: regionId, ownerId: player2Id),
          ],
          units: [u1, u2],
        ),
      ),
    );
  }
}
