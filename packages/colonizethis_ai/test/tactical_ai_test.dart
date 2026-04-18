import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('decideQuickBattleActions', () {
    test('returns non-empty actions for minimal input', () {
      const input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p1',
        regionId: 'oldWorld',
        attackerDeployment: QuickBattleDeployment(
          groups: [],
          laneTerrain: {},
        ),
        defenderDeployment: QuickBattleDeployment(
          groups: [],
          laneTerrain: {},
        ),
        fortLevel: 0,
        provinceTerrain: 'plains',
        seed: 0,
        maxRounds: 10,
      );
      const config = AIConfig(
        leaderId: 'test',
        personalityId: 'test',
        hiddenAgendaId: 'warmonger',
      );
      final actions = decideQuickBattleActions(
        input: input,
        nationId: 'att',
        config: config,
        tacticalSeed: 42,
      );
      expect(actions.actions, isNotEmpty);
      expect(actions.actions.length, lessThanOrEqualTo(2));
    });
    test('is deterministic for same seed', () {
      const input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p1',
        regionId: 'oldWorld',
        attackerDeployment: QuickBattleDeployment(groups: [], laneTerrain: {}),
        defenderDeployment: QuickBattleDeployment(groups: [], laneTerrain: {}),
        fortLevel: 0,
        provinceTerrain: 'plains',
        seed: 0,
        maxRounds: 10,
      );
      const config = AIConfig(
        leaderId: 'test',
        personalityId: 'test',
        hiddenAgendaId: 'warmonger',
      );
      final a = decideQuickBattleActions(
        input: input,
        nationId: 'att',
        config: config,
        tacticalSeed: 99,
      );
      final b = decideQuickBattleActions(
        input: input,
        nationId: 'att',
        config: config,
        tacticalSeed: 99,
      );
      expect(a.actions, b.actions);
    });
    test('prefers Volley Fire or Defend when outmatched (we are defender, weaker)', () {
      const input = QuickBattleInput(
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
          laneTerrain: {'center_front': QuickBattleLaneTerrain.open},
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
          laneTerrain: {'center_front': QuickBattleLaneTerrain.open},
        ),
        fortLevel: 0,
        provinceTerrain: 'plains',
        seed: 0,
        maxRounds: 10,
        attackerLeaderMultiplier: 1.0,
        defenderLeaderMultiplier: 1.0,
      );
      const config = AIConfig(
        leaderId: 'test',
        personalityId: 'test',
        hiddenAgendaId: 'warmonger',
      );
      for (var i = 0; i < 20; i++) {
        final actions = decideQuickBattleActions(
          input: input,
          nationId: 'def',
          config: config,
          tacticalSeed: 1000 + i,
        );
        expect(actions.actions, isNotEmpty);
        final hasDefensive = actions.actions.any((a) =>
            a == QuickBattleAction.volleyFire ||
            a == QuickBattleAction.defendEntrench);
        expect(hasDefensive, isTrue);
      }
    });
    test('prefers Maneuver or Fall Back when we have damaged groups', () {
      const input = QuickBattleInput(
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
          laneTerrain: {'center_front': QuickBattleLaneTerrain.open},
        ),
        defenderDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['d1', 'd2', 'd3'],
              cohesion: 1,
            ),
          ],
          laneTerrain: {'center_front': QuickBattleLaneTerrain.open},
        ),
        fortLevel: 0,
        provinceTerrain: 'plains',
        seed: 0,
        maxRounds: 10,
      );
      const config = AIConfig(
        leaderId: 'test',
        personalityId: 'test',
        hiddenAgendaId: 'warmonger',
      );
      for (var i = 0; i < 20; i++) {
        final actions = decideQuickBattleActions(
          input: input,
          nationId: 'def',
          config: config,
          tacticalSeed: 2000 + i,
        );
        final hasManeuverOrFallBack = actions.actions.any((a) =>
            a == QuickBattleAction.maneuver ||
            a == QuickBattleAction.fallBackRefuseFlank);
        expect(hasManeuverOrFallBack, isTrue);
      }
    });
    test('prefers Assault/Charge when enemy disrupted and terrain favorable', () {
      const input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p1',
        regionId: 'oldWorld',
        attackerDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['a1', 'a2', 'a3', 'a4'],
              cohesion: 3,
            ),
          ],
          laneTerrain: {'center_front': QuickBattleLaneTerrain.hill},
        ),
        defenderDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['d1'],
              cohesion: 1,
            ),
          ],
          laneTerrain: {'center_front': QuickBattleLaneTerrain.open},
        ),
        fortLevel: 0,
        provinceTerrain: 'plains',
        seed: 0,
        maxRounds: 10,
      );
      const config = AIConfig(
        leaderId: 'test',
        personalityId: 'militant',
        hiddenAgendaId: 'warmonger',
      );
      for (var i = 0; i < 20; i++) {
        final actions = decideQuickBattleActions(
          input: input,
          nationId: 'att',
          config: config,
          tacticalSeed: 3000 + i,
        );
        expect(
          actions.actions.contains(QuickBattleAction.assaultCharge),
          isTrue,
        );
      }
    });
  });
}
