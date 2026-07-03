// Tests for isolationist call-to-arms refusal evidence rule.
// SPEC/ai/hidden-agendas.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('evidenceForIsolationistCallToArmsRefuse', () {
    for (final scenario in evidenceRulesIsolationistScenarios()) {
      test(scenario.label, () => runEvidenceRulesScenario(scenario));
    }
  });
}
