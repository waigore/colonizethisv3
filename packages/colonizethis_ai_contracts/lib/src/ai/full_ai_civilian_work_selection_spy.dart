part of 'full_ai_civilian_work_selection.dart';

// Spy (`steal_tech` / `counter_spy`) candidate scoring / row selection and the
// Spy path appender. Replaces the lexicographic fallback (which always picked
// `counter_spy` first because it sorts alphabetically before `steal_tech`) with
// a unified, phase-dependent scored pool over both Spy targets. Split out of
// full_ai_civilian_work_selection.dart by concern to keep each library file
// small; shares the parent library's private scope via `part`.
//
// Normative SPEC: SPEC/ai/civilian-work-planner.md § Spy (Refs #3794, AC23-AC31).
// Spy selection is phase-dependent: outside DEVELOP `steal_tech` is preferred,
// in DEVELOP `counter_spy` is preferred, expressed as a GA-tunable phase bonus
// sized to dominate the other target's contextual bonuses. All factors use
// cheap, deterministic proxies (tech-deficit count, expando-cached diplomacy
// lookups, a ground-truth enemy-Spy province scan) rather than path-finding.

const int _kSpyTechDeficitCap = 60;

bool _isSpyWorkTarget(String target) =>
    target == kWorkTargetStealTech || target == kWorkTargetCounterSpy;

/// Count of techs the rival GP [rivalId] has unlocked that [playerId] lacks,
/// capped at [_kSpyTechDeficitCap] for determinism / budget.
int _spyTechDeficit(Game game, String playerId, String rivalId) {
  final rival = game.playerById(rivalId);
  final rivalTechs = rival?.techUnlocked;
  if (rivalTechs == null || rivalTechs.isEmpty) return 0;
  final ownTechs = game.playerById(playerId)?.techUnlocked ?? const {};
  var deficit = 0;
  for (final entry in rivalTechs.entries) {
    if (entry.value != true) continue;
    if (ownTechs[entry.key] == true) continue;
    deficit++;
    if (deficit >= _kSpyTechDeficitCap) return _kSpyTechDeficitCap;
  }
  return deficit;
}

/// The rival Great Power whose capital province is [provinceId], or null.
Player? _spyRivalGpForCapitalProvince(
  Game game,
  String playerId,
  String? provinceId,
) {
  if (provinceId == null) return null;
  for (final p in game.players) {
    if (p.id == playerId) continue;
    if (p.capitalProvinceId == provinceId) return p;
  }
  return null;
}

/// Relation score at or below which a rival is treated as hostile (the 0-25
/// Hostile band per SPEC/game/diplomacy.md § Relation Model). Scores are decimal
/// in `[0, 100]` with 50 neutral, so "worse relations" means a lower score.
const num _kSpyHostileRelationMaxScore = 25;

bool _spyHasHostileRelations(Game game, String playerId, String rivalId) {
  if (factionsAtWar(game, playerId, rivalId)) return true;
  final rel = getRelation(game, playerId, rivalId);
  return rel != null && rel.score <= _kSpyHostileRelationMaxScore;
}

/// Deterministic Full AI score for a Spy `steal_tech` / `counter_spy` [w]
/// candidate. Returns `0` for any non-Spy target so a mixed candidate list never
/// scores a foreign target.
int _spyWorkScore(
  WorkOrder w,
  Game game, {
  required String playerId,
  required bool spyDevelopPhase,
  required String? spyRegionId,
  required Set<String> enemySpyProvinceIds,
}) {
  final provinceId = Unit.provinceIdFromTileKey(w.targetTileKey);
  switch (w.target) {
    case kWorkTargetStealTech:
      var score = kSpyStealTechBaseWorkScore;
      final rival = _spyRivalGpForCapitalProvince(game, playerId, provinceId);
      if (rival != null) {
        score += _spyTechDeficit(game, playerId, rival.id) *
            kSpyStealTechTechDeficitWeight;
        if (_spyHasHostileRelations(game, playerId, rival.id)) {
          score += kSpyStealTechHostileRelationsBonus;
        }
      }
      final rivalRegionId = Unit.regionIdFromTileKey(w.targetTileKey);
      if (spyRegionId != null && rivalRegionId == spyRegionId) {
        score += kSpyStealTechProximityBonus;
      }
      if (!spyDevelopPhase) score += kSpyPhaseStealTechBonus;
      return score;
    case kWorkTargetCounterSpy:
      var score = kSpyCounterSpyBaseWorkScore;
      if (provinceId != null && enemySpyProvinceIds.contains(provinceId)) {
        score += kSpyCounterSpyEnemySpyPresenceBonus;
      }
      final capitalProvinceId = game.playerById(playerId)?.capitalProvinceId;
      if (capitalProvinceId != null && provinceId == capitalProvinceId) {
        score += kSpyCounterSpyCapitalBonus;
      }
      if (Unit.regionIdFromTileKey(w.targetTileKey) == kNewWorldRegionId) {
        score += kSpyCounterSpyBorderBonus;
      }
      if (spyDevelopPhase) score += kSpyPhaseCounterSpyBonus;
      return score;
  }
  return 0;
}

