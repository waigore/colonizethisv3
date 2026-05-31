/// Relation and overture lookup helpers for diplomacy. SPEC/program/diplomacy-resolution.md.
/// Shared by diplomacy_resolver and order validators.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';

import '../combat/military_strength.dart';
import '../utils/expando_index.dart';
import '../world/province_lookup.dart';

/// Overture costs per diplomacy-resolution. Consulate £500, Embassy £1000.
const int overtureConsulateCost = 500;
const int overtureEmbassyCost = 1000;

/// Join Empire cost: base + per-province. SPEC/game/diplomacy.md.
const int joinEmpireBaseCost = 5000;
const int joinEmpirePerProvinceCost = 2000;

/// Lazily built per [Game] instance (issue #2268 AC-5). A new [Game] from
/// [Game.copyWith] does not share expando state with the previous instance.
/// Routed through the shared [ExpandoIndex] utility so all `colonizethis_logic`
/// per-[Game] caches share one invalidation contract (Refs #2836 AC 2).
final ExpandoIndex<Game, Map<String, int>> _gameProvinceCountsByOwnerIndex =
    ExpandoIndex<Game, Map<String, int>>('gameProvinceCountsByOwner', (game) {
      final built = <String, int>{};
      for (final p in allProvinces(game.worldState)) {
        final oid = p.ownerId;
        if (oid == null) continue;
        built[oid] = (built[oid] ?? 0) + 1;
      }
      return built;
    });

Map<String, int> _provinceCountsByOwner(Game game) =>
    _gameProvinceCountsByOwnerIndex.get(game);

/// Returns the number of provinces owned by [factionId] (Minor or Tribe) in [game].
int provinceCountOwnedBy(Game game, String factionId) {
  return _provinceCountsByOwner(game)[factionId] ?? 0;
}

/// Old World provinces owned by [factionId] (observer conquest / survival peace).
int oldWorldProvinceCountOwnedBy(Game game, String factionId) {
  return game.worldState
      .provincesForRegion(kRegionOldWorld)
      .where((p) => p.ownerId == factionId)
      .length;
}

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

/// Normalizes faction pair for lookup (consistent ordering).
String pairKey(String a, String b) => a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';

/// Lazily built per [Game] instance (issue #2268 AC-4). A new [Game] from
/// [Game.copyWith] does not share expando state with the previous instance.
/// Routed through the shared [ExpandoIndex] utility (Refs #2836 AC 2).
final ExpandoIndex<Game, Map<String, DiplomacyRelation>>
_gameDiplomacyRelationsByPairKeyIndex =
    ExpandoIndex<Game, Map<String, DiplomacyRelation>>(
      'gameDiplomacyRelationsByPairKey',
      (game) {
        final map = <String, DiplomacyRelation>{};
        for (final r in game.diplomacyRelations) {
          map.putIfAbsent(pairKey(r.factionId1, r.factionId2), () => r);
        }
        return map;
      },
    );

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

Map<String, DiplomacyRelation> _diplomacyRelationsByPairKey(Game game) =>
    _gameDiplomacyRelationsByPairKeyIndex.get(game);

Map<String, OvertureState> _overtureStatesByLookupKey(Game game) =>
    _gameOvertureStatesByGpTargetIndex.get(game);

/// Returns relation for faction pair, or null if not found.
DiplomacyRelation? getRelation(
  Game game,
  String factionId1,
  String factionId2,
) {
  final key = pairKey(factionId1, factionId2);
  return _diplomacyRelationsByPairKey(game)[key];
}

/// Finds the relation, passes it (or null) to [updater], and replaces or appends the result.
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

/// True when [a] and [b] are at war according to [game.diplomacyRelations].
bool factionsAtWar(Game game, String a, String b) {
  final rel = getRelation(game, a, b);
  return rel?.atWar ?? false;
}

/// Undirected adjacency: for each faction id, the set of faction ids at war
/// with it (from [game.diplomacyRelations], using [DiplomacyRelation.atWar]).
///
/// Used by naval visibility, naval combat conflict detection, and sea trade
/// interception. Issue #2178 Phase A; keep in sync with [factionsAtWar].
Map<String, Set<String>> hostileFactionsByFaction(Game game) {
  final out = <String, Set<String>>{};
  for (final rel in game.diplomacyRelations) {
    if (!rel.atWar) continue;
    out.putIfAbsent(rel.factionId1, () => <String>{}).add(rel.factionId2);
    out.putIfAbsent(rel.factionId2, () => <String>{}).add(rel.factionId1);
  }
  return out;
}

/// Faction ids currently at war with [playerId] (empty if none or unknown).
Set<String> enemiesOf(Game game, String playerId) =>
    hostileFactionsByFaction(game)[playerId] ?? const <String>{};

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
