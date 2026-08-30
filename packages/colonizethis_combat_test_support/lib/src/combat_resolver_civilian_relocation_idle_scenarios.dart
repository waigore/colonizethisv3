// Idle-civilian relocation scenarios (Refs #3865, #4196 slice B).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_civilian_relocation_fixtures.dart';
import 'scenario_runner.dart';

List<RunnableScenario> combatResolverIdleCivilianRelocationScenarios() => [
  RunnableScenario(
    scenarioId: 'crsc-relocate-idle-civilian',
    label:
        'combat conquest relocates idle foreign civilian with stale assignment tracking but no currentWork to owner capital',
    run: () {
      const tileKey = '$civilianRelocationOldWorld|P1|0|0';
      const cCapProvince = '$civilianRelocationOldWorld|C1';
      const cCapTile = '$civilianRelocationOldWorld|C1|0|0';
      final game = civilianRelocationConquestGame(
        civilian: Unit(
          id: 'civ1',
          type: kUnitTypeBuilder,
          ownerId: 'civ',
          locationProvinceId: '$civilianRelocationOldWorld|P1',
          tileKey: tileKey,
          status: UnitStatus.idle,
          originTileKey: tileKey,
          assignedTileKey: tileKey,
        ),
      );
      final after = resolveBattleContext(
        game,
        civilianRelocationBattleContext(),
      );
      final relocated = after.worldState.oldWorld.units
          .where((u) => u.id == 'civ1')
          .single;
      expect(relocated.tileKey, cCapTile);
      expect(relocated.locationProvinceId, cCapProvince);
      expect(relocated.status, UnitStatus.idle);
      expect(relocated.currentWork, isNull);
      expect(relocated.originTileKey, isNull);
      expect(relocated.assignedTileKey, isNull);
    },
  ),
];
