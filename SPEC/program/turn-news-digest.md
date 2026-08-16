# Turn news digest (logic)

**Source:** GitHub issue #1478 + product comment 2026-04-03. **Audience:** omniscient (world newspaper); province names may appear before the human map reveals them.

## When it runs

After a full `resolveTurnForGame` completes (no pending diplomacy), compare **game at start of resolution** (after `ensureMilitaryArmiesForGame`) to **final game** (after end-of-turn, including turn increment). If `final.victory != null`, **no** digest is produced (victory UX runs first; no news dialog).

`resolvedTurnNumber` in the digest is `start.worldState.turnState.turnNumber` (the turn that was just resolved). The UI shows the dialog when `turnNumberAfter >= 1` (see `TurnResolutionCompleteEvent`).

## Persistent tracking (`WorldState`)

Stored on save so reload does not duplicate lines:

- **`newsDigestProvinceRevealDoneIds`**: prefixed province ids for which a **province discovery** line has already been emitted (global; do not re-emit when another GP later gains first local visibility).
- **`newsDigestSeaZoneFleetDoneIds`**: prefixed sea zone ids for which a **first fleet presence** line has already been emitted (global).

Lists are kept sorted for deterministic JSON and equality.

## Line taxonomy (deterministic order)

Categories and sort keys:

1. **Province captured** — same predicate as `emitProvinceCapturedEvents`: **both** `previousOwner` and `prov.ownerId` are non-empty faction ids and they differ (faction-to-faction handover). Null/empty `ownerId` is uncolonized frontier only, not a capture outcome. Sort by `provinceId`.
2. **War / peace** — symmetric pair `RelationState` transitions only: to `atWar` or to `atPeace`. Neutral copy: faction ids sorted lexicographically (`A` and `B`). No aggressor/defender labels.
3. **Overture advanced** — `OvertureState.stage` strictly increased vs start of turn for the same `(gpId, targetId)`; all faction pairs. Sort by `gpId`, `targetId`, then `stage.name`.
4. **Province discovered** — any Great Power tile visibility in that province moves from all-`unknown` to any non-`unknown` (includes partial/coastal reveal). Emit only if province id ∉ `newsDigestProvinceRevealDoneIds` at start; then add id to tracking. Sort by `provinceId`.
5. **Sea zone — first fleet presence** — sea zone has at least one fleet at sea in final state, zone id ∉ `newsDigestSeaZoneFleetDoneIds` at start; then add zone id to tracking. Sort by sea zone id.

Within the digest, emit lines in category order above; within a category, use the sort keys listed.

## Determinism

Same start/end games → same digest lines and order. Implementation uses sorted iteration over provinces, relations, overtures, and zones.

## Acceptance criteria

- Given a start/end pair where a province’s `ownerId` changes from a non-empty faction **A** to **null** or empty  
  When the system builds the turn news digest for that resolution  
  Then the digest contains **no** `TurnNewsProvinceCapturedLine` for that province.

- Given a start/end pair where a province’s `ownerId` changes from non-empty faction **A** to non-empty faction **B** with **A ≠ B**  
  When the system builds the turn news digest for that resolution  
  Then the digest includes exactly one province-captured line for that province with `previousOwnerId == A` and `newOwnerId == B` (prefixed province id), consistent with `emitProvinceCapturedEvents` for the same transition.

---

## Integration

Province ownership invariant for captures: [world-model.md](../game/world-model.md) § Invariants. Event contract: [game-events.md](game-events.md). Last-turn **Intelligence** world briefing reuses these lines and adds formal alliance formed/broken (newspaper taxonomy unchanged): [intelligence-digest.md](intelligence-digest.md).
