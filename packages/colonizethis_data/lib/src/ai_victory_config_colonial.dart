/// Colonial pressure, naval, and overture constants.
///
/// Extracted from the victory-config kitchen sink (Refs #4121). Public API
/// remains available via `ai_victory_config.dart` and the package barrel.
library;

/// Expand-goal bonus when invadable New World tribe/minor provinces exist.
const int kColonialExpandBonusWhenInvadableNw = 45;

/// Conquer-goal bonus for colonial pressure (below OW victory floors).
const int kColonialConquerBonusWhenInvadableNw = 40;

/// Establish-overture bonus toward a preferred colonial tribe target.
const int kEstablishOvertureColonialTribeBonus = 60;

/// Establish-overture bonus toward a tribe owning a sea-reachable NW province.
const int kEstablishOvertureColonialInvadableOwnerBonus = 120;

/// Maximum reduction applied to `establishOverture` improve-relations desire
/// when per-turn relation decay (Refs #3753 R9.3/R9.4) will naturally drift a
/// below-equilibrium relation back toward neutral 50 on its own. Scaled by the
/// fraction of the gap-to-equilibrium that one turn of decay closes, so a pair
/// that decay alone restores to neutral next turn is discounted by the full
/// amount, while a deeply hostile pair (decay barely helps) is barely
/// discounted. SPEC/ai/phase-planner-architecture.md § Decay-aware overture.
const int kEstablishOvertureDecayCreditMax = 20;

/// Establish-overture incentive added when the active AI is **not** the
/// current favoured trading partner (highest GP→seller relation) for a
/// Minor/Tribe target. The favoured partner wins the world-market
/// sell-priority tiebreaker among consulate-holding buyers, so a trailing GP
/// is nudged to invest in the relationship (Refs #3758 S10/R11; #3753 R7).
/// SPEC/ai/phase-planner-architecture.md § Favoured-trading-partner
/// competition overture; SPEC/game/world-market.md § Favored Trading Partner.
const int kEstablishOvertureFtpCompetitionBonus = 30;

/// Maximum establish-overture incentive for the overseas-profit **embassy
/// kickback** (Refs #3758 R7/R8 / S6; #3753 R8.3). Every embassy-holding Great
/// Power earns `filledQuantity × pricePerUnit × (relationScore / 100) × 0.10`
/// on each world-market sale from a Minor/Tribe seller — income that requires
/// only an embassy (no purchased tile, no Merchant). When the AI does **not**
/// yet hold an embassy with a Minor/Tribe at peace, this bonus values advancing
/// the overture toward the embassy stage purely for the kickback income, scaled
/// by the relation fraction and the seller's sales-volume proxy, so a
/// high-volume seller is worth an embassy even without a purchase-land intent.
/// SPEC/ai/phase-planner-architecture.md § Embassy-kickback overture.
const int kEstablishOvertureEmbassyKickbackBonusMax = 24;

/// Seller sales-volume proxy — the count of non-empty resource tiles a
/// Minor/Tribe owns — at or above which [kEstablishOvertureEmbassyKickbackBonusMax]
/// saturates to its maximum. Below this the bonus scales linearly with the
/// seller's resource-tile count; at zero tiles no kickback bonus applies.
/// SPEC/ai/phase-planner-architecture.md § Embassy-kickback overture.
const int kEstablishOvertureEmbassyKickbackVolumeFull = 4;

/// Economy-domain weight boost for cargo preference when colonial targets exist.
const int kColonialCargoPreferenceEconomyBoost = 40;

/// Extra cargo boost when the GP owns no New World provinces yet.
const int kColonialCargoPreferenceNoNwColoniesBoost = 28;

/// Naval planner weight boost when New World invasion/colonization is viable.
const int kColonialNavalWeightBonus = 65;

/// Minimum naval planner domain weight under active colonial pressure.
const int kColonialNavalMinWeightWhenPressure = 85;

/// Naval move score when docking at a New World port under colonial pressure.
const int kColonialNavalMoveDockNewWorldPortScore = 180;

/// Naval move score for an NW sea zone bordering an invadable NW province.
const int kColonialNavalMovePriorityNwSeaZoneScore = 200;

