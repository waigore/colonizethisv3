// Table-driven spy-timer and civilian relocation scenarios (Refs #3865, #4196 slice B).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_combat/src/combat/combat_resolver_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';
import 'scenario_runner.dart';

const _ow = 'oldWorld';

List<RunnableScenario>
combatResolverCivilianRelocationScenarios() => [
  RunnableScenario(
    scenarioId: 'crsc-relocate-working-civilian',
    label:
        'combat conquest relocates illegal foreign civilian in changed province to owner capital',
    run: () {
      const provinceId = '$_ow|P1';
      const tileKey = '$_ow|P1|0|0';
      const cCapProvince = '$_ow|C1';
      const cCapTile = '$_ow|C1|0|0';

      final game = combatResolverMinimalGame(
        players: const [
          Player(id: 'att', displayName: 'Attacker', isHuman: true),
          Player(id: 'def', displayName: 'Defender', isHuman: true),
          Player(
            id: 'civ',
            displayName: 'CivOwner',
            isHuman: false,
            capitalProvinceId: cCapProvince,
            capitalTile: CapitalTile(
              regionId: _ow,
              provinceId: 'C1',
              x: 0,
              y: 0,
            ),
          ),
        ],
        oldWorld: RegionData(
          provinces: const [
            Province(id: provinceId, regionId: _ow, ownerId: 'def'),
            Province(id: cCapProvince, regionId: _ow, ownerId: 'civ'),
          ],
          units: [
            Unit(
              id: 'att1',
              type: 'grenadiers',
              ownerId: 'att',
              locationProvinceId: provinceId,
            ),
            Unit(
              id: 'def1',
              type: 'peasant_levies',
              ownerId: 'def',
              locationProvinceId: provinceId,
            ),
            Unit(
              id: 'civ1',
              type: kUnitTypeBuilder,
              ownerId: 'civ',
              locationProvinceId: provinceId,
              tileKey: tileKey,
              status: UnitStatus.working,
              currentWork: CurrentWork(
                workTarget: kWorkTargetBuildRoad,
                tileKey: tileKey,
                totalTurns: 2,
                remainingTurns: 1,
              ),
              originTileKey: tileKey,
              assignedTileKey: tileKey,
            ),
          ],
        ),
      );

      const ctx = BattleContext(
        provinceId: provinceId,
        regionId: _ow,
        defenderFactionId: 'def',
        defenderUnitIds: ['def1'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['att1'], generalMedals: 0),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      final after = resolveBattleContext(game, ctx);
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
  RunnableScenario(
    scenarioId: 'crsc-relocate-idle-civilian',
    label:
        'combat conquest relocates idle foreign civilian with stale assignment tracking but no currentWork to owner capital',
    run: () {
      const provinceId = '$_ow|P1';
      const tileKey = '$_ow|P1|0|0';
      const cCapProvince = '$_ow|C1';
      const cCapTile = '$_ow|C1|0|0';

      final game = combatResolverMinimalGame(
        players: const [
          Player(id: 'att', displayName: 'Attacker', isHuman: true),
          Player(id: 'def', displayName: 'Defender', isHuman: true),
          Player(
            id: 'civ',
            displayName: 'CivOwner',
            isHuman: false,
            capitalProvinceId: cCapProvince,
            capitalTile: CapitalTile(
              regionId: _ow,
              provinceId: 'C1',
              x: 0,
              y: 0,
            ),
          ),
        ],
        oldWorld: RegionData(
          provinces: const [
            Province(id: provinceId, regionId: _ow, ownerId: 'def'),
            Province(id: cCapProvince, regionId: _ow, ownerId: 'civ'),
          ],
          units: [
            Unit(
              id: 'att1',
              type: 'grenadiers',
              ownerId: 'att',
              locationProvinceId: provinceId,
            ),
            Unit(
              id: 'def1',
              type: 'peasant_levies',
              ownerId: 'def',
              locationProvinceId: provinceId,
            ),
            Unit(
              id: 'civ1',
              type: kUnitTypeBuilder,
              ownerId: 'civ',
              locationProvinceId: provinceId,
              tileKey: tileKey,
              status: UnitStatus.idle,
              originTileKey: tileKey,
              assignedTileKey: tileKey,
            ),
          ],
        ),
      );

      const ctx = BattleContext(
        provinceId: provinceId,
        regionId: _ow,
        defenderFactionId: 'def',
        defenderUnitIds: ['def1'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['att1'], generalMedals: 0),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      final after = resolveBattleContext(game, ctx);
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

