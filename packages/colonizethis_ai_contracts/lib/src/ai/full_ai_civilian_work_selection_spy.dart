part of 'full_ai_civilian_work_selection.dart';

// Spy (`counter_spy`) candidate scoring / row selection. Refs #3834 R11.
// Empire-wide counter-espionage: one spy on counter_spy anywhere is sufficient.
// Passive RP boost and scouting require no work order — idle spies in rival GP
// territory are handled by movement, not work selection.

bool _isSpyWorkTarget(String target) => target == kWorkTargetCounterSpy;

int _spyWorkScore(
  WorkOrder w,
  Game game, {
  required String playerId,
  required bool spyDevelopPhase,
  required Set<String> enemySpyProvinceIds,
  required bool playerAlreadyHasCounterSpy,
}) {
  if (w.target != kWorkTargetCounterSpy) return 0;
  if (playerAlreadyHasCounterSpy) {
    return kSpyCounterSpyBaseWorkScore ~/ 10;
  }
  var score = kSpyCounterSpyBaseWorkScore;
  final provinceId = Unit.provinceIdFromTileKey(w.targetTileKey);
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

int _compareSpyCandidate(WorkOrder a, WorkOrder b) {
  final pa = Unit.provinceIdFromTileKey(a.targetTileKey) ?? '';
  final pb = Unit.provinceIdFromTileKey(b.targetTileKey) ?? '';
  final p = pa.compareTo(pb);
  if (p != 0) return p;
  return a.targetTileKey.compareTo(b.targetTileKey);
}

Set<String> _spyEnemySpyProvinceIds(Game game, String playerId) {
  final out = <String>{};
  for (final u in game.worldState.allUnitsById.values) {
    if (u.ownerId == playerId) continue;
    if (!isSpyUnit(u.type)) continue;
    out.add(u.locationProvinceId);
  }
  return out;
}

bool _playerHasCounterSpyAssignment(Game game, String playerId) {
  for (final u in game.worldState.allUnitsById.values) {
    if (u.ownerId != playerId) continue;
    if (!isSpyUnit(u.type)) continue;
    if (u.currentWork?.workTarget == kWorkTargetCounterSpy) return true;
  }
  return false;
}

WorkOrder? _bestSpyRow(
  List<WorkOrder> candidates,
  Game game, {
  required String playerId,
  required bool spyDevelopPhase,
  required Set<String> enemySpyProvinceIds,
  required bool playerAlreadyHasCounterSpy,
}) {
  final spyCandidates =
      candidates.where((w) => _isSpyWorkTarget(w.target)).toList();
  if (spyCandidates.isEmpty) return null;
  var best = spyCandidates.first;
  var bestScore = _spyWorkScore(
    best,
    game,
    playerId: playerId,
    spyDevelopPhase: spyDevelopPhase,
    enemySpyProvinceIds: enemySpyProvinceIds,
    playerAlreadyHasCounterSpy: playerAlreadyHasCounterSpy,
  );
  for (var i = 1; i < spyCandidates.length; i++) {
    final w = spyCandidates[i];
    final s = _spyWorkScore(
      w,
      game,
      playerId: playerId,
      spyDevelopPhase: spyDevelopPhase,
      enemySpyProvinceIds: enemySpyProvinceIds,
      playerAlreadyHasCounterSpy: playerAlreadyHasCounterSpy,
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
  final enemySpyProvinceIds = _spyEnemySpyProvinceIds(game, playerId);
  final playerAlreadyHasCounterSpy =
      _playerHasCounterSpyAssignment(game, playerId);
  final chosen =
      _bestSpyRow(
        w,
        game,
        playerId: playerId,
        spyDevelopPhase: spyDevelopPhase,
        enemySpyProvinceIds: enemySpyProvinceIds,
        playerAlreadyHasCounterSpy: playerAlreadyHasCounterSpy,
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
