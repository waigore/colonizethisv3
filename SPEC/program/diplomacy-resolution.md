# Diplomacy Resolution

**SPEC/program** — Technical diplomacy: relation model, overture state machine, order types, phase resolution order. Game rules: [diplomacy.md](../game/diplomacy.md). Turn sequence: [turn-resolution-phases.md](turn-resolution-phases.md).

---

## Relation model (technical)

Per faction-pair: data structures for **score** (0–100), **level** (Hostile/Neutral/Friendly/Allied), **sinceTurn**, **lastInteractionTurn**, and **relationState** (AT_PEACE/AT_WAR). Stored in world state; serialized in save/load. Relation level derived from score using thresholds (0–25, 26–50, 51–75, 76–100).

---

## Overture state machine

Per Minor/Tribe per GP: current **overture stage** (none, Trade Consulate, Embassy, Non-Aggression Pact, Join Empire/Colony). **Costs and turn delays:** Consulate and Embassy have fixed costs (e.g. £500, £1000) and complete the turn after payment. **Advancement:** Each step requires the previous; Join Empire/Colony resolution depends on relation check (and optionally RNG or threshold). State is stored in world state and save/load.

---

## Diplomatic order types

- **DeclareWarOrder** — target faction; valid if AT_PEACE.
- **OfferPeaceOrder** — target faction; valid if AT_WAR.
- **AllianceOrder** — target GP; propose, accept, or refuse; validation per diplomacy.md.
- **EstablishOvertureOrder** — target Minor/Tribe, overture type (Consulate, Embassy, NAP, Join Empire); valid if previous step achieved and cost/turn conditions met.
- **GrantAidOrder** — target faction, amount; valid if Embassy with target; deducts from treasury.
- **SetSubsidyOrder** — target, amount or percentage; trade policy; valid where consulate/embassy exists.

Validation preconditions for each type are enforced by the order engine and at resolution.

---

## Diplomacy phase resolution order

The Diplomacy phase runs **before** Movement in the turn sequence. Steps (in order):

1. **Process overture payments** — Consulate, Embassy; deduct treasury; advance state when paid.
2. **Advance in-progress overtures** — Turn delays and completion.
3. **Resolve Join Empire/Colony** — For each request, check relation score (and threshold/RNG); apply absorption or colony creation per diplomacy.md.
4. **Process alliance proposals and responses** — Apply accept/refuse; update alliance state; apply refusal penalties.
5. **Process Declare War and Peace** — Update relationState, sinceTurn, lastInteractionTurn.
6. **Apply relation modifiers** — From trade, grants, war, broken treaties (see GDD 07 modifier table).
7. **Update relation scores** — Recompute scores from modifiers; clamp 0–100; update level.

TurnResolver calls the diplomacy resolver in the Diplomacy phase (phase 1 or as defined in turn-resolution-phases).

---

## Integration

**Economy:** GrantAid deducts treasury. Trade agreement slots gated by embassy level (per economy spec). War terminates all trade agreements with the target.

**Combat/movement validation:** Before move or combat, check AT_WAR for Minor targets; for Tribe targets, no war check unless the province has another GP's investment (then check AT_WAR with that GP). Order engine and TurnResolver enforce these checks.

**AI events and evidence:** When AI (or any faction) performs diplomatic actions (declare war, peace, alliances, overtures), resolution may feed into AI **evidence** and **dialogue event** pipelines for hidden-agenda discovery and dossier updates. See [ai-events-and-dossier.md](ai-events-and-dossier.md) and [SPEC/ai/ai-dossier.md](../ai/ai-dossier.md).
