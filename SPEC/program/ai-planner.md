# AIPlanner (Phase 4)

## Purpose and scope

Phase 4 introduces a minimal **AIPlanner** that generates orders for AI-controlled Great Powers. The goals are:

- Provide simple, reproducible AI behaviour for single-player games.
- Integrate with diplomacy (war/peace) and combat (including Quick Battle).
- Remain limited in scope: no deep strategy, no complex diplomacy.

This spec focuses on control rules, seeding and determinism, and the high-level behaviour of AIPlanner. It complements (but does not replace) `sim-game-default-ai.md`, which is used by CLI simulation tools.

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

AIPlanner may internally reuse patterns from the sim-game default AI, but must additionally consult diplomacy and terrain/tactical context.

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

At the strategic (turn-wide) level, AIPlanner can follow a simple policy:

- Movement:
  - For each AI unit, consider legal moves per `movement.md`.
  - Prefer moves that bring units into contested or enemy territory with which the AI is at war.
  - Avoid illegal moves against players at peace; skip or choose alternative non-aggressive moves.
- Build/work (if implemented):
  - Use simple rules similar to `sim-game-default-ai.md` (e.g. first valid build location, first idle worker).

These behaviours remain basic by design; later phases can extend or override them.

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

