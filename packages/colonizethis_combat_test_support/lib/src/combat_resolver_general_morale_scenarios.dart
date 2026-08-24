// Table-driven spy-timer and civilian relocation scenarios (Refs #3865, #4196 slice B).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_combat/src/combat/combat_resolver_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';
import 'scenario_runner.dart';

const _ow = 'oldWorld';

List<RunnableScenario> combatResolverGeneralMoraleAuraScenarios() => [
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
