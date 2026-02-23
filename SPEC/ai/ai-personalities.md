# AI Personalities (Phase 6)

**SPEC/ai** — Leader-specific behavior config for MVP. Source: GDD 10a. Application: [ai-architecture.md](ai-architecture.md).

---

## Purpose

Each Great Power has a **leader** (e.g. Victoria, Napoleon, Isabella). The leader’s **personality** is fixed for the game and drives:

- **Goal selection** — Behavior tree prefers strategies that match the personality (e.g. Napoleon → conquer/fortify; Victoria → trade/alliances).
- **Utility scoring** — Domain planners weight candidates by personality (e.g. Isabella → high weight for exploration and gold provinces; Henry → high weight for trade and subsidies).

Personalities are **config data**: read-only once the game is created. No mid-game change.

---

## Canonical leaders (MVP)

| Leader id | Nation | Archetype | War tendency | Build priority | Research focus |
|-----------|--------|-----------|--------------|---------------|----------------|
| victoria | England | industrial_trader | Low | Ships, industry, forts, army | Naval, industrial |
| napoleon | France | fortifier | High | Forts, army, ships, industry | Military, fortification |
| isabella | Spain | explorer | Medium (gold) | Explorers, ships, minimal army | Exploration |
| henry | Portugal | navigator | Very low | Ships, trade posts, exploration | Naval speed, exploration |
| deruyter | Netherlands | merchant | Low (trade threat) | Trade ships, subsidies, banks | Economic |
| frederick | Prussia | defender | Medium (counter) | Forts, elite army | Military quality |
| gustavus | Sweden | tactician | Medium (opportunity) | Mixed, artillery, navy | Military innovation |

---

## Domain priority weights

Each personality defines **domain weights** (economy, military, diplomacy, research) used by the behavior tree and utility AI. Example scale 0–100; relative weights matter.

- **industrial_trader:** economy high, diplomacy high, military low.
- **fortifier:** military high, economy medium, diplomacy low (alliances as tools).
- **explorer:** economy (extraction/colonies) high, military medium for gold, diplomacy low.
- **navigator:** economy (trade) high, diplomacy high, military very low.
- **merchant:** economy high, diplomacy high, military low.
- **defender:** military high (defensive), economy low, diplomacy medium.
- **tactician:** military high (combined arms), economy medium, diplomacy medium.

Exact numbers live in config data; SPEC does not mandate values, only that each leader has a defined vector and that it biases goal selection and utility scores.

---

## Behavioral modifiers

Personality also adjusts **thresholds** used by planners:

- **War likelihood** — Base score to declare war; personality adds a modifier (e.g. Napoleon +, Henry −).
- **Peace tendency** — Willingness to accept peace offers (Victoria high, Napoleon lower).
- **Alliance tendency** — Likelihood to accept/offer alliances and maintain them (Victoria high, Napoleon low).
- **Research preference** — Weights per tech category (naval, military, economic, exploration) so that e.g. Isabella favors exploration techs.

These are applied when scoring actions (e.g. declare war, accept peace, choose research slot). Combined with hidden agenda modifiers (see [hidden-agendas.md](hidden-agendas.md)).

---

## Difficulty

Difficulty does **not** change personality or AI strength. It only affects **starting parameters and ruleset modifiers** (e.g. AI nation’s starting resources, production modifiers, unit strength modifiers). Same personality and same algorithm for all difficulty levels.

---

## Acceptance criteria

- **Config and immutability:** Personalities are config data; read-only once the game is created. No mid-game change to a leader's personality.
- **Leader binding:** Each Great Power has exactly one leader (canonical id per § Canonical leaders). Personality drives goal selection and utility scoring per that leader's archetype and domain weights.
- **Domain weights:** Each leader has a defined domain-weight vector (economy, military, diplomacy, research). The vector biases behavior-tree goal selection and planner utility scores; relative weights matter.
- **Behavioral modifiers:** Thresholds (war likelihood, peace tendency, alliance tendency, research preference) are applied when scoring actions (e.g. declare war, accept peace, choose research). Modifiers combine with hidden agendas per [hidden-agendas.md](hidden-agendas.md).
- **Difficulty:** Difficulty level does not change personality or the AI algorithm; it only affects starting parameters and ruleset modifiers (e.g. resources, production, unit strength).
