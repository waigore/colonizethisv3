# Diplomacy Planner (AI)

**SPEC/ai** — Authoritative source of truth for how Full AI scores and emits diplomatic orders. Derives from [diplomacy.md](../game/diplomacy.md), [world-market.md](../game/world-market.md), [ai-planner.md](../program/ai-planner.md). Companion specs: candidate dispatch in [phase-planner-dispatch.md](phase-planner-dispatch.md); colony/overseas/decay/FTP scoring detail in [phase-planner-architecture.md](phase-planner-architecture.md); agenda/personality modifier tables and per-order ACs in [hidden-agendas.md](hidden-agendas.md); trade-order emission in [treasury-planner.md](treasury-planner.md). Implementation: `diplomatic_candidate_scoring.dart`, `war_desire_calculator.dart`.

---

## Overview

For each diplomatic order candidate, `computeDiplomaticCandidateScores` returns a pre-weighted-random integer score. A candidate starts from the **neutral base 50**, is adjusted per order type, then finalized: a structurally invalid or suppressed candidate scores **0**; every other candidate is floored to `max(1, score)`. Relation scores are **decimal** (`num`, 0.1 precision; `SPEC/game/diplomacy.md` § Relation Model); all AI threshold comparisons read the raw decimal and must not round (e.g. `69.9` does not satisfy `>= 70`).

---

## Scoring by order type

| Order type | Score model (from base 50) |
|---|---|
| `offerPeace` | `-(warDesire-50)`; futile/stalled/mutual-exhausted GP-war and peace-target bonuses; `+ agendaPeaceAcceptanceModifier + (peaceTendency-50)`. Detail: `diplomatic_candidate_scoring_offer_peace.dart` + observer peace targets. |
| `alliance` | `+ agendaAllianceAcceptanceModifier + (allianceTendency-50)`. |
| `breakAlliance` | `+ treatyBreakingModifier - allianceAcceptanceModifier - (allianceTendency-50)`. ACs: [hidden-agendas.md](hidden-agendas.md) § Behavior modifiers. |
| `boycott` | `+ treatyBreakingModifier - peaceAcceptanceModifier + (warLikelihood-50)`. ACs: [hidden-agendas.md](hidden-agendas.md). |
| `declareWar` | `war_desire_calculator` result + ~18 target bonuses; suppressed (0) when `relationScore > declareWarMaxRelationScore(agenda)` or behind victory pace. Detail: declare-war scoring parts + [hidden-agendas.md](hidden-agendas.md) § War declaration. |
| `establishOverture` | `improveRelationsDesire = 100 - warDesire`; decay-aware discount; `+ (improveRelationsDesire-50) + (allianceTendency-50)`; colonial-tribe / invadable-owner / FTP-competition bonuses; suppressed (0) on NW-collapse phase or improve-relations cooldown. Detail: [phase-planner-architecture.md](phase-planner-architecture.md). |

### War desire (`computeWarDesireScore`)

Base 50. Strength ratio (attacker/target power): `>=1.35` +30, `>=0.85` +5, else −25. Relation: `>=70` −40, `>=50` −20, `<=25` +10. Minor/Tribe targets add resource-need, intervention-risk, and invasion-capacity adjustments. Clamped to `[0,100]`.

---

## Colony-state awareness (Refs #3758 R4 / S3)

After Tribe Join Empire, the Tribe becomes a colony (`Game.colonyStates`) and keeps its provinces. `planColonialAcquisition` excludes every NW province whose owner is a Tribe that is **the active player's own colony** (`colonyOfGpId == playerId`) from all three acquisition arms (`joinEmpire`, `purchase_land`, `declareWar`). Colonies of a different GP are not excluded. Detail and ACs: [phase-planner-architecture.md](phase-planner-architecture.md) § Own-colony exclusion.

## Overseas-profit-aware purchase-land (Refs #3758 R7 / S6)

The `purchase_land` arm selects the eligible owner with the **highest relation score** (larger overseas profit share), ties broken by adjacency-distance order. Detail and ACs: [phase-planner-architecture.md](phase-planner-architecture.md) § Overseas-profit-aware purchase-land target selection.

