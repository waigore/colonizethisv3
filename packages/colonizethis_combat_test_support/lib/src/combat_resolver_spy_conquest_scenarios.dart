// Table-driven spy-timer and civilian relocation scenarios (Refs #3865, #4196 slice B).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_combat/src/combat/combat_resolver_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';
import 'scenario_runner.dart';

const _ow = 'oldWorld';

List<RunnableScenario> combatResolverSpyConquestScenarios() => [
  RunnableScenario(
    scenarioId: 'crsc-spy-timer-cleared',
    label: 'combat conquest clears Spy timer for new owner province',
    run: () {
      const provinceId = '$_ow|P1';
      const tileKey = '$_ow|P1|0|0';

      final game = combatSpyTimerGame(
        provinceId: provinceId,
        regionId: _ow,
        defenderOwnerId: 'def',
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
        ],
        playerVisibilityByTile: const {
          'att': {tileKey: 'fullyVisible'},
        },
        spyRevealTurnsByPlayer: const {
          'att': {provinceId: 3},
        },
        tileKeysByRegionAndProvince: const {
          _ow: {
            provinceId: [tileKey],
          },
        },
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
      final province = after.worldState.oldWorld.provinces
          .where((p) => p.id == provinceId)
          .first;
      expect(province.ownerId, 'att');
      expect(after.worldState.spyRevealTurnsByPlayer['att'], isNull);
      expect(
        after.worldState.playerVisibilityByTile['att']?[tileKey],
        'fullyVisible',
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'crsc-purchased-land-cleared',
    label: 'combat conquest clears purchased land for conquered province',
    run: () {
      const provinceId = '$_ow|P1';
      const tileKey = '$_ow|P1|0|0';

      final game = combatResolverMinimalGame(
        players: const [
          Player(id: 'gp1', displayName: 'Investor', isHuman: true),
          Player(id: 'gp2', displayName: 'Aggressor', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
        oldWorld: RegionData(
          provinces: const [
            Province(id: provinceId, regionId: _ow, ownerId: 'minor1'),
          ],
          units: [
            Unit(
              id: 'att1',
              type: 'grenadiers',
              ownerId: 'gp2',
              locationProvinceId: provinceId,
            ),
            Unit(
              id: 'def1',
              type: 'peasant_levies',
              ownerId: 'minor1',
              locationProvinceId: provinceId,
            ),
          ],
        ),
        purchasedTilesByTileKey: const {tileKey: 'gp1'},
      );

      const ctx = BattleContext(
        provinceId: provinceId,
        regionId: _ow,
        defenderFactionId: 'minor1',
        defenderUnitIds: ['def1'],
        attackers: [
          AttackingSide(factionId: 'gp2', unitIds: ['att1'], generalMedals: 0),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      final after = resolveBattleContext(game, ctx);
      final province = after.worldState.oldWorld.provinces
          .where((p) => p.id == provinceId)
          .first;
      expect(province.ownerId, 'gp2');
      expect(
        after.worldState.purchasedTilesByTileKey.containsKey(tileKey),
        isFalse,
      );
    },
  ),
];
