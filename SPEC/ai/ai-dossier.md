# AI Dossier (Phase 6)

**SPEC/ai** — Logical structure of the intelligence dossier. Source: GDD 10e. Implementation: [ai-events-and-dossier.md](../program/ai-events-and-dossier.md). UI layout and visuals are deferred to UI phases.

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
- **Confidence %** is derived from suspicion score bands (e.g. 0–2 → 0%, 3–5 → low %, 6–8 → medium %, 9–10 → high %, 10+ → “Confirmed” with 100% display). “Confirmed” means suspicion passed threshold; it does not mean the game reveals the true agenda value.
- Evidence and timeline entries must only reference **observable** events (e.g. war declared, treaty broken, visible army movement). No “internal AI intent” fields.

---

## Update cadence

- Basic intel: whenever relation or strength comparison changes; at least once per turn if the player views the dossier.
- Hidden agenda analysis: when new evidence is added for that subject.
- Behavioral notes / timeline: when new observable events occur (turn resolution or event hooks).

Storage may be part of game state (e.g. per-observer dossier cache) or computed on demand from game state and evidence logs; spec does not mandate storage format, only the logical sections and safety rules above.

---

## Acceptance criteria

- **PlayerView safety:** The dossier exposes only PlayerView-safe data. True hidden agenda (`hiddenAgenda[subjectId]`) is never exposed to the observer. Only suspicion scores, evidence-derived labels, and observable-event summaries are visible.
- **Sections:** Dossier has logical sections: Basic intel (personality/archetype, relation, relative strength); Hidden agenda analysis (per-agenda suspicion score, display bands Unknown/Possible/Likely/Almost certain/Confirmed, best-guess agenda id and confidence %); Evidence list (capped, chronological, human-readable entries); Behavioral notes; Timeline. All sections computable from observable state.
- **Confidence %:** Derived from suspicion score bands (e.g. 0–2 → 0%, 3–5 → low %, 6–8 → medium %, 9–10 → high %, 10+ → “Confirmed” with 100% display). “Confirmed” means suspicion passed threshold; it does not reveal the true agenda value.
- **Evidence and timeline:** Evidence list and timeline entries reference only **observable** events (e.g. war declared, treaty broken, visible army movement). No internal AI intent or hidden state in entries.
- **Update cadence:** Basic intel when relation or strength comparison changes (at least once per turn if dossier is viewed). Hidden agenda analysis when new evidence is added for that subject. Behavioral notes and timeline when new observable events occur (turn resolution or event hooks).
- **Implementation:** Dossier projection, evidence rules, and storage/on-demand contract: [ai-events-and-dossier.md](../program/ai-events-and-dossier.md).
