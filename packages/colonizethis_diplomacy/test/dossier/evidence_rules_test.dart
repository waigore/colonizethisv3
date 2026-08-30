// Tests for battle-victory and research/spy dossier evidence rules.
// Diplomacy / war-peace / isolationist rules live in sibling files:
//  - evidence_rules_war_peace_test.dart
//  - evidence_rules_isolationist_test.dart
// SPEC/ai/hidden-agendas.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_test/test.dart';

import 'evidence_rules_scenario_helpers.dart';
import 'evidence_rules_scenarios.dart';

void main() {
  group('evidenceForLandBattleVictory', () {
    for (final scenario in evidenceRulesLandBattleVictoryScenarios()) {
      test(scenario.label, () => runEvidenceRulesScenario(scenario));
    }
  });

  group('evidenceForNavalBattleVictory', () {
    for (final scenario in evidenceRulesNavalBattleVictoryScenarios()) {
      test(scenario.label, () => runEvidenceRulesScenario(scenario));
    }
  });

  group('evidenceForEnvyResearchMirror', () {
    for (final scenario in evidenceRulesEnvyResearchMirrorScenarios()) {
      test(scenario.label, () => runEvidenceRulesScenario(scenario));
    }
  });
}
