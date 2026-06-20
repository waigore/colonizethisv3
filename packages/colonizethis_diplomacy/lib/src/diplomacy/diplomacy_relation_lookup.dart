/// Relation and overture lookup helpers for diplomacy. SPEC/program/diplomacy-resolution.md.
/// Shared by diplomacy_resolver and order validators.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';

import 'package:colonizethis_combat/src/combat/military_strength.dart';
import 'package:colonizethis_world/src/utils/expando_index.dart';
import 'package:colonizethis_world/src/world/diplomatic_relation_lookup.dart';

export 'package:colonizethis_world/src/world/diplomatic_relation_lookup.dart';
export 'package:colonizethis_world/src/world/province_owner_cache.dart'
    show oldWorldProvinceCountOwnedBy;

/// Overture costs per diplomacy-resolution. Consulate £500, Embassy £1000.
const int overtureConsulateCost = 500;
const int overtureEmbassyCost = 1000;

/// Join Empire cost: base + per-province. SPEC/game/diplomacy.md.
const int joinEmpireBaseCost = 5000;
const int joinEmpirePerProvinceCost = 2000;

/// Returns the number of provinces owned by [factionId] (Minor or Tribe) in
/// [game].
///
/// Reads the count from the shared read-only [ProvinceOwnerCache] projection
/// (memoised per [WorldState] identity) instead of recomputing a separate
/// per-[Game] province-count scan — consolidating onto the single ownership
/// projection (Phase 6b, SPEC/program/worldstate-projection.md; Refs #3393).
/// Counts only provinces whose non-null `ownerId == factionId`, identical to
/// the prior full-world `allProvinces` scan.
int provinceCountOwnedBy(Game game, String factionId) =>
    ProvinceOwnerCache.of(game.worldState).countOwnedBy(factionId);

/// Default weights for Great Power power score. SPEC/game/diplomacy.md § Great Power power score.
const int powerScoreProvinceWeight = 10;
const int powerScoreRegimentWeight = 1;
const int powerScoreShipWeight = 5;

/// Total number of ships (sum of shipTypeIds.length) over all fleets owned by [factionId].
int shipCountForFaction(Game game, String factionId) {
  var count = 0;
  for (final f in game.worldState.fleets) {
    if (f.ownerId == factionId) count += f.shipTypeIds.length;
  }
  return count;
}

/// Absolute power score for a Great Power. SPEC/game/diplomacy.md § Great Power power score.
/// Formula: provinceCount×W_province + round(regimentStrength)×W_regiment + shipCount×W_ship.
int greatPowerPowerScore(Game game, String factionId) {
  final provinces = provinceCountOwnedBy(game, factionId);
  final regimentStrength = aggregateMilitaryStrengthForPlayer(game, factionId);
  final ships = shipCountForFaction(game, factionId);
  return provinces * powerScoreProvinceWeight +
      regimentStrength.round() * powerScoreRegimentWeight +
      ships * powerScoreShipWeight;
}

/// Great Power with strictly highest [greatPowerPowerScore], or `null` when tied
/// or there are no players. SPEC/game/victory.md § Calendar campaign end.
String? pickUniqueGreatPowerLeaderByPowerScore(Game game) {
  if (game.players.isEmpty) return null;
  final scores = <String, int>{
    for (final p in game.players) p.id: greatPowerPowerScore(game, p.id),
  };
  var bestScore = -1;
  for (final s in scores.values) {
    if (s > bestScore) bestScore = s;
  }
  final leaders =
      scores.entries
          .where((e) => e.value == bestScore)
          .map((e) => e.key)
          .toList()
        ..sort();
  if (leaders.length != 1) return null;
  return leaders.single;
}

/// Join Empire cost in pounds for absorbing [targetId] (Minor or Tribe).
int joinEmpireCostForMinorOrTribe(Game game, String targetId) {
  final n = provinceCountOwnedBy(game, targetId);
  return joinEmpireBaseCost + n * joinEmpirePerProvinceCost;
}

