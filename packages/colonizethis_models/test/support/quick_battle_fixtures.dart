import 'package:colonizethis_models/colonizethis_models.dart';

/// Full quick-battle input fixture for JSON round-trip coverage.
QuickBattleInput sampleQuickBattleInput() => const QuickBattleInput(
      attackerFactionId: 'A',
      defenderFactionId: 'D',
      provinceId: 'r1|p1',
      regionId: 'r1',
      attackerDeployment: QuickBattleDeployment(
        groups: [
          QuickBattleGroup(
            lane: QuickBattleLane.left,
            line: QuickBattleLine.front,
            unitIds: ['a1'],
          ),
        ],
      ),
      defenderDeployment: QuickBattleDeployment(
        groups: [
          QuickBattleGroup(
            lane: QuickBattleLane.right,
            line: QuickBattleLine.support,
            unitIds: ['d1'],
          ),
        ],
      ),
      fortLevel: 2,
      emplacedGuns: [
        QuickBattleEmplacedGun(
          id: 'g1',
          maxHp: 10,
          hp: 10,
          attackStrength: 3,
          defenseStrength: 5,
          rng: 2,
        ),
      ],
      provinceTerrain: 'hills',
      seed: 99,
      maxRounds: 4,
      attackerLeaderMultiplier: 1.2,
      defenderLeaderMultiplier: 0.9,
      attackerCavalryShare: 0.3,
      defenderCavalryShare: 0.1,
      attackerGeneralMedals: 2,
      defenderGeneralMedals: 1,
    );
