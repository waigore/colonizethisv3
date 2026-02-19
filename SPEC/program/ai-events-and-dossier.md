# AI Events and Dossier — Implementation (Phase 6)

## Responsibility
Event data models and data flows for dialogue, mood, evidence, and dossier. Behavior rules: [dialogue-and-mood.md](../ai/dialogue-and-mood.md), [ai-dossier.md](../ai/ai-dossier.md), [hidden-agendas.md](../ai/hidden-agendas.md).

## Data Model

### DialogueEvent
Fields: `leaderId`, `category`, `situation`, `era`, `mood?`, `variables` (map string→string). Categories and situations per [dialogue-and-mood.md](../ai/dialogue-and-mood.md).

### PortraitMoodEvent
Fields: `leaderId`, `fromMood`, `toMood`, `durationMs`. Mood values per [dialogue-and-mood.md](../ai/dialogue-and-mood.md).

### EvidenceEntry
Internal record appended when an action matches an evidence rule. Fields: observer id, subject id, agenda type, score delta, turn, description. Not emitted to UI; updates state read by dossier.

## Algorithm / Flow

### Dialogue and Mood
1. AI calls `onDialogue(DialogueEvent)` and `onMood(PortraitMoodEvent)` callbacks during order generation.
2. Caller guarantees deterministic invocation order.
3. **Negotiation mood:** App updates offer state and stall count; mood state machine computes next mood and emits event on transition. Inputs deterministic for replay.
4. UI subscribes and resolves to text/portrait assets. No asset paths in events.

### Evidence and Dossier
1. Evidence rules evaluated when actions are applied (turn resolution or post-resolution hook). Rules per [hidden-agendas.md](../ai/hidden-agendas.md).
2. Storage: per (observer, subject, agenda type) counter + optional (turn, description) list. Deterministic: same actions → same evidence.
3. Dossier projection: read API returning PlayerView-safe data (basic intel, suspicion levels, evidence list, behavioral notes). True hidden agenda never exposed.

## Integration

- **Phase:** Events emitted during AI order generation. Evidence accumulated during action resolution.
- **Upstream:** AI order generation, turn resolution hooks.
- **Downstream:** UI (dialogue, portrait mood), game state (evidence), dossier screen.

## Constraints
- All events and evidence reproducible: same state + seeds → same output.
- Replay and save/load must restore or recompute evidence from persisted state.
- True hidden agenda never exposed via events or dossier.
