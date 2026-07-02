// Tests for declare-war / offer-peace / treaty-break dossier evidence rules.
// SPEC/ai/hidden-agendas.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('evidenceForDeclareWar', () {
    for (final scenario in evidenceRulesWarPeaceScenarios().take(5)) {
      test(scenario.label, () => runEvidenceRulesScenario(scenario));
    }
  });

  group('evidenceForOfferPeace', () {
    for (final scenario in evidenceRulesWarPeaceScenarios().skip(5).take(3)) {
      test(scenario.label, () => runEvidenceRulesScenario(scenario));
    }
  });

  group('evidenceForDeclareWar treaty-break window', () {
    for (final scenario in evidenceRulesWarPeaceScenarios().skip(8)) {
      test(scenario.label, () => runEvidenceRulesScenario(scenario));
    }
  });
}
