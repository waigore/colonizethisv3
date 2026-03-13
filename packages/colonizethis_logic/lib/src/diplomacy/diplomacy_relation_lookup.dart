/// Relation and overture lookup helpers for diplomacy. SPEC/program/diplomacy-resolution.md.
/// Shared by diplomacy_resolver and order validators.

import 'package:colonizethis_models/colonizethis_models.dart';

import '../combat/military_strength.dart';

/// Overture costs per diplomacy-resolution. Consulate £500, Embassy £1000.
const int overtureConsulateCost = 500;
const int overtureEmbassyCost = 1000;

/// Join Empire cost: base + per-province. SPEC/game/diplomacy.md.
const int joinEmpireBaseCost = 5000;
const int joinEmpirePerProvinceCost = 2000;

/// Returns the number of provinces owned by [factionId] (Minor or Tribe) in [game].
int provinceCountOwnedBy(Game game, String factionId) {
  int count = 0;
  for (final p in game.worldState.oldWorld.provinces) {
    if (p.ownerId == factionId) count++;
  }
  for (final p in game.worldState.newWorld.provinces) {
    if (p.ownerId == factionId) count++;
  }
  return count;
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

/// Alliance score band: when forming alliance, score is set/clamped to this range.
const int relationScoreMinAllied = 76;

/// Display label thresholds (inclusive max): Hostile ]0,29], Unfriendly ]29,49], Cordial ]49,69], Friendly ]69,100].
const int relationScoreDisplayHostileMax = 29;
const int relationScoreDisplayUnfriendlyMax = 49;
const int relationScoreDisplayCordialMax = 69;

/// Relation score change on war declaration (protest path). Clamped to [relationScoreMin, relationScoreMax].
const int relationScoreWarDelta = 10;

/// Suggested grant/subsidy amount for AI order suggestion when GP has embassy/consulate.
const int suggestedGrantOrSubsidyAmount = 100;

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
String pairKey(String a, String b) =>
    a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';

/// Returns relation for faction pair, or null if not found.
DiplomacyRelation? getRelation(
    Game game, String factionId1, String factionId2) {
  final key = pairKey(factionId1, factionId2);
  for (final r in game.diplomacyRelations) {
    if (pairKey(r.factionId1, r.factionId2) == key) return r;
  }
  return null;
}

/// Finds the relation, passes it (or null) to [updater], and replaces or appends the result.
List<DiplomacyRelation> upsertRelation(
  List<DiplomacyRelation> relations,
  String factionId1,
  String factionId2,
  DiplomacyRelation Function(DiplomacyRelation?) updater,
) {
  final key = pairKey(factionId1, factionId2);
  final idx =
      relations.indexWhere((r) => pairKey(r.factionId1, r.factionId2) == key);
  final existing = idx >= 0 ? relations[idx] : null;
  final updated = updater(existing);
  final result = List<DiplomacyRelation>.from(relations);
  if (idx >= 0) {
    result[idx] = updated;
  } else {
    result.add(updated);
  }
  return result;
}

/// Returns overture state for GP–Minor/Tribe, or null.
OvertureState? getOverture(Game game, String gpId, String targetId) {
  for (final o in game.overtureStates) {
    if (o.gpId == gpId && o.targetId == targetId) return o;
  }
  return null;
}

/// True when [a] and [b] are at war according to [game.diplomacyRelations].
bool factionsAtWar(Game game, String a, String b) {
  final rel = getRelation(game, a, b);
  return rel?.atWar ?? false;
}

/// Returns player by id, or null.
Player? getPlayer(Game game, String playerId) {
  for (final p in game.players) {
    if (p.id == playerId) return p;
  }
  return null;
}

/// Diplomatic history events involving both [factionA] and [factionB], newest first.
/// SPEC/ui/diplomacy-panel.md § Diplomacy Detail — history contents.
List<DiplomaticEvent> diplomaticHistoryForPair(
  Game game,
  String factionA,
  String factionB,
) {
  final list = game.diplomaticHistoryEvents
      .where((e) =>
          e.participants.contains(factionA) && e.participants.contains(factionB))
      .toList();
  list.sort((a, b) {
    final turnCmp = b.turn.compareTo(a.turn);
    if (turnCmp != 0) return turnCmp;
    return b.intraTurnIndex.compareTo(a.intraTurnIndex);
  });
  return list;
}
