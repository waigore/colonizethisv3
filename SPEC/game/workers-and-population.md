# Workers and Population

**SPEC/game** — Industrial labour model, distinct from civilian units. Derived from GDD 04, TDD 04. Reference: Imperialism II 02-economy (GDD).

---

## Workers as Separate Population Model

**Workers are a separate population model** — they are not map units. Civilian units (Explorer, Builder, Engineer, etc.) deploy, move, and work on terrain; workers are industrial labour in the capital, assigned to production, and never appear on the map.

Per Imperialism II 02-economy: workers "in your city" supply labour for industry. They consume food and luxuries directly from the player's stockpile.

---

## Worker Tiers

| Tier | Labour/turn | Food | Luxury (trained only) |
|------|-------------|------|------------------------|
| **Peasant** | 1 | 1 grain or meat | None |
| **Apprentice** | 4 | 1 grain + 1 meat | Refined sugar |
| **Journeyman** | 6 | 1 grain + 1 meat | Cigars |
| **Master** | 8 | 1 grain + 1 meat | Fur hats |

---

## Recruiting and Training

- **Recruiting:** fabric → new Peasant. Adds to worker pool. **CLARIFICATION NEEDED:** How much fabric per Peasant? Need Imperialism II reference.
- **Training:** worker + paper + cash → next tier. Worker is out of pool that turn. Requires tech per tier. **CLARIFICATION NEEDED:** What quantities of paper and cash? Need Imperialism II reference.
- **Military/naval construction:** regiments and ships consume a worker when built.

---

## Consumption and Production

- Workers consume food and luxuries from player stockpile during end-of-turn Consumption phase.
- **Starvation (per Imp2):** Food is deducted from transported amounts first, then from warehouse/stockpile. If a worker's required food cannot be met from either source, the worker **starves and is immediately removed** at end of that turn's Consumption phase. There is no grace period.
- Without luxury: trained worker produces no labour that turn (but is not removed).
- Production uses labour: one labour per resource input consumed by a recipe (e.g. 2 timber → 1 lumber = 2 labour).
- Total food demand = workers + navy + army.

---

## Relations

- **Player** → **WorkerPool** (or Population): per-player worker counts by tier.
- Workers consume from Player stockpile. Workers supply labour to production.

---

## Implementation

Data structures in [economy-models.md](../program/economy-models.md). Worker model distinct from Unit; workers live in economy (TDD 04), not unit model (TDD 05). Config is program-level (no JSON rulesets in MVP).

**MVP scope:** Food consumption and starvation are implemented in economy_consumption.dart (peasant 1 food, trained 2 food; starvation order: peasants first, then apprentices, journeymen, masters). Luxury consumption (sugar, cigars, fur hats) and worker tier training (paper + cash → next tier) are deferred until Recruiting/Training quantities are defined or an MVP simplification is chosen.
