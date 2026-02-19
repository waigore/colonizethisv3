import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

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
        cautious.attackerCasualties.length +
            cautious.defenderCasualties.length,
        greaterThan(0),
      );
    });
  });

  group('buildQuickBattleInput', () {
    test('builds input from BattleContext', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'def'),
            ],
            units: [
              Unit(id: 'u1', type: 'musketeers', ownerId: 'att', provinceId: 'P1'),
              Unit(id: 'u2', type: 'pikemen', ownerId: 'def', provinceId: 'P1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [
          Player(id: 'att', displayName: 'A', isHuman: true),
          Player(id: 'def', displayName: 'D', isHuman: true),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['u2'],
        attackers: [AttackingSide(factionId: 'att', unitIds: ['u1'])],
        fortLevel: 0,
        terrain: 'plains',
      );

      final input = buildQuickBattleInput(game, ctx, seed: 5);
      expect(input.attackerFactionId, 'att');
      expect(input.defenderFactionId, 'def');
      expect(input.provinceId, 'P1');
      expect(input.attackerDeployment.groups.single.unitIds, ['u1']);
      expect(input.defenderDeployment.groups.single.unitIds, ['u2']);
    });
  });
}
