# Last-turn intelligence digest

**SPEC/program** — Persisted last-turn briefing for Diplomacy Intelligence (`GAME30003`). UI: [intelligence-council.md](../ui/intelligence-council.md). World gazette taxonomy: [turn-news-digest.md](turn-news-digest.md). Spy entitlement: [civilian-units.md](../game/civilian-units.md). Events: [game-events.md](game-events.md).

## When it runs

After `resolveTurnForGame` completes with no pending diplomacy, immediately after `buildTurnNewsDigestForComplete`. If `end.victory != null`, **do not** replace the persisted digest (victory UX first). `resolvedTurnNumber` is `start.worldState.turnState.turnNumber`.

Replace (do not append) `Game.lastTurnIntelligenceDigest` each completed turn. Same lifecycle as `OVL70001`. Persist on `Game` JSON (save/load). Legacy saves without the field load as `null` (empty council).

Build is O(events this turn + diplomatic history this turn + provinces for captures already computed by turn news). Deterministic. No extra simulation.

## Contents

**World (public, observer-independent):** turn-news lines in that spec’s category order, plus **formal alliance formed/broken** this turn from `Game.diplomaticHistoryEvents` (`allianceFormed` / `allianceBroken`), inserted after war/peace and before overtures. Pair ids lexicographic. Empty world: no world lines.

**Spy-gated (per observer GP):** for each other faction that still hosts ≥1 of the observer’s Spies **after** spy-resolution (unit still present on `end`), one court block. Multiple Spies in the same court → one block. Caught or departed last Spy → no block. Fold that court’s last-turn `DiplomaticEvent`s, captures they made or lost, `CombatResultEvent` / `NavalCombatResultEvent` they fought, and `ResearchCompleteEvent` / newly unlocked techs they earned. Never `hiddenAgenda`. Tribe/Minor spy reports **that owner**, not every GP.

Store spy blocks in `spyReportsByObserverId` keyed by observer GP id (all GPs; UI shows the human).

## Acceptance criteria

- Given two other GPs go to war and a third-party province changes owner this turn, when the digest commits, then world lines include both facts with faction and prefixed province ids, and `Game.lastTurnIntelligenceDigest` round-trips through JSON.
- Given observer `H` has no Spy in France after resolution, when France unlocks a catalog tech and fights a battle `H` is not in, then France spy-report lines for `H` are absent; public world types may still appear.
- Given `H` still has a Spy in a French-owned province after spy-resolution, and France unlocked a tech and `declareWar` vs Spain this turn, then the France block for `H` includes both facts (tech id, Spain id) and no `hiddenAgenda`.
- Given that Spy was caught or was the last Spy and left so France hosts none of `H`’s Spies, when the next digest builds, then France spy-report lines for `H` are omitted (world lines unchanged).
- Given a new turn resolves, when the digest commits, then the previous digest is replaced, not appended.