// --- Relation score bounds and thresholds. SPEC/game/diplomacy.md. ---

/// Relation score range: min and max (inclusive).
const int relationScoreMin = 0;
const int relationScoreMax = 100;

/// Neutral relation score; convergence target and default for new relations.
const int relationScoreNeutral = 50;

/// Level thresholds (inclusive max per band): Hostile ]0,25], Neutral ]25,50], Friendly ]50,75], Allied ]75,100].
const int relationScoreLevelHostileMax = 25;
const int relationScoreLevelNeutralMax = 50;
const int relationScoreLevelFriendlyMax = 75;

/// Minimum score for Friendly (and Allied). Join Empire and similar require >= this.
const int relationScoreMinFriendly = 51;

/// Minimum relation score for FTP acceptance (proposer and acceptor). SPEC/game/world-market.md.
const int relationScoreMinFtp = 65;

/// Alliance score band: when forming alliance, score is set/clamped to this range.
const int relationScoreMinAllied = 76;

/// Display label thresholds (inclusive max): Hostile ]0,29], Unfriendly ]29,49], Cordial ]49,69], Friendly ]69,100].
const int relationScoreDisplayHostileMax = 29;
const int relationScoreDisplayUnfriendlyMax = 49;
const int relationScoreDisplayCordialMax = 69;

/// Relation score change on war declaration (protest path). Clamped to [relationScoreMin, relationScoreMax].
const int relationScoreWarDelta = 10;

/// Reduced penalty when the aggressor has [kTechIdPropaganda]. SPEC/game/tech-tree-diplomacy-civilian.md.
const int relationScoreWarDeltaReducedPropaganda = 5;

/// Score penalty applied to third parties (e.g. intervention) reacting to [aggressorGpId]'s war declaration.
int warDeclarationThirdPartyPenaltyDelta(Game game, String aggressorGpId) {
  final u = game.playerById(aggressorGpId)?.techUnlocked;
  if (u?[kTechIdPropaganda] == true) {
    return relationScoreWarDeltaReducedPropaganda;
  }
  return relationScoreWarDelta;
}

/// Score drop on ally refusing a call to arms; alliance ends (no longer Allied). SPEC/game/diplomacy.md.
const int callToArmsRefusalScorePenalty = 20;

/// AI ally joins the war if B–A relation score is at least this (inclusive). SPEC/game/diplomacy.md.
const int callToArmsAiAcceptMinRelationScore = 50;

/// AI intervention probability by relation level (0–1). SPEC/game/diplomacy.md § Intervention.
/// Relation score 0–25 (Hostile) → 0%, 26–50 (Neutral) → 25%, 51–75 (Friendly) → 50%, 76–100 (Allied) → 80%.
const double kInterventionProbabilityNeutral = 0.25;
const double kInterventionProbabilityFriendly = 0.5;
const double kInterventionProbabilityAllied = 0.8;

/// Default Grant Aid amount (UI + suggestions). Positive multiples of [grantAidAmountStep].
const int grantAidDefaultAmount = 1000;

/// Default Set Subsidy amount (UI + suggestions). Positive multiples of [setSubsidyAmountStep].
const int setSubsidyDefaultAmount = 1000;

/// Grant Aid step and multiple (pounds). Validation and UI stepper.
const int grantAidAmountStep = 1000;

/// Set Subsidy step and multiple (pounds). Validation and UI stepper.
const int setSubsidyAmountStep = 100;

/// Subsidy relation boost: +[subsidyBoostRelationPerStep] per [subsidyBoostDucatsPerStep] ducats, cap [subsidyBoostMax].
const int subsidyBoostDucatsPerStep = 500;
const int subsidyBoostRelationPerStep = 2;
const int subsidyBoostMax = 8;

/// Relation score thresholds for level. 0–25 Hostile, 26–50 Neutral, 51–75 Friendly, 76–100 Allied.
RelationLevel scoreToLevel(int score) {
  if (score <= relationScoreLevelHostileMax) return RelationLevel.hostile;
  if (score <= relationScoreLevelNeutralMax) return RelationLevel.neutral;
  if (score <= relationScoreLevelFriendlyMax) return RelationLevel.friendly;
  return RelationLevel.allied;
}

