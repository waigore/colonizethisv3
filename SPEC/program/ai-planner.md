# AIPlanner (Phase 4)

## Purpose and scope

Phase 4 introduces a minimal **AIPlanner** that generates orders for AI-controlled Great Powers. The goals are:

- Provide simple, reproducible AI behaviour for single-player games.
- Integrate with diplomacy (war/peace) and combat (including Quick Battle).
- Remain limited in scope: no deep strategy, no complex diplomacy.

This spec focuses on control rules, seeding and determinism, and the high-level behaviour of AIPlanner. It complements (but does not replace) `sim-game-default-ai.md`, which produces orders for one GP when ctdev selects Sim Game AI for the run (all GPs use that AI). AIPlanner (for AI-controlled GPs) and the sim-game default AI share the same **simple heuristics core** in colonizethis_logic: both use PlayerView, the order suggestion API, the same category order (move → work → build → research), seeded random choice within category, and the same diplomacy post-filter. Entry points remain separate; only the strategy implementation is shared.

## Control rules (who is AI)

In Phase 4:

- Each Great Power has a control type:
  - **Human-controlled**: bound to a local or remote player.
  - **AI-controlled**: no human player is assigned to this Great Power.
- In a **single-player** game:
  - All Great Powers not assigned to a human slot are automatically AI-controlled.
- Control type is part of game state and is saved/loaded with the game.

AIPlanner only produces orders for AI-controlled Great Powers. Human players provide their own orders through UI.

## Seeding and determinism

AI behaviour (both strategic and tactical) must be reproducible given the same initial state and seeds:

- **Global game seed**
  - A deterministic seed stored with the game; used for high-level randomness (map generation, event ordering, etc.).
- **Per-AI seed**
  - Each AI-controlled Great Power `P` has a persistent `aiSeed[P]`, stored in game state.
  - `aiSeed[P]` is set when the game is created or when control for P changes to AI.

For each turn `T` and AI player `P`, AIPlanner derives:

- `turnSeed[P, T] = hash(globalGameSeed, aiSeed[P], T)`
- From `turnSeed[P, T]`, sub-seeds for subsystems as needed:
  - `strategicSeed[P, T]` — used by AIPlanner when choosing high-level orders (movement, build/work).
  - `tacticalSeed[P, T]` — used when AI controls Quick Battle actions for battles involving P.

All AI randomness must flow from these seeds so that:

- Same save + same seeds → same AI orders and Quick Battle decisions.
- Debug tools can reproduce specific AI turns or battles by logging seeds and replaying them.

## AIPlanner behaviour (Phase 4)

AIPlanner’s responsibilities in Phase 4 are intentionally narrow:

- **Scope (per AI Great Power, per turn)**
  - Produce movement and simple build/work orders (if implemented) consistent with `orders.md` and `sim-game-default-ai.md`.
  - Respect diplomacy constraints from `diplomacy.md` (no attacks against players at peace).
  - For combats chosen as Quick Battle, provide tactical actions (CP spending) for the AI side using `tacticalSeed`.
- **Out of scope**
  - Long-term strategic planning (grand strategy).
  - Complex diplomatic behaviour (alliances, multi-stage negotiations).
  - Economic optimization beyond trivial rules.
  - **Naval orders** (fleet move, patrol, blockade, beachhead). Phase 4 AIPlanner does not generate naval orders. When ctdev uses **simple (Phase 4) AI**, games with fleets still resolve (e.g. fleets keep current position and no mission, or implementation may emit minimal naval orders so fleets are not stuck); **full naval play in sim** (patrol, blockade, beachhead, invasions) requires **Phase 6 full AI**, which issues naval orders via the same order suggestion API and PlayerView.

The shared simple heuristics (used by both AIPlanner and defaultSimGameAi) apply the diplomacy post-filter to moves and consult only PlayerView and the suggestion API; no raw order construction from topology.

### High-level heuristics (tactical)

When acting in Quick Battle on behalf of an AI Great Power:

- Prefer occupying and defending **good terrain** (`HILL`, `TOWN`, `WOODS`) with high-value units.
- Avoid exposing fragile units in `SWAMP` unless numerically overwhelming.
- Use **Volley Fire** and **Defend / Entrench** when outmatched or when holding key lanes (especially `CENTER`).
- Use **Maneuver** and **Fall Back / Refuse Flank** to:
  - Rotate damaged units out of the front line.
  - Shift strength from a winning flank into `CENTER` or a threatened flank.
- Use **Assault / Charge** when:
  - The enemy lane is already disrupted (low cohesion).
  - Terrain is favourable or at least neutral.

