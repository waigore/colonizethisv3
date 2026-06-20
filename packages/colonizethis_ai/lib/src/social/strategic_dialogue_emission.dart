// Optional strategic dialogue/mood emission on deterministic cadence.
// SPEC/ai/dialogue-and-mood.md § When to emit.

import 'package:colonizethis_data/colonizethis_data.dart'
    show kDialogueTurnsBetweenComments;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'mood_state_machine.dart';

/// Emits optional agenda-flavoured dialogue and a matching base [PortraitMoodEvent]
/// when [seeds.dialogueSeed] hits the strategic cadence
/// (`dialogueSeed % kDialogueTurnsBetweenComments == 0`).
void emitStrategicDialogueAndMood({
  required AIConfig config,
  required AISeedBundle seeds,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
}) {
  // Optional dialogue/mood emission (deterministic from dialogueSeed).
  // SPEC/ai/dialogue-and-mood.md § When to emit:
  // Strategic AI may emit optional agenda/comment and base mood once every
  // kDialogueTurnsBetweenComments turns per leader, when
  // `dialogueSeed % kDialogueTurnsBetweenComments == 0`.
  if (onDialogue != null &&
      seeds.dialogueSeed % kDialogueTurnsBetweenComments == 0) {
    onDialogue(
      DialogueEvent(
        leaderId: config.leaderId,
        category: 'agenda',
        situation: 'comment',
        era: 'earlyModern',
        variables: const {},
      ),
    );
  }
  if (onMood != null &&
      seeds.dialogueSeed % kDialogueTurnsBetweenComments == 0) {
    onMood(
      PortraitMoodEvent(
        leaderId: config.leaderId,
        fromMood: kDefaultMood,
        toMood: kDefaultMood,
        durationMs: 0,
      ),
    );
  }
}