/// One-word relation state for UI display. SPEC/game/diplomacy.md § Player-facing relation display.
/// Score is hidden; UI shows this label: 0–29 Hostile, 30–49 Unfriendly, 50–69 Cordial, 70–100 Friendly.
String relationScoreToDisplayLabel(int score) {
  final clamped = score.clamp(relationScoreMin, relationScoreMax);
  if (clamped <= relationScoreDisplayHostileMax) return 'Hostile';
  if (clamped <= relationScoreDisplayUnfriendlyMax) return 'Unfriendly';
  if (clamped <= relationScoreDisplayCordialMax) return 'Cordial';
  return 'Friendly';
}

/// Directed GP → Minor/Tribe overture rows, keyed by `_overtureLookupKey`.
/// Routed through the shared [ExpandoIndex] utility (Refs #2836 AC 2).
final ExpandoIndex<Game, Map<String, OvertureState>>
_gameOvertureStatesByGpTargetIndex =
    ExpandoIndex<Game, Map<String, OvertureState>>(
      'gameOvertureStatesByGpTarget',
      (game) {
        final map = <String, OvertureState>{};
        for (final o in game.overtureStates) {
          map.putIfAbsent(_overtureLookupKey(o.gpId, o.targetId), () => o);
        }
        return map;
      },
    );

String _overtureLookupKey(String gpId, String targetId) => '$gpId|$targetId';

Map<String, OvertureState> _overtureStatesByLookupKey(Game game) =>
    _gameOvertureStatesByGpTargetIndex.get(game);

/// Finds the relation, passes it (or null) to [updater], and replaces or
/// appends the result.
///
/// **Soft-deprecated for batched/loop use in favour of [RelationUpsertIndex]**
/// (Refs #3562 AC5). It is not annotated `@Deprecated` because it remains the
/// correct primitive for a genuinely *single* isolated upsert, and a hard
/// annotation would wrongly flag those legitimate call sites; instead the
/// acceptable single-call-vs-batched guidance is documented here and at the
/// remaining single-call sites.
///
/// Each call rebuilds the `pairKey → firstIndex` map and copies the whole
/// relations list, so it is O(relations) per call. Use it only for a **single
/// isolated upsert** (one accepted order / one resolver event). For **repeated**
/// upserts in a loop — multiple orders, per-tribe first contact, batched phase
/// mutations — prefer [RelationUpsertIndex], which builds the index once and
/// keeps each upsert amortized O(1); calling [upsertRelation] in a loop silently
/// reintroduces an O(relations²) pattern (Refs #3562 AC5).
List<DiplomacyRelation> upsertRelation(
  List<DiplomacyRelation> relations,
  String factionId1,
  String factionId2,
  DiplomacyRelation Function(DiplomacyRelation?) updater,
) {
  final key = pairKey(factionId1, factionId2);
  final firstIndexByPairKey = <String, int>{};
  for (var i = 0; i < relations.length; i++) {
    final r = relations[i];
    final rk = pairKey(r.factionId1, r.factionId2);
    firstIndexByPairKey.putIfAbsent(rk, () => i);
  }
  final idx = firstIndexByPairKey[key];
  final existing = idx != null ? relations[idx] : null;
  final updated = updater(existing);
  final result = List<DiplomacyRelation>.from(relations);
  if (idx != null) {
    result[idx] = updated;
  } else {
    result.add(updated);
  }
  return result;
}

