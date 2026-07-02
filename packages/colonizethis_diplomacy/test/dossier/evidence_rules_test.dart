// Tests for battle-victory and research/spy dossier evidence rules.
// Diplomacy / war-peace / isolationist rules live in sibling files:
//  - evidence_rules_war_peace_test.dart
//  - evidence_rules_isolationist_test.dart
// SPEC/ai/hidden-agendas.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('evidenceForLandBattleVictory', () {
    for (final scenario in evidenceRulesBattleAndMirrorScenarios().take(4)) {
      test(scenario.label, () => runEvidenceRulesScenario(scenario));
    }
  });

  group('evidenceForNavalBattleVictory', () {
    for (final scenario in evidenceRulesBattleAndMirrorScenarios().skip(4).take(2)) {
      test(scenario.label, () => runEvidenceRulesScenario(scenario));
    }
  });

  group('evidenceForEnvyResearchMirror', () {
    for (final scenario in evidenceRulesBattleAndMirrorScenarios().skip(6)) {
      test(scenario.label, () => runEvidenceRulesScenario(scenario));
    }
  });
}
