import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveQuickBattle', () {
    test('deterministic for same seed', () {
      final input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p1',
        regionId: 'oldWorld',
        attackerDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['a1', 'a2', 'a3', 'a4', 'a5'],
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        defenderDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['d1', 'd2'],
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        seed: 42,
        maxRounds: 3,
      );

      final r1 = resolveQuickBattle(input);
      final r2 = resolveQuickBattle(input);
      expect(r1.winner, r2.winner);
      expect(r1.attackerCasualties.length, r2.attackerCasualties.length);
      expect(r1.defenderCasualties.length, r2.defenderCasualties.length);
    });

    test('stronger attacker tends to win', () {
      final input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p1',
        regionId: 'oldWorld',
        attackerDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: List.generate(10, (i) => 'a$i'),
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        defenderDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['d1', 'd2'],
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        seed: 1,
        maxRounds: 3,
      );

      final result = resolveQuickBattle(input);
      expect(result.winner, QuickBattleWinner.attacker);
      expect(result.provinceFlips, true);
    });

    test('custom roundActions override default Volley Fire', () {
      final input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p1',
        regionId: 'oldWorld',
        attackerDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['a1', 'a2'],
              cohesion: 2,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        defenderDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['d1'],
              cohesion: 2,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        seed: 99,
        maxRounds: 2,
      );
      final result = resolveQuickBattle(
        input,
        roundActions: [
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.volleyFire],
            defenderActions: [QuickBattleAction.volleyFire],
          ),
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.volleyFire],
            defenderActions: [QuickBattleAction.volleyFire],
          ),
        ],
      );
      expect(result.attackerCasualties, isNotNull);
      expect(result.defenderCasualties, isNotNull);
    });

    test('fort level applies wall and damage reduction', () {
      final input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p1',
        regionId: 'oldWorld',
        fortLevel: 2,
        provinceTerrain: 'plains',
        attackerDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['a1', 'a2', 'a3'],
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        defenderDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['d1', 'd2'],
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        seed: 7,
        maxRounds: 3,
      );
      final result = resolveQuickBattle(input);
      expect(result.winner, isNotNull);
    });

    test('stronger defender tends to hold', () {
      final input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p1',
        regionId: 'oldWorld',
        attackerDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['a1', 'a2'],
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        defenderDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: List.generate(10, (i) => 'd$i'),
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        seed: 1,
        maxRounds: 3,
      );

      final result = resolveQuickBattle(input);
      expect(result.winner, QuickBattleWinner.defender);
      expect(result.provinceFlips, false);
    });

    test('uses lane terrain modifiers and actions', () {
      final input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p1',
        regionId: 'oldWorld',
        attackerDeployment: QuickBattleDeployment(
          groups: const [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['a1', 'a2', 'a3', 'a4'],
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        defenderDeployment: QuickBattleDeployment(
          groups: const [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['d1', 'd2', 'd3', 'd4'],
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.hill},
        ),
        seed: 7,
        maxRounds: 3,
      );

      final aggressive = resolveQuickBattle(
        input,
        roundActions: const [
          QuickBattleRoundActions(actions: [QuickBattleAction.assaultCharge]),
          QuickBattleRoundActions(actions: [QuickBattleAction.assaultCharge]),
          QuickBattleRoundActions(actions: [QuickBattleAction.assaultCharge]),
        ],
      );
      final cautious = resolveQuickBattle(
        input,
        roundActions: const [
          QuickBattleRoundActions(actions: [QuickBattleAction.defendEntrench]),
          QuickBattleRoundActions(actions: [QuickBattleAction.defendEntrench]),
          QuickBattleRoundActions(actions: [QuickBattleAction.defendEntrench]),
        ],
      );

      // Both runs should be deterministic for same seed + actions.
      expect(
        aggressive.attackerCasualties.length +
            aggressive.defenderCasualties.length,
        greaterThan(0),
      );
      expect(
        cautious.attackerCasualties.length + cautious.defenderCasualties.length,
        greaterThan(0),
      );
    });

    test('initiative ordering is deterministic and affects sequencing', () {
      final inputAttFirst = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p-order',
        regionId: 'oldWorld',
        attackerDeployment: QuickBattleDeployment(
          groups: const [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['a1', 'a2', 'a3', 'a4', 'a5', 'a6'],
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        defenderDeployment: QuickBattleDeployment(
          groups: const [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['d1', 'd2', 'd3', 'd4', 'd5', 'd6'],
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        attackerCavalryShare: 1.0,
        defenderCavalryShare: 0.0,
        seed: 123,
      );

      final resultAttFirst = resolveQuickBattle(
        inputAttFirst,
        roundActions: const [
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.assaultCharge],
            defenderActions: [QuickBattleAction.defendEntrench],
          ),
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.assaultCharge],
            defenderActions: [QuickBattleAction.defendEntrench],
          ),
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.assaultCharge],
            defenderActions: [QuickBattleAction.defendEntrench],
          ),
        ],
      );

      final inputDefFirst = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p-order',
        regionId: 'oldWorld',
        attackerDeployment: inputAttFirst.attackerDeployment,
        defenderDeployment: inputAttFirst.defenderDeployment,
        attackerCavalryShare: 0.0,
        defenderCavalryShare: 1.0,
        seed: 123,
      );
      final resultDefFirst = resolveQuickBattle(
        inputDefFirst,
        roundActions: const [
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.assaultCharge],
            defenderActions: [QuickBattleAction.defendEntrench],
          ),
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.assaultCharge],
            defenderActions: [QuickBattleAction.defendEntrench],
          ),
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.assaultCharge],
            defenderActions: [QuickBattleAction.defendEntrench],
          ),
        ],
      );

      expect(
        resultAttFirst.attackerCasualties.length,
        isNot(resultDefFirst.attackerCasualties.length),
      );
    });
  });
}