/// Mutable accumulator for repeated relation upserts in a single phase.
///
/// Builds the `pairKey → firstIndex` map **once** at construction and keeps it
/// current as relations are appended, so each [upsert] is amortized O(1).
/// This replaces calling the standalone [upsertRelation] in a loop, which
/// rebuilt the whole index (and copied the entire list) on every call —
/// O(relations²) across a phase (Refs #3419 step 5).
///
/// Produces results identical to applying [upsertRelation] sequentially over
/// the same starting list and updaters; call [toList] for a defensive copy
/// suitable for `copyWith`.
class RelationUpsertIndex {
  RelationUpsertIndex(List<DiplomacyRelation> relations)
    : _relations = List<DiplomacyRelation>.from(relations) {
    for (var i = 0; i < _relations.length; i++) {
      final r = _relations[i];
      _firstIndexByPairKey.putIfAbsent(
        pairKey(r.factionId1, r.factionId2),
        () => i,
      );
    }
  }

  final List<DiplomacyRelation> _relations;
  final Map<String, int> _firstIndexByPairKey = <String, int>{};

  /// Number of relations currently held.
  int get length => _relations.length;

  /// Finds the relation for the [factionId1]/[factionId2] pair, passes it (or
  /// null) to [updater], and replaces or appends the result in place.
  void upsert(
    String factionId1,
    String factionId2,
    DiplomacyRelation Function(DiplomacyRelation?) updater,
  ) {
    final key = pairKey(factionId1, factionId2);
    final idx = _firstIndexByPairKey[key];
    final existing = idx != null ? _relations[idx] : null;
    final updated = updater(existing);
    if (idx != null) {
      _relations[idx] = updated;
    } else {
      _relations.add(updated);
      _firstIndexByPairKey[key] = _relations.length - 1;
    }
  }

  /// Defensive copy of the accumulated relations for storing on a [Game].
  List<DiplomacyRelation> toList() => List<DiplomacyRelation>.from(_relations);
}

/// Returns overture state for GP–Minor/Tribe, or null.
OvertureState? getOverture(Game game, String gpId, String targetId) {
  return _overtureStatesByLookupKey(game)[_overtureLookupKey(gpId, targetId)];
}

/// Embassy-tier overture from [gpId] toward [targetId]. SPEC/game/world-market.md.
bool hasEmbassyOverture(Game game, String gpId, String targetId) {
  final o = getOverture(game, gpId, targetId);
  return o != null && o.hasEmbassy;
}

/// Bilateral FTP active between [factionId1] and [factionId2].
bool hasFtpPartnership(Game game, String factionId1, String factionId2) {
  return game.ftpPartnershipKeys.contains(pairKey(factionId1, factionId2));
}

/// Active FTP pair keys for world-market matching. SPEC/program/world-market-resolution.md.
Set<String> ftpPairKeysFromGame(Game game) =>
    Set<String>.from(game.ftpPartnershipKeys);

/// True if [playerId] may attack [targetOwnerId]: at war or declaring war this turn.
/// Used by move validator for GP and Minor/Tribe attack checks. SPEC/program/orders.md.
bool canAttackWithWarOrDeclaring(
  Game game,
  String playerId,
  String targetOwnerId,
  List<DiplomaticOrder> diplomaticOrders,
) {
  final rel = getRelation(game, playerId, targetOwnerId);
  final atWar = rel?.atWar ?? false;
  final declaringWarThisTurn = diplomaticOrders.any(
    (o) =>
        o.type == DiplomaticOrderType.declareWar &&
        o.targetFactionId == targetOwnerId,
  );
  return atWar || declaringWarThisTurn;
}

/// Diplomatic history events involving both [factionA] and [factionB], newest first.
/// SPEC/ui/diplomacy-panel.md § Diplomacy Detail — history contents.
List<DiplomaticEvent> diplomaticHistoryForPair(
  Game game,
  String factionA,
  String factionB,
) {
  final list = game.diplomaticHistoryEvents
      .where(
        (e) =>
            e.participants.contains(factionA) &&
            e.participants.contains(factionB),
      )
      .toList();
  list.sort((a, b) {
    final turnCmp = b.turn.compareTo(a.turn);
    if (turnCmp != 0) return turnCmp;
    return b.intraTurnIndex.compareTo(a.intraTurnIndex);
  });
  return list;
}
