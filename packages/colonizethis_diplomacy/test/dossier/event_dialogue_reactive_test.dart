// Tests for reactive event dialogue (forts on border, human attack)
// and additional event/reactive situations (tech, capital, colony, spies).
// Battles / era / negotiation live in event_dialogue_test.dart.
// SPEC/ai/dialogue-and-mood.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('dialogueEventsForReactiveFortsOnBorder', () {
    for (final scenario in eventDialogueReactiveScenarios().take(3)) {
      test(scenario.label, () => runEventDialogueReactiveScenario(scenario));
    }
  });

  group('dialogueEventsForReactiveHumanAttack', () {
    for (final scenario in eventDialogueReactiveScenarios().skip(3).take(3)) {
      test(scenario.label, () => runEventDialogueReactiveScenario(scenario));
    }
  });

  group('additional event/reactive situations', () {
    for (final scenario in eventDialogueReactiveScenarios().skip(6)) {
      test(scenario.label, () => runEventDialogueReactiveScenario(scenario));
    }
  });
}