## Embassy-kickback overture valuation (Refs #3758 R7/R8 / S6)

`establishOverture` toward a Minor/Tribe with which the AI does **not yet hold an embassy** gains a kickback incentive proportional to the seller's sales-volume proxy and relation fraction, valuing the `Q × P × relation% × 10%` overseas-profit kickback every embassy holder earns on that seller's sales — even without any purchase-land intent (no tile, no Merchant required). Detail and ACs: [phase-planner-architecture.md](phase-planner-architecture.md) § Embassy-kickback overture.

## Decay-aware overture (Refs #3758 S8)

`establishOverture` improve-relations urgency is discounted when per-turn relation decay (±`relationDecayPerTurn` toward 50) will improve a below-neutral at-peace pair on its own; the discount is suppressed when a same-turn relation event is predicted (decay is skipped on event turns). Detail and ACs: [phase-planner-architecture.md](phase-planner-architecture.md) § Decay-aware overture.

## Favoured-trading-partner competition (Refs #3758 S10)

When the AI is not the highest-relation GP for a Minor/Tribe at peace, its `establishOverture` toward that seller gains an FTP-competition bonus (winning the world-market sell-priority tiebreaker). Detail and ACs: [phase-planner-architecture.md](phase-planner-architecture.md) § Favoured-trading-partner competition overture.

## Candidate generation

Boycott and break-alliance candidates are enumerated by the order-suggestion layer (`order_suggestion_diplomatic.dart`): a `boycott` candidate per other known GP for a colony-holding AI not already boycotting that GP and at peace; a `breakAlliance` candidate per GP with which a formal alliance exists at peace. Dispatch: [phase-planner-dispatch.md](phase-planner-dispatch.md).

## Treasury-side economics

Boycott-aware **bid suppression** in `runTreasuryPlanner` is **implemented** (Refs #3758 S7/R12): when planning for a boycotted buyer, the planner drops bids for commodities only sourceable from a colony Tribe it is boycotted from. Normative detail and ACs: [treasury-planner.md](treasury-planner.md) § Boycott-aware bid suppression. Trade-deal-relation-boost-aware **bid preference** (Refs #3758 S9/R10) is **implemented**: the planner prefers the bid commodity offered by the peace-time below-neutral partner whose completed deal earns the largest `+2.0 + 0.2S + 0.4E` boost, threading it through the `preferCommodityId` ordering hint. Normative detail and ACs: [treasury-planner.md](treasury-planner.md) § Trade-deal relation-boost-aware bid preference. Market-side boycott enforcement (the authoritative trade block) already happens in deal matching (`SPEC/program/world-market-resolution.md`).

---

## Acceptance criteria

- Given a relation score of `69.9`, when the AI computes war desire toward that target, then the `>= 70` relation penalty (−40) is **not** applied; given `70.0`, the −40 penalty **is** applied.
- Given a relation score of `50.9` and a Friendly-gated colonial target, when the AI evaluates the gate (`relationScoreMinFriendly` = 51), then the target is skipped; given `51.0`, the target passes.
- Given any diplomatic candidate that is structurally valid but receives a suppression condition, when scored, then `computeDiplomaticCandidateScores` returns `0` for that candidate; otherwise the returned score is at least `1`.
- Given identical `(Game, snapshot, config)` inputs, when `computeDiplomaticCandidateScores` runs twice, then it returns identical score lists (deterministic, PlayerView-safe).
- Given a colony-holding AI at peace with GP `B` and no existing boycott against `B`, when diplomatic candidates for `B` are enumerated, then a `boycott` candidate is included; when a boycott against `B` already exists, then no duplicate `boycott` candidate is emitted.

## Interactions

- Game rules: [diplomacy.md](../game/diplomacy.md), [world-market.md](../game/world-market.md).
- AI: [hidden-agendas.md](hidden-agendas.md), [phase-planner-architecture.md](phase-planner-architecture.md), [phase-planner-dispatch.md](phase-planner-dispatch.md), [treasury-planner.md](treasury-planner.md).
