// Tests for event dialogue (battle result, era change, negotiation).
// Reactive and additional event-dialogue rules live in
// event_dialogue_reactive_test.dart.
// SPEC/ai/dialogue-and-mood.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('dialogueEventsForLandBattleResult', () {
    for (final scenario in eventDialogueCoreScenarios().take(3)) {
      test(scenario.label, () => runEventDialogueScenario(scenario));
    }
  });

  group('dialogueEventsForNavalBattleResult', () {
    for (final scenario in eventDialogueCoreScenarios().skip(3).take(2)) {
      test(scenario.label, () => runEventDialogueScenario(scenario));
    }
  });

  group('eraFromYear', () {
    test(
      eventDialogueCoreScenarios()[5].label,
      () => runEventDialogueScenario(eventDialogueCoreScenarios()[5]),
    );
  });

  group('dialogueEventsForEraChange', () {
    for (final scenario in eventDialogueCoreScenarios().skip(6).take(2)) {
      test(scenario.label, () => runEventDialogueScenario(scenario));
    }
  });

  group('dialogueEventForNegotiation', () {
    for (final scenario in eventDialogueCoreScenarios().skip(8)) {
      test(scenario.label, () => runEventDialogueScenario(scenario));
    }
  });
}
