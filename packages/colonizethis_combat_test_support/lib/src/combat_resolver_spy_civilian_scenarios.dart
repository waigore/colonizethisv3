// Table-driven spy-timer and civilian relocation scenarios (Refs #3865).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_combat/src/combat/combat_resolver_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';
import 'scenario_runner.dart';


const _ow = 'oldWorld';

/// Scenarios for spy timers, purchased land, and civilian relocation.
List<RunnableScenario> combatResolverSpyCivilianScenarios() =>
    [
      ..._combatResolverSpyConquestScenarios(),
      ..._combatResolverCivilianRelocationScenarios(),
      ..._combatResolverGeneralMoraleAuraScenarios(),
    ];

List<RunnableScenario>
_combatResolverSpyConquestScenarios() => [
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

List<RunnableScenario>
_combatResolverCivilianRelocationScenarios() => [
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

List<RunnableScenario>
_combatResolverGeneralMoraleAuraScenarios() => [
  RunnableScenario(
    scenarioId: 'crsc-general-medal-morale-aura',
    label: 'general medals provide morale aura bonus (5% per medal, max 20%)',
    run: () {
      expect(moraleMultiplierForGeneralMedals(0), 1.0);
      expect(moraleMultiplierForGeneralMedals(1), 1.05);
      expect(moraleMultiplierForGeneralMedals(2), 1.10);
      expect(moraleMultiplierForGeneralMedals(3), 1.15);
      expect(moraleMultiplierForGeneralMedals(4), 1.20);
      expect(
        moraleMultiplierForGeneralMedals(5),
        1.20,
        reason: 'capped at 4 medals',
      );
      expect(
        moraleMultiplierForGeneralMedals(-1),
        1.0,
        reason: 'negative clamped to 0',
      );
    },
  ),
];