/// Naval move score for an NW sea zone bordering a **phase-priority** NW
/// invadable province (Refs #2509 S5). Phase-priority provinces are surfaced
/// by `resolvePhaseNavalDirective` from
/// `ColonialNavalPlan.priorityInvasionTransportProvinceIdsSorted` (COLONIAL —
/// declared colonial target's invadable provinces or the at-war owner
/// fallback) or `ColonialLiteNavalPlan.priorityNwProvinceIdsSorted`
/// (COLONIAL-lite — tribe / minor-only invadable provinces). The phase-
/// priority tier ranks above the general priority tier so fleets approach the
/// phase-active acquisition frontier ahead of unrelated invadable NW
/// neighbors when both are reachable on the same turn.
const int kColonialNavalMovePhasePriorityNwSeaZoneScore = 240;

/// Naval move score for any other New World sea zone destination.
const int kColonialNavalMoveNwSeaZoneScore = 140;

/// Naval move score for an Old World sea zone with a warp/adjacent link to NW seas.
const int kColonialNavalMoveGatewaySeaZoneScore = 90;

/// Goal bonuses when the GP still owns fewer than this many NW provinces.
const int kColonialFewNwProvincesThreshold = 8;

/// Extra conquer weight when below [kColonialFewNwProvincesThreshold] NW holdings.
const int kColonialConquerBonusWhenFewNwProvinces = 55;

/// Penalty to diplomacy goal weight while sea-reachable NW targets exist and
/// holdings are below [kColonialFewNwProvincesThreshold].
const int kColonialDiplomacyGoalPenaltyWhenPressure = 45;

/// Penalty to trade goal weight under the same colonial pressure.
const int kColonialTradeGoalPenaltyWhenPressure = 25;

/// Floor for `expand` under colonial pressure (does not reduce OW floors).
const int kMinimumColonialExpandScoreWhenPressure = 90;

/// Floor for `conquer` under colonial pressure (does not reduce OW floors).
const int kMinimumColonialConquerScoreWhenPressure = 95;

/// Minimum declare-war diplomacy pass weight under colonial pressure.
const int kDiplomacyDeclareWarMinWeightWhenColonialPressure = 55;

/// Minimum conquest army-move pass weight under colonial pressure.
const int kConquestArmyMoveMinWeightWhenColonialPressure = 45;

/// Full AI explore-work score bonus when the target tile is in the New World.
const int kExploreWorkScoreBonusNewWorld = 80;

/// Civilian work economy threshold cap when colonial targets are visible.
const int kColonialCivilianWorkThresholdCap = 12;

/// Build-order economy threshold cap under COLONIAL acquisition pressure when
/// the GP already owns at least one New World province (late-game improvement
/// pacing for observer turn-150 gate; Refs #2509). Applied by
/// `resolvePhaseEconomyColonialBuildOrderThresholdCap` only when the active
/// phase is [ObserverGoalPhase.colonial]; structurally suppressed under
/// EXPAND, COLONIAL-lite, and DEVELOP per
/// `SPEC/ai/phase-planner-dispatch.md` § Orchestrator economy build
/// colonial-cap slice.
const int kColonialBuildOrderThresholdWhenOwnedNwUnderPressure = 15;

/// Naval mission score when [NavalMissionOrder.targetPortId] is a New World port.
const int kColonialNavalMissionNwPortScore = 160;

/// Naval mission score when [NavalMissionOrder.targetPortId] points at a New
/// World port whose province id is in the per-phase priority NW province
/// subset surfaced by `resolvePhaseNavalDirective` (Refs #2509 S5 mission-
/// ranking slice). One tier above [kColonialNavalMissionNwPortScore] (160) so
/// missions targeting the COLONIAL declared invasion frontier (or the
/// COLONIAL-lite tribe / minor-only subset) outrank missions toward unrelated
/// NW ports when both arms are scored on the same turn. Empty / null priority
/// list (legacy callers) preserves the prior NW-port tier exactly.
const int kColonialNavalMissionPhasePriorityNwPortScore = 200;

/// Naval mission score when [NavalMissionOrder.targetProvinceId] is in the NW.
const int kColonialNavalMissionNwProvinceScore = 130;

/// Naval mission score when [NavalMissionOrder.targetProvinceId] is in the
/// per-phase priority NW province subset (Refs #2509 S5). Mirrors the
/// [kColonialNavalMissionPhasePriorityNwPortScore] tier for the
/// `targetProvinceId` branch: one step above
/// [kColonialNavalMissionNwProvinceScore] (130) so missions targeting the
/// phase-active NW frontier rank ahead of unrelated NW-province missions.
/// Empty / null priority list preserves the legacy tier exactly.
const int kColonialNavalMissionPhasePriorityNwProvinceScore = 170;

/// Naval mission score for beachhead missions under colonial pressure.
const int kColonialNavalMissionBeachheadScore = 100;
