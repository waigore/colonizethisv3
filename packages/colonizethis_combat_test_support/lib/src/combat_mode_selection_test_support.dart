import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

Game capitalSiegeFixtureGame({bool includeAttackerPlayer = false}) {
  return TestFixtures.minimalGame(
    id: 'g1',
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: 'capital',
      ),
      if (includeAttackerPlayer)
        Player(id: 'p2', displayName: 'P2', isHuman: true),
    ],
  );
}

BattleContext capitalSiegeBattleContext({
  required String provinceId,
  required int fortLevel,
}) {
  return BattleContext(
    provinceId: provinceId,
    regionId: 'oldWorld',
    defenderFactionId: 'p1',
    defenderUnitIds: ['u1'],
    attackers: [
      AttackingSide(factionId: 'p2', unitIds: ['u2']),
    ],
    fortLevel: fortLevel,
    terrain: 'plains',
  );
}
