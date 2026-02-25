# Diplomacy Resolution

## Responsibility

Resolves diplomatic orders, manages overture state machine, updates relation scores, and feeds AI evidence pipeline during the Diplomacy phase. Game rules: [diplomacy.md](../game/diplomacy.md). Province identity (e.g. in order payloads or state that reference a province) follows [world-model-identity.md](../game/world-model-identity.md).

---

## Data Model

**Relation record** (per faction-pair): score (int 0–100), level (enum: Hostile, Neutral, Friendly, Allied — derived from score per game thresholds), sinceTurn (int), lastInteractionTurn (int), relationState (enum: AT_PEACE, AT_WAR). Stored in world state; serialized in save/load.

**Overture state** (per Minor/Tribe per GP): current stage (none, TradeConsulate, Embassy, NAP, JoinEmpire/Colony). Costs and turn delays per game rules. Stored in world state; serialized in save/load.

---

## Algorithm / Flow

Diplomacy phase runs before Movement. Resolution steps in order:

1. **Process overture payments** — For Consulate/Embassy orders: validate treasury, deduct cost, advance overture stage.
2. **Advance in-progress overtures** — Apply turn delays; mark completed.
3. **Resolve Join Empire/Colony** — Check relation score threshold per game rules; apply absorption (GP target) or colony creation (Tribe target).
4. **Process alliance proposals** — Apply accept/refuse; update alliance state; apply refusal relation penalties per game rules.
5. **Process Declare War and Peace** — Update relationState, sinceTurn, lastInteractionTurn.
6. **Apply relation modifiers** — From trade, grants (GrantAid), subsidies (SetSubsidy), war, broken treaties per game rules. SetSubsidy: valid if consulate/embassy exists; deducts payer treasury; if target is GP adds to target treasury, else (Minor/Tribe) improves relation.
7. **Update relation scores** — Recompute from modifiers; clamp 0–100; derive level.

**Order validation:** Each diplomatic order type (see game/diplomacy.md § Diplomatic Order Types) is validated by the order engine — preconditions (AT_PEACE/AT_WAR, overture stage, treasury) checked at submission and again at resolution.

---

## Integration

| Aspect | Detail |
|---|---|
| Phase | Diplomacy (before Movement) |
| Upstream | Player orders, world state (relations, overtures, treasury) |
| Downstream | Relation state → combat/movement validation; AI evidence/dossier pipeline |

**Economy:** GrantAid and SetSubsidy deduct payer treasury; SetSubsidy transfers to target GP or improves relation with Minor/Tribe. Trade agreement slots gated by embassy level. War terminates trade agreements with target.

**Combat/movement:** Before move or attack, check AT_WAR for Minors; for Tribes, check only if province has another GP's investment. Enforced by order engine and turn resolver.

**AI:** Diplomatic actions feed into AI evidence and dialogue event pipelines for hidden-agenda discovery. See [ai-events-and-dossier.md](ai-events-and-dossier.md), [SPEC/ai/ai-dossier.md](../ai/ai-dossier.md).

---

## Logging

Per [ctdev-logging.md](ctdev-logging.md): diplomacy is in **logic** scope. Phase start/end are logged by the turn resolver (`logic: phase diplomacy start` / `logic: phase diplomacy end`). The diplomacy resolver logs **key outcomes** with the `logic:` prefix so that flows and state changes are grep-friendly:

- **Phase boundaries:** Diplomacy resolver logs phase start and end at debug (redundant with turn resolver but allows filtering by file).
- **Key outcomes (info):** Overture payment applied (gpId, targetId, stage); Join Empire/Colony applied; alliance formed (faction pair); war declared (faction pair); peace offered (faction pair); agreements terminated due to war; GrantAid/SetSubsidy applied when modifier changes relation or treasury.

Rejections and validation failures are logged by the order engine; diplomacy resolution logs only applied state changes.

---

## Acceptance criteria

- **Phase order:** Diplomacy phase runs before Movement; resolution steps 1–7 run in the specified order (overture payments → advance overtures → Join Empire/Colony → alliances → war/peace → terminate agreements on war → relation modifiers and score update).
- **Upstream orders:** The diplomacy phase receives merged orders that include `diplomaticOrdersByPlayerId`; the turn resolver supplies the output of the order engine (see [order-engine.md](order-engine.md), [turn-resolution-phases.md](turn-resolution-phases.md)). The order engine must preserve diplomatic orders and pass them into the diplomacy phase input.
- **Overture payments:** Consulate/Embassy orders: when GP has sufficient treasury and is at the previous overture stage, cost is deducted and stage is advanced; NAP and Join Empire are free.
- **Join Empire/Colony:** Requires NAP stage and relation score ≥ 51 (Friendly/Allied); absorption (Minor) or colony (Tribe) applied per game rules.
- **Alliances:** GP–GP only; relation set to allied (score ≥ 76), state atPeace.
- **War and peace:** Declare War / Offer Peace update relationState, sinceTurn, lastInteractionTurn and scores per game rules; evidence and dialogue events emitted when applicable.
- **Agreements on war:** Overtures between a faction pair at war are terminated.
- **GrantAid / SetSubsidy:** GrantAid requires Embassy; SetSubsidy requires Consulate or Embassy. Payer treasury deducted; SetSubsidy to GP adds to target treasury, to Minor/Tribe improves relation modifier.
- **Order validation:** Preconditions for each diplomatic order type (AT_PEACE/AT_WAR, overture stage, treasury, etc.) are checked at order submission by the order engine and again at resolution; invalid orders are rejected and not applied. See game/diplomacy.md § Diplomatic Order Types.
- **Save/load:** Relation records (per faction-pair) and overture state (per Minor/Tribe per GP) are serialized in the game save and restored on load so that relation scores, levels, sinceTurn, lastInteractionTurn, relationState, and overture stages are preserved.
- **Logging:** Phase start and end at debug with `logic:` prefix; key outcomes at info (overture applied, join empire, alliance formed, war declared, peace offered, agreements terminated, GrantAid/SetSubsidy applied). Rejections and validation failures are logged by the order engine only.

---

## Config source (MVP)

Relation thresholds (score-to-level bands) and overture costs (Consulate £500, Embassy £1000) are currently **code constants** in the diplomacy resolver (`colonizethis_logic`: `overtureConsulateCost`, `overtureEmbassyCost`, `scoreToLevel`). The **default values** are defined in [diplomacy.md](../game/diplomacy.md) § Configurable Values; that table is the source of truth for design. Ruleset loading for these parameters is **not implemented** in MVP. When ruleset-driven config is added, the resolver will read from the resolved ruleset per [ruleset-config.md](ruleset-config.md) and the key path will be specified in the GDD and here.

---

## Constraints

- All diplomatic rules (relation thresholds, overture chain, order preconditions) are defined in game/diplomacy.md; this module references, not restates, them.
- Resolution order is strict (steps 1–7); reordering may break precondition checks.
- Overture stage transitions are linear; no stage may be skipped.
- Any province id used in diplomacy state or in diplomatic order payloads must be in prefixed form and resolved per [world-model-identity.md](../game/world-model-identity.md).
