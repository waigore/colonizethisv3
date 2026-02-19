import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

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
        personalityId: 'militant',
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
        personalityId: 'militant',
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
  });
}