AI may randomise between multiple acceptable actions using the provided seeds, but should remain deterministic given them.

### High-level heuristics (strategic)

At the strategic (turn-wide) level, AIPlanner does **not** construct raw orders directly. Instead it:

- Builds a [PlayerView](player-view.md) for each AI-controlled Great Power `P`, encoding only what `P` can legally see under fog of war.
- Asks the **order suggestion API** (see [order-engine.md](order-engine.md)) for:
  - Candidate movement orders based on units and topology visible in `PlayerView`.
  - Candidate work/build orders using visible provinces, prospected tiles, and economy.
  - Candidate research orders using `P`'s known tech state and the public tech catalog.
- Applies simple heuristics (per this section) plus seeded randomness to choose:
  - Which order type to act on next (move vs work vs build vs research).
  - Which candidate within that type to take.
- Appends the chosen order to `P`'s current order list and repeats until it decides to stop (e.g. no more suggestions or a per-turn cap).

Example heuristics:

- Movement:
  - For each AI unit, prefer suggested moves that bring units into contested or enemy territory with which the AI is at war.
  - Avoid suggested moves into provinces owned by factions at peace (these will typically not be offered when rules forbid them).
- Build/work:
  - Prefer cheaper suggested builds and work orders that improve owned, visible provinces.
- Research:
  - Prefer lower-era, cheaper technologies that unlock core capabilities.

These behaviours remain basic by design; later phases can extend or override them while still going through PlayerView and the suggestion API.

## Order merge with human players

Once AIPlanner and human players have produced their orders:

- The game collects:
  - All human orders.
  - All AI orders (from AIPlanner) for AI-controlled Great Powers.
- An **order merge step** combines them into a final, deterministic order list for `TurnResolver`:
  - Keep a stable ordering (e.g. by player id, then unit id, then order type) so that resolution is repeatable.
  - Conflicts (e.g. multiple orders for the same unit) are resolved by clear precedence rules; typically:
    - A unit controlled by a human player cannot receive AI orders.
    - For purely AI-controlled units, AIPlanner should emit at most one order per unit or system.
  - All merged orders must be validated against `diplomacy.md` and world state; invalid orders are dropped or reported, but must not break determinism.

The merged and validated order list is then passed to `TurnResolver` as in previous phases.

---

## Diagnostics in ctdev (Running Game)

The **ctdev** dev application uses AIPlanner output as a diagnostic signal when running the **Running Game** sim screen:

- In ctdev sim, all GPs are AI-controlled. The user chooses either **Sim Game AI** (defaultSimGameAi for every GP) or **AI Planner** (minimal or full) for every GP; no human orders. When the user clicks **Next Turn** or **Fast-forward 10**, ctdev uses the selected AI to obtain per-turn `Orders` for all Great Powers.
- Before passing the combined `Orders` to `TurnResolver`, ctdev may mirror these orders into an in-memory **AI order history** structure and ask `OrderEngine.validatePlayerOrdersWithContext(game, topology, playerId)` for per-order validation results.
- This diagnostic history is rendered in the **Orders (AI history)** tab described in `ctdev-app.md`. It is **read-only** and does not change which orders are applied during turn resolution; it exists purely to help developers understand which orders AIPlanner attempted to issue, and why certain orders were rejected by validation.
- ctdev displays the **turn seed** (per player and turn) as a monitored variable on the Running Game screen so developers can reproduce or debug AI behaviour (see [ctdev-app.md](ctdev-app.md)).

---

## Phase 6 superseding behaviour

The behaviour above is the **Phase 4 minimal** AIPlanner: baseline for tooling and tests, and sufficient for Phase 4 exit.

**Phase 6** introduces the **full hybrid AI** (package **colonizethis_ai**): behavior trees, utility-based domain planners, personalities, hidden agendas, dialogue and mood events, dossier. For standard gameplay, the game uses the full AI to generate orders for AI-controlled GPs; the same control rules, seeding, PlayerView, and order merge apply. AIPlanner will then use this full AI and thus a **different** strategy from the shared simple heuristics. When the user selects Sim Game AI in ctdev, all GPs use the sim-game default AI (shared simple heuristics). When the user selects AI Planner, all GPs use that path (minimal or full). The Phase 4 simple-heuristics implementation remains available so that **ctdev** can offer a toggle: run simulations with **Sim Game AI** or **AI Planner** (simple Phase 4 or full Phase 6). Both paths produce valid, deterministic orders.

Authoritative behaviour for the full AI is defined in [SPEC/ai/](../ai/) and [ai-systems-impl.md](ai-systems-impl.md); this document remains the source for control rules, seeds, and merge semantics shared by both.

