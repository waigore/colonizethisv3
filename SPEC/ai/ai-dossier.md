# AI Dossier (Phase 6)

**SPEC/ai** — Logical structure of the intelligence dossier. Source: GDD 10e. Implementation (dossier projection and evidence): [ai-events-and-dossier.md](../program/ai-events-and-dossier.md) § Evidence and Dossier. UI layout and visuals are deferred to UI phases.

---

## Purpose

The **dossier** is the player’s intelligence view of another (e.g. AI) nation. It is built from **PlayerView-safe** data only: no hidden state (e.g. true hidden agenda) is exposed. Logic defines what data exists and how it is updated; UI decides how to display it.

---

## Data sections

| Section | Contents | Source |
|---------|----------|--------|
| **Basic intel** | Visible personality/archetype (e.g. Fortifier), current relation with observer, relative military/economic strength. | Game state, visibility rules. Updated every turn or when relation/strength changes. |
| **Hidden agenda analysis** | Per-agenda **suspicion score** (0–10+); display band: Unknown, Possible, Likely, Almost certain, Confirmed. Best-guess agenda id and confidence % for display. | Evidence accumulation (see [hidden-agendas.md](hidden-agendas.md)). Updated when evidence is added. |
| **Evidence list** | Capped, chronological list of evidence entries the observer has seen (e.g. “Declared war on weaker neighbor, Turn 34”). No raw counter; only human-readable summary. | Evidence log for (observerId, subjectId). |
| **Behavioral notes** | War history (who they declared on, when, outcome), diplomatic pattern (alliances accepted/broken), military buildup (e.g. fort focus). | Derived from game events and visibility. |
| **Timeline** | Chronological list of notable actions (wars, treaties, visible builds) relevant to dossier. | Same as behavioral notes, optionally more granular. |

Spy reports (if in scope) add evidence or special entries; format TBD in implementation. All of the above must be computable from **observable** state so that no cheating (reading true hidden agenda) is possible.

---

## PlayerView-safe rules

- **Never expose** `hiddenAgenda[subjectId]` to the observer. Only suspicion scores and evidence-derived labels are visible.
- **Confidence %** is derived from suspicion score bands. Exact mapping: [ai-events-and-dossier.md](../program/ai-events-and-dossier.md) § Evidence and Dossier (0–2 → 0%; 3–5 → 25%; 6–8 → 60%; 9–10 → 85%; 11+ → 100%). “Confirmed” means suspicion passed threshold; it does not mean the game reveals the true agenda value.
- Evidence and timeline entries must only reference **observable** events (e.g. war declared, treaty broken, visible army movement). No “internal AI intent” fields.

---

## Update cadence

- Basic intel: whenever relation or strength comparison changes; at least once per turn if the player views the dossier.
- Hidden agenda analysis: when new evidence is added for that subject.
- Behavioral notes / timeline: when new observable events occur (turn resolution or event hooks).

Storage:

- **MVP:** Evidence entries are stored in **game state** as part of the dossier data (e.g. `game.dossierEvidenceEntries`), so that evidence and dossier contents persist across save/load and are available for deterministic replay.
- **Post-MVP:** On-demand computation from game state and evidence logs is allowed as an alternative implementation, provided it produces the same observable dossier sections and respects the PlayerView safety rules above. The GDD does not mandate a single storage format beyond these logical and safety requirements.

---

## Evidence list cap

- **MVP cap:** The maximum number of evidence entries kept per dossier (per `(observerId, subjectId)` pair) is defined by a program-level constant in `colonizethis_data`. When the list would exceed this cap, the system drops the oldest entries so that the list remains capped and chronological.
- **Post-MVP ruleset:** Future releases may promote this cap to a ruleset-configurable value (for example per scenario or difficulty). When that happens, this document and the TDD implementation spec (`ai-events-and-dossier.md` § Evidence and Dossier) are the source of truth for how the cap is read and applied.

---

## Acceptance criteria

- **PlayerView safety:** The dossier exposes only PlayerView-safe data. True hidden agenda (`hiddenAgenda[subjectId]`) is never exposed to the observer. Only suspicion scores and evidence-derived labels are visible.
- **Sections:** Dossier has logical sections: Basic intel (personality/archetype, relation, relative strength); Hidden agenda analysis (per-agenda suspicion score, display bands Unknown/Possible/Likely/Almost certain/Confirmed, best-guess agenda id and confidence %); Evidence list (capped, chronological, human-readable entries, with the cap defined by a program-level constant as above); Behavioral notes; Timeline. All sections computable from observable state.
- **Confidence %:** Derived from suspicion score bands; exact mapping in [ai-events-and-dossier.md](../program/ai-events-and-dossier.md) § Evidence and Dossier (0–2 → 0%; 3–5 → 25%; 6–8 → 60%; 9–10 → 85%; 11+ → 100%). “Confirmed” means suspicion passed threshold; it does not reveal the true agenda value.
- **Evidence and timeline:** Evidence list and timeline entries reference only **observable** events (e.g. war declared, treaty broken, visible army movement). No internal AI intent or hidden state in entries.
- **Update cadence:** Basic intel when relation or strength comparison changes (at least once per turn if dossier is viewed). Hidden agenda analysis when new evidence is added for that subject. Behavioral notes and timeline when new observable events occur (turn resolution or event hooks).
- **Implementation:** Dossier projection, evidence rules, and storage/on-demand contract: [ai-events-and-dossier.md](../program/ai-events-and-dossier.md) § Evidence and Dossier.
