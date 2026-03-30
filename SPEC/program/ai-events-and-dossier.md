# AI Events and Dossier — Implementation (Phase 6)

**SPEC/program** — Event data and flows for dialogue, mood, evidence, dossier. Province identity: [world-model-identity.md](../game/world-model-identity.md).

## Responsibility
Event data models and data flows for dialogue, mood, evidence, and dossier. Behavior rules: [dialogue-and-mood.md](../ai/dialogue-and-mood.md), [ai-dossier.md](../ai/ai-dossier.md), [hidden-agendas.md](../ai/hidden-agendas.md). For AI–human dialogue that requires a player response (overtures, intervention, etc.), see [dialogue-system.md](dialogue-system.md) and [dialogue-management.md](../ai/dialogue-management.md).

## Data Model

### DialogueEvent
Fields: `leaderId`, `category`, `situation`, `era`, `mood?`, `variables` (map string→string). Categories and situations per [dialogue-and-mood.md](../ai/dialogue-and-mood.md). When `variables` includes a `province` key (e.g. from event_dialogue), its value must be a **prefixed** province id per [world-model-identity.md](../game/world-model-identity.md); never a bare local id. For battle result and reactive border events that are tied to a specific turn, the emitter derives `era` from the game’s turn-time mapping as `eraFromYear(mapping.yearAtTurn(turnNumber))`; for era_change events, `era` is the new era value.

### PortraitMoodEvent
Fields: `leaderId`, `fromMood`, `toMood`, `durationMs`. Mood values per [dialogue-and-mood.md](../ai/dialogue-and-mood.md).

### EvidenceEntry
Internal record appended when an action matches an evidence rule. Fields: observer id, subject id, agenda type, score delta, turn, description. Not emitted to UI; updates state read by dossier.

## Algorithm / Flow

### Dialogue and Mood
1. AI calls `onDialogue(DialogueEvent)` and `onMood(PortraitMoodEvent)` callbacks during order generation.
2. Caller guarantees deterministic invocation order.
3. **Negotiation mood:** App updates offer state and stall count; mood state machine computes next mood and emits event on transition. Inputs deterministic for replay. Canonical integration helper computes `toMood` with `computeNextNegotiationMood` and emits `PortraitMoodEvent` when `toMood != currentMood`.
4. UI subscribes and resolves to text/portrait assets. No asset paths in events.

### Evidence and Dossier
1. Evidence rules evaluated when actions are applied (turn resolution or post-resolution hook). Rules per [hidden-agendas.md](../ai/hidden-agendas.md). Which triggers are in scope (MVP) vs deferred is defined in that doc (§ Evidence rule coverage).
2. Storage: per (observer, subject, agenda type) counter + optional (turn, description) list. Deterministic: same actions → same evidence.
3. Dossier projection: read API returning PlayerView-safe data (basic intel, suspicion levels, evidence list, behavioral notes). True hidden agenda never exposed.
4. **Confidence % mapping:** Best-guess agenda confidence (display %) is derived from the highest suspicion score for that agenda. Mapping: score 0–2 → 0%; 3–5 → 25%; 6–8 → 60%; 9–10 → 85%; 11+ → 100%. Implementation must use this mapping for consistency with display bands (see [ai-dossier.md](../ai/ai-dossier.md) § PlayerView-safe rules).
5. **Evidence ordering and cap:** For each `(observerId, subjectId)` pair, dossier evidence entries are sorted by `turn` ascending and then capped to the most recent `kMaxDossierEvidenceEntries` items as defined in `colonizethis_data`. When the list would exceed this cap, the system drops the oldest entries so that both the evidence list and timeline remain capped and chronological.

## Integration

- **Phase:** Events emitted during AI order generation. Evidence accumulated during action resolution.
- **Upstream:** AI order generation, turn resolution hooks.
- **Downstream:** UI (dialogue, portrait mood), game state (evidence), dossier screen.

## Acceptance criteria

- **Phase:** Dialogue and mood events are emitted during AI order generation; evidence is accumulated during turn resolution (or post-resolution hook).
- **Callback contract:** AI invokes `onDialogue(DialogueEvent)` and `onMood(PortraitMoodEvent)`; caller guarantees deterministic invocation order.
- **Determinism:** Same game state and seeds produce the same events and evidence; replay and save/load restore or recompute consistently.
- **Province id in dialogue:** When a DialogueEvent carries a `province` variable, it is in prefixed form (`regionId|localId`) per [world-model-identity.md](../game/world-model-identity.md).

## Constraints
- All events and evidence reproducible: same state + seeds → same output.
- Replay and save/load must restore or recompute evidence from persisted state.
- True hidden agenda never exposed via events or dossier.
- **Province identity:** The `province` variable in DialogueEvent (when present) must be prefixed; any code passing provinceId into variables (e.g. event_dialogue) must use prefixed form per [world-model-identity.md](../game/world-model-identity.md).
