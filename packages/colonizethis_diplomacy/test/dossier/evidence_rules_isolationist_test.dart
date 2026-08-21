// Tests for isolationist call-to-arms refusal evidence rule.
// SPEC/ai/hidden-agendas.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_test/test.dart';

import 'evidence_rules_scenario_helpers.dart';
import 'evidence_rules_war_peace_scenarios.dart';

void main() {
  group('evidenceForIsolationistCallToArmsRefuse', () {
    for (final scenario in evidenceRulesIsolationistScenarios()) {
      test(scenario.label, () => runEvidenceRulesScenario(scenario));
    }
  });
}
