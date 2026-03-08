# AI Personalities (Phase 6)

**SPEC/ai** — Leader-specific behavior config for MVP. Source: GDD 10a. Application: [ai-architecture.md](ai-architecture.md). Implementation: [ai-systems-impl.md](../program/ai-systems-impl.md) (config, domain planners, goal selection), [ai-planner.md](../program/ai-planner.md) (AIConfig supplied when generating orders).

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

**Config source:** Personality config (domain weights, goal weights, behavioral thresholds) lives in program-level config (`colonizethis_data/lib/src/ai_personality_config.dart`) per [ruleset-config.md](../program/ruleset-config.md). Ruleset-configurable personality bundles are deferred to a future phase when the ruleset loader supports JSON merge. The `personalityId` field in AIConfig is reserved for future ruleset-driven personality overrides.

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

## Implementation

Personality is loaded as config and supplied via **AIConfig** when the AI generates orders. [ai-systems-impl.md](../program/ai-systems-impl.md) defines where config holds personality and where domain planners and goal selection use it; [ai-planner.md](../program/ai-planner.md) describes integration and where AIConfig is built and supplied for order generation.

In MVP, **AIConfig** fields related to personality have the following contract:

- `leaderId` — canonical leader id (e.g. `victoria`, `napoleon`). This is the **only** id used by `colonizethis_ai` for personality lookups: domain weights, goal weights, and behavioral thresholds in `colonizethis_data/lib/src/ai_personality_config.dart` are all keyed by canonical leader id. Dossier/archetype display also derives from `leaderId` via that config.
- `personalityId` — optional personality archetype id (e.g. an archetype handle in future rulesets). In MVP, `colonizethis_ai` does **not** read this field; callers SHOULD pass the same canonical id as `leaderId`. Future ruleset-configurable personality bundles may use `personalityId` as an override handle; when that happens, this spec and [ruleset-config.md](../program/ruleset-config.md) must be updated first.

### Leader identity and `Player.leaderKey` (MVP)

- Game state stores the chosen leader per Great Power on `Player.leaderKey` (string), set from the ruleset naming config (`LeaderVariant.leaderKey` in `naming_rules.dart`, e.g. `england_leader`, `france_leader`, `spain_leader`, `portugal_leader`, `netherlands_leader`, `prussia_leader`, `prussia_reserve_leader`, `sweden_leader`). This is the value serialized in the `Game` model and used by combat for leader bonuses per [leader-bonuses.md](../game/leader-bonuses.md).
- For AI personality lookups and dossier/archetype display, `leaderId` in **AIConfig** MUST be a **canonical leader id** from § Canonical leaders (e.g. `victoria`, `napoleon`, `isabella`, `henry`, `deruyter`, `frederick`, `gustavus`). `colonizethis_logic` therefore resolves `Player.leaderKey` to a canonical id **before** constructing `AIConfig`, using a resolver in `colonizethis_data` (see `ai_personality_config.dart`).
- The resolver accepts either a canonical id or a variant `leaderKey` and behaves as follows:
  - If the input already matches a canonical id present in the personality tables, it is returned unchanged.
  - If the input is a known variant key from the default naming config (e.g. `england_leader`, `france_leader`, `spain_leader`, `portugal_leader`, `netherlands_leader`, `prussia_leader`, `prussia_reserve_leader`, `sweden_leader`), it returns the corresponding canonical id (`victoria`, `napoleon`, `isabella`, `henry`, `deruyter`, `frederick`, `frederick`, `gustavus` respectively).
  - If the input is unknown (e.g. a scenario-specific leader key not in the mapping), the canonical id used for lookups is the input string itself; `colonizethis_ai` then falls back to the **default** neutral personality weights and thresholds for that id per `ai_personality_config.dart`.

---

## Acceptance criteria

- **Config and immutability:** Personalities are config data; read-only once the game is created. No mid-game change to a leader's personality.
- **Leader binding:** Each Great Power has exactly one leader (canonical id per § Canonical leaders). Personality drives goal selection and utility scoring per that leader's archetype and domain weights.
- **Domain weights:** Each leader has a defined domain-weight vector (economy, military, diplomacy, research). The vector biases behavior-tree goal selection and planner utility scores; relative weights matter.
- **Behavioral modifiers:** Thresholds (war likelihood, peace tendency, alliance tendency, research preference) are applied when scoring actions (e.g. declare war, accept peace, choose research). Modifiers combine with hidden agendas per [hidden-agendas.md](hidden-agendas.md).
- **Difficulty:** Difficulty level does not change personality or the AI algorithm; it only affects starting parameters and ruleset modifiers (e.g. resources, production, unit strength).
- **Leader identity resolution:** Given a game where a Great Power’s `Player.leaderKey` is a known variant key from the naming config (e.g. `england_leader`), when the AI agent builds **AIConfig** for that Great Power, then `AIConfig.leaderId` equals the corresponding canonical leader id from § Canonical leaders (e.g. `victoria`) and `colonizethis_ai` uses that canonical id for all personality lookups (domain weights, goal weights, thresholds, and archetype display).
