# AI Events and Dossier (Phase 6)

**SPEC/program** — Technical event models and data flows for dialogue, mood, evidence, and dossier. Design: [SPEC/ai/dialogue-and-mood.md](../ai/dialogue-and-mood.md), [SPEC/ai/ai-dossier.md](../ai/ai-dossier.md), [SPEC/ai/hidden-agendas.md](../ai/hidden-agendas.md).

---

## Event types

**DialogueEvent** — Emitted when AI should “say” something. Fields: leaderId, category, situation, era, mood?, variables. Consumer (UI) resolves to text. Deterministic: same game state and dialogue seed → same event.

**PortraitMoodEvent** — Emitted when negotiation (or base) mood changes. Fields: leaderId, fromMood, toMood, durationMs. Consumer (UI) uses for portrait/animation choice. Deterministic.

**EvidenceEntry** — Internal: when an action matches an evidence rule (e.g. “declared war on weaker neighbor”), a record is appended to the observer’s evidence log for that subject. Not an event to UI; it updates state that dossier reads.

---

## Flow: dialogue and mood

1. **Strategic/tactical AI** (colonizethis_ai) runs and may call `onDialogue(DialogueEvent)` and `onMood(PortraitMoodEvent)` callbacks provided by the caller (e.g. TurnResolver or app).
2. Caller guarantees callbacks are invoked in a deterministic order (e.g. after each decision that triggers dialogue).
3. **Negotiation mood:** When the human is in a deal-making flow, the app or a dedicated component updates offer state and stall count; colonizethis_ai (or a shared mood state machine) computes next mood and emits PortraitMoodEvent on transition. Inputs (offer quality, stall count) must be deterministic for replay; use seeds if any randomness.
4. UI subscribes to these events (or polls after turn resolution) and displays dialogue text and portrait mood. No asset paths in events; UI resolves leaderId + mood to asset.

---

## Flow: evidence and dossier

1. **Evidence rules** are evaluated when actions are applied (e.g. in turn resolution or in a post-resolution hook). Example: “AI P declared war on nation Q where Q was weaker” → add evidence (observerId = human, subjectId = P, agendaType = warmonger, +2). Rules live in colonizethis_ai or in a shared module; resolution calls into them so that evidence is written in one place.
2. **Evidence storage** is part of game state (or a dedicated store keyed by game id). Per (observerId, subjectId, agendaType) counter; optional list of (turn, description) for dossier display. Same actions → same evidence (deterministic).
3. **Dossier projection** is a read API: given observerId (e.g. human), subjectId (AI nation), and current game state + evidence store, return the PlayerView-safe dossier (basic intel, suspicion levels, evidence list, behavioral notes). colonizethis_ai or colonizethis_logic can expose this; no hidden data in the return value.

---

## Determinism and replay

- All events and evidence must be reproducible: same (game state, seeds, order of operations) → same (DialogueEvents, PortraitMoodEvents, evidence entries).
- Replay and save/load must restore or recompute evidence and dossier from persisted state so that no non-determinism is introduced.
