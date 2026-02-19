# Diplomacy Resolution

## Responsibility

Resolves diplomatic orders, manages overture state machine, updates relation scores, and feeds AI evidence pipeline during the Diplomacy phase. Game rules: [diplomacy.md](../game/diplomacy.md).

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
6. **Apply relation modifiers** — From trade, grants, war, broken treaties per game rules.
7. **Update relation scores** — Recompute from modifiers; clamp 0–100; derive level.

**Order validation:** Each diplomatic order type (see game/diplomacy.md § Diplomatic Order Types) is validated by the order engine — preconditions (AT_PEACE/AT_WAR, overture stage, treasury) checked at submission and again at resolution.

---

## Integration

| Aspect | Detail |
|---|---|
| Phase | Diplomacy (before Movement) |
| Upstream | Player orders, world state (relations, overtures, treasury) |
| Downstream | Relation state → combat/movement validation; AI evidence/dossier pipeline |

**Economy:** GrantAid deducts treasury. Trade agreement slots gated by embassy level. War terminates trade agreements with target.

**Combat/movement:** Before move or attack, check AT_WAR for Minors; for Tribes, check only if province has another GP's investment. Enforced by order engine and turn resolver.

**AI:** Diplomatic actions feed into AI evidence and dialogue event pipelines for hidden-agenda discovery. See [ai-events-and-dossier.md](ai-events-and-dossier.md), [SPEC/ai/ai-dossier.md](../ai/ai-dossier.md).

---

## Constraints

- All diplomatic rules (relation thresholds, overture chain, order preconditions) are defined in game/diplomacy.md; this module references, not restates, them.
- Resolution order is strict (steps 1–7); reordering may break precondition checks.
- Overture stage transitions are linear; no stage may be skipped.
