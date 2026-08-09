// Event dialogue: emit DialogueEvent when game events trigger commentary.
// SPEC/ai/dialogue-and-mood.md (event: battle result, era transition, reactive, negotiation),
// SPEC/program/ai-events-and-dossier.md.
// Only AI leaders emit for event/reactive; deterministic given game state and seed.
library;

export 'event_dialogue_events.dart'
    show
        dialogueEventsForCapitalThreatened,
        dialogueEventsForColonyFounded,
        dialogueEventsForEraChange,
        dialogueEventsForLandBattleResult,
        dialogueEventsForNavalBattleResult,
        dialogueEventsForTechDiscovered;
export 'event_dialogue_reactive.dart'
    show
        dialogueEventForNegotiation,
        dialogueEventsForReactiveFortsOnBorder,
        dialogueEventsForReactiveHumanAttack,
        dialogueEventsForReactiveSpiesCaught,
        dialogueEventsForReactiveSpiesDefected,
        dialogueEventsForReactiveTechFirst;
export 'event_dialogue_shared.dart'
    show eraFromYear, kDialogueEras, neighborProvinceLocalIds;
