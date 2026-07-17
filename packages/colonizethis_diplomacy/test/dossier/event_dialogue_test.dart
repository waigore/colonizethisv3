// Tests for event dialogue (battle result, era change, negotiation).
// Reactive and additional event-dialogue rules live in
// event_dialogue_reactive_test.dart.
// SPEC/ai/dialogue-and-mood.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('dialogueEventsForLandBattleResult', () {
    for (final scenario in eventDialogueCoreLandBattleScenarios()) {
      test(scenario.label, () => runEventDialogueScenario(scenario));
    }
  });

  group('dialogueEventsForNavalBattleResult', () {
    for (final scenario in eventDialogueCoreNavalBattleScenarios()) {
      test(scenario.label, () => runEventDialogueScenario(scenario));
    }
  });

  group('eraFromYear', () {
    for (final scenario in eventDialogueCoreEraFromYearScenarios()) {
      test(scenario.label, () => runEventDialogueScenario(scenario));
    }
  });

  group('dialogueEventsForEraChange', () {
    for (final scenario in eventDialogueCoreEraChangeScenarios()) {
      test(scenario.label, () => runEventDialogueScenario(scenario));
    }
  });

  group('dialogueEventForNegotiation', () {
    for (final scenario in eventDialogueCoreNegotiationScenarios()) {
      test(scenario.label, () => runEventDialogueScenario(scenario));
    }
  });
}