/// Stable, non-alphabetical-on-target secondary ordering for equally-scored Spy
/// candidates: province id first, then full tile key, then target (Refs #3794
/// AC30). Score, not target alphabetisation, drives the primary choice.
int _compareSpyCandidate(WorkOrder a, WorkOrder b) {
  final pa = Unit.provinceIdFromTileKey(a.targetTileKey) ?? '';
  final pb = Unit.provinceIdFromTileKey(b.targetTileKey) ?? '';
  final p = pa.compareTo(pb);
  if (p != 0) return p;
  final t = a.targetTileKey.compareTo(b.targetTileKey);
  if (t != 0) return t;
  return a.target.compareTo(b.target);
}

/// Province ids (canonical prefixed) currently occupied by a foreign-owned Spy.
Set<String> _spyEnemySpyProvinceIds(Game game, String playerId) {
  final out = <String>{};
  for (final u in game.worldState.allUnitsById.values) {
    if (u.ownerId == playerId) continue;
    if (!isSpyUnit(u.type)) continue;
    out.add(u.locationProvinceId);
  }
  return out;
}

WorkOrder? _bestSpyRow(
  List<WorkOrder> candidates,
  Game game, {
  required String playerId,
  required bool spyDevelopPhase,
  required String? spyRegionId,
  required Set<String> enemySpyProvinceIds,
}) {
  final spyCandidates = candidates
      .where((w) => _isSpyWorkTarget(w.target))
      .toList();
  if (spyCandidates.isEmpty) return null;
  var best = spyCandidates.first;
  var bestScore = _spyWorkScore(
    best,
    game,
    playerId: playerId,
    spyDevelopPhase: spyDevelopPhase,
    spyRegionId: spyRegionId,
    enemySpyProvinceIds: enemySpyProvinceIds,
  );
  for (var i = 1; i < spyCandidates.length; i++) {
    final w = spyCandidates[i];
    final s = _spyWorkScore(
      w,
      game,
      playerId: playerId,
      spyDevelopPhase: spyDevelopPhase,
      spyRegionId: spyRegionId,
      enemySpyProvinceIds: enemySpyProvinceIds,
    );
    if (s > bestScore) {
      bestScore = s;
      best = w;
      continue;
    }
    if (s == bestScore && _compareSpyCandidate(w, best) < 0) {
      best = w;
    }
  }
  return best;
}

void _appendSpyPathResult({
  required Unit? unit,
  required List<WorkOrder> w,
  required Game game,
  required String playerId,
  required bool spyDevelopPhase,
  required List<WorkOrder> workOrders,
  required List<FullAiCivilianWorkIdle> idleEvents,
}) {
  final spyRegionId = unit == null
      ? null
      : ProvinceId.regionIdFrom(unit.locationProvinceId);
  final enemySpyProvinceIds = _spyEnemySpyProvinceIds(game, playerId);
  final chosen =
      _bestSpyRow(
        w,
        game,
        playerId: playerId,
        spyDevelopPhase: spyDevelopPhase,
        spyRegionId: spyRegionId,
        enemySpyProvinceIds: enemySpyProvinceIds,
      ) ??
      _pickLexicographic(w);
  if (chosen != null) {
    workOrders.add(chosen);
    return;
  }
  if (unit == null) return;
  idleEvents.add(
    FullAiCivilianWorkIdle(
      unitId: unit.id,
      unitType: unit.type,
      reason: 'no_suggestions',
    ),
  );
}
