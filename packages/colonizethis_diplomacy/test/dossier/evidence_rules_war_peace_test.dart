// Tests for declare-war / offer-peace / treaty-break dossier evidence rules.
// SPEC/ai/hidden-agendas.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_test/test.dart';

import 'evidence_rules_scenarios.dart';

void main() {
  group('evidenceForDeclareWar', () {
    for (final scenario in evidenceRulesDeclareWarScenarios()) {
      test(scenario.label, () => runEvidenceRulesScenario(scenario));
    }
  });

  group('evidenceForOfferPeace', () {
    for (final scenario in evidenceRulesOfferPeaceScenarios()) {
      test(scenario.label, () => runEvidenceRulesScenario(scenario));
    }
  });

  group('evidenceForDeclareWar treaty-break window', () {
    for (final scenario in evidenceRulesTreatyBreakWindowScenarios()) {
      test(scenario.label, () => runEvidenceRulesScenario(scenario));
    }
  });
}
