import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import 'scenario_runner.dart';


BattleContext _context(List<AttackingSide> attackers) => BattleContext(
  regionId: kRegionOldWorld,
  provinceId: 'oldWorld|p1',
  defenderFactionId: 'd1',
  defenderUnitIds: const [],
  fortLevel: 0,
  terrain: 'field',
  attackers: attackers,
  defenderGeneralId: null,
  defenderGeneralMedals: 0,
);
List<RunnableScenario>
landBattleAttackTreasuryCostForPlayerScenarios() => [
  RunnableScenario(
    scenarioId: 'mae-base-cost',
    label: 'base cost 100 without military tech discounts',
    run: () => expect(
      landBattleAttackTreasuryCostForPlayer(
        const Player(id: 'p1', displayName: 'P1', isHuman: true),
      ),
      100,
    ),
  ),
  RunnableScenario(
    scenarioId: 'mae-tech-discounts',
    label: 'applies multiplicative discounts for machinery and modern funding',
    run: () {
      final p = Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        techUnlocked: const {
          kTechIdIndustrialMachinery: true,
          kTechIdModernMilitaryFunding: true,
        },
      );
      expect(
        landBattleAttackTreasuryCostForPlayer(p),
        (100 * 0.75 * 0.85).ceil(),
      );
    },
  ),
];
List<RunnableScenario>
applyLandBattleAttackTreasuryCostsScenarios() => [
  RunnableScenario(
    scenarioId: 'mae-deducts-one',
    label: 'deducts per attacker Great Power once per battle context',
    run: () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'a1', displayName: 'A1', isHuman: true, treasury: 500),
          Player(id: 'd1', displayName: 'D1', isHuman: false, treasury: 0),
        ],
      );
      expect(
        applyLandBattleAttackTreasuryCosts(
          game,
          _context([
            AttackingSide(
              factionId: 'a1',
              unitIds: const ['u1'],
              generalId: null,
            ),
          ]),
        ).playerById('a1')!.treasury,
        400,
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'mae-deducts-nonfirst',
    label: 'deducts treasury when attacker is not first in players list order',
    run: () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'z1', displayName: 'Z', isHuman: false, treasury: 0),
          Player(id: 'a1', displayName: 'A1', isHuman: true, treasury: 500),
          Player(id: 'y1', displayName: 'Y', isHuman: false, treasury: 0),
        ],
      );
      expect(
        applyLandBattleAttackTreasuryCosts(
          game,
          _context([
            AttackingSide(
              factionId: 'a1',
              unitIds: const ['u1'],
              generalId: null,
            ),
          ]),
        ).playerById('a1')!.treasury,
        400,
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'mae-deducts-distinct',
    label: 'deducts treasury for each distinct Great Power attacker side',
    run: () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'a1', displayName: 'A1', isHuman: true, treasury: 300),
          Player(id: 'a2', displayName: 'A2', isHuman: true, treasury: 400),
          Player(id: 'd1', displayName: 'D1', isHuman: false, treasury: 0),
        ],
      );
      final after = applyLandBattleAttackTreasuryCosts(
        game,
        _context(const [
          AttackingSide(factionId: 'a1', unitIds: ['u1'], generalId: null),
          AttackingSide(factionId: 'a2', unitIds: ['u2'], generalId: null),
        ]),
      );
      expect(after.playerById('a1')!.treasury, 200);
      expect(after.playerById('a2')!.treasury, 300);
    },
  ),
  RunnableScenario(
    scenarioId: 'mae-skip-minor',
    label: 'does not deduct treasury when attacker is not a Great Power',
    run: () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'a1', displayName: 'A1', isHuman: true, treasury: 500),
          Player(id: 'd1', displayName: 'D1', isHuman: false, treasury: 0),
        ],
        minorNations: const [MinorNation(id: 'm1', displayName: 'Minor')],
      );
      expect(
        applyLandBattleAttackTreasuryCosts(
          game,
          _context(const [
            AttackingSide(factionId: 'm1', unitIds: ['u1'], generalId: null),
          ]),
        ).playerById('a1')!.treasury,
        500,
      );
    },
  ),
];
