import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'turn_logging.dart';
import 'turn_resolution_seeds.dart';

/// Spy killed during spy-resolution (Refs #3834 R9).
class SpyCaughtDetail {
  const SpyCaughtDetail({
    required this.unitId,
    required this.spyOwnerId,
    required this.territoryOwnerId,
    required this.provinceId,
  });

  final String unitId;
  final String spyOwnerId;
  final String territoryOwnerId;
  final String provinceId;
}

/// Spy defected during spy-resolution (Refs #3834 R9).
class SpyDefectedDetail {
  const SpyDefectedDetail({
    required this.unitId,
    required this.previousOwnerId,
    required this.newOwnerId,
    required this.provinceId,
  });

  final String unitId;
  final String previousOwnerId;
  final String newOwnerId;
  final String provinceId;
}

/// Result of the pre-Research spy-resolution sub-step (Refs #3834 R12).
class SpyResolutionResult {
  const SpyResolutionResult({
    required this.game,
    this.killedSpyUnitIds = const [],
    this.defectedSpyUnitIds = const [],
    this.caughtSpies = const [],
    this.defectedSpies = const [],
    this.diplomacyPenaltiesApplied = 0,
  });

  final Game game;
  final List<String> killedSpyUnitIds;
  final List<String> defectedSpyUnitIds;
  final List<SpyCaughtDetail> caughtSpies;
  final List<SpyDefectedDetail> defectedSpies;
  final int diplomacyPenaltiesApplied;
}

/// Resolves spy kill rolls, diplomacy penalties, and defection rolls.
/// Runs after Diplomacy and before Research. SPEC/program/turn-resolution-phases.md.
SpyResolutionResult resolveSpyPhase(Game game, {Random? random}) {
  final turn = game.worldState.turnState.turnNumber;
  final rand = spyPhaseRandom(game, override: random);
  final ownerByProvince = ownerByProvinceIdMap(game.worldState);
  final garrisonByProvince = _garrisonRegimentCountByProvince(game);
  final counterEspGpIds = _greatPowersWithEmpireWideCounterEspionage(game);

  final units = Map<String, Unit>.from(game.worldState.allUnitsById);
  final killedIds = <String>[];
  final defectedIds = <String>[];
  final caughtDetails = <SpyCaughtDetail>[];
  final defectedDetails = <SpyDefectedDetail>[];
  var relations = List<DiplomacyRelation>.from(game.diplomacyRelations);
  var diplomacyHits = 0;

  final foreignSpies = <String, Unit>{};
  for (final entry in units.entries) {
    final u = entry.value;
    if (!isSpyUnit(u.type)) continue;
    final territoryOwner = ownerByProvince[u.locationProvinceId];
    if (territoryOwner == null || territoryOwner == u.ownerId) continue;
    foreignSpies[entry.key] = u;
  }

  // Kill rolls (survivors may defect below).
  final survivors = <String, Unit>{};
  for (final entry in foreignSpies.entries) {
    final unitId = entry.key;
    final spy = entry.value;
    final provinceId = spy.locationProvinceId;
    final territoryOwner = ownerByProvince[provinceId]!;
    final garrisonBonus = (garrisonByProvince[provinceId] ?? 0)
        .clamp(0, spyGarrisonKillChanceCapPercent);
    final counterEspBonus =
        _counterEspionageKillBonusPercent(territoryOwner, counterEspGpIds);
    final killChancePercent = spyBaseKillChancePercent +
        garrisonBonus +
        counterEspBonus;
    if (rand.nextDouble() * 100 < killChancePercent) {
      units.remove(unitId);
      killedIds.add(unitId);
      caughtDetails.add(
        SpyCaughtDetail(
          unitId: unitId,
          spyOwnerId: spy.ownerId,
          territoryOwnerId: territoryOwner,
          provinceId: provinceId,
        ),
      );
      final penalty = applySpyDeathDiplomacyPenalty(
        relations: relations,
        spyOwnerId: spy.ownerId,
        territoryOwnerId: territoryOwner,
        turn: turn,
      );
      relations = penalty.relations;
      diplomacyHits += penalty.penaltiesApplied;
      turnLog.i(
        'spy killed unitId=$unitId owner=${spy.ownerId} '
        'territory=$territoryOwner province=$provinceId '
        'chance=$killChancePercent%',
      );
      continue;
    }
    survivors[unitId] = spy;
  }

  // Defection rolls for survivors in GP territory where that GP runs counter-esp.
  for (final entry in survivors.entries) {
    final unitId = entry.key;
    final spy = entry.value;
    final provinceId = spy.locationProvinceId;
    final territoryOwner = ownerByProvince[provinceId]!;
    if (!counterEspGpIds.contains(territoryOwner)) continue;
    if (game.playerById(territoryOwner) == null) continue;
    if (rand.nextDouble() * 100 >= spyDefectionChancePercent) continue;
    final defected = spy.copyWith(
      ownerId: territoryOwner,
      currentWork: null,
      status: UnitStatus.idle,
    );
    units[unitId] = defected;
    defectedIds.add(unitId);
    defectedDetails.add(
      SpyDefectedDetail(
        unitId: unitId,
        previousOwnerId: spy.ownerId,
        newOwnerId: territoryOwner,
        provinceId: provinceId,
      ),
    );
    turnLog.i(
      'spy defected unitId=$unitId from=${spy.ownerId} to=$territoryOwner '
      'province=$provinceId',
    );
  }

  final nextGame = _gameWithUnits(game, units).copyWith(
    diplomacyRelations: relations,
  );
  return SpyResolutionResult(
    game: nextGame,
    killedSpyUnitIds: killedIds,
    defectedSpyUnitIds: defectedIds,
    caughtSpies: caughtDetails,
    defectedSpies: defectedDetails,
    diplomacyPenaltiesApplied: diplomacyHits,
  );
}

int _counterEspionageKillBonusPercent(
  String territoryOwnerId,
  Set<String> counterEspGpIds,
) {
  if (!counterEspGpIds.contains(territoryOwnerId)) return 0;
  return spyCounterEspionageKillBoostPercent;
}

Set<String> _greatPowersWithEmpireWideCounterEspionage(Game game) {
  return {
    for (final p in game.players)
      if (_playerRunsCounterEspionage(game, p.id)) p.id,
  };
}

bool _playerRunsCounterEspionage(Game game, String playerId) {
  for (final u in game.worldState.allUnitsById.values) {
    if (u.ownerId != playerId) continue;
    if (!isSpyUnit(u.type)) continue;
    if (u.currentWork?.workTarget == kWorkTargetCounterSpy) return true;
  }
  return false;
}

Map<String, int> _garrisonRegimentCountByProvince(Game game) {
  final counts = <String, int>{};
  for (final army in game.worldState.armies) {
    final provinceId = army.stationedProvinceId;
    if (provinceId == null || provinceId.isEmpty) continue;
    counts[provinceId] =
        (counts[provinceId] ?? 0) + army.regimentUnitIds.length;
  }
  return counts;
}

Game _gameWithUnits(Game game, Map<String, Unit> unitsById) {
  final oldUnits = <Unit>[];
  final newUnits = <Unit>[];
  for (final u in unitsById.values) {
    if (ProvinceId.regionIdFrom(u.locationProvinceId) == kRegionOldWorld) {
      oldUnits.add(u);
    } else {
      newUnits.add(u);
    }
  }
  return game.updateWorldState(
    (ws) => ws.copyWith(
      oldWorld: RegionData(provinces: ws.oldWorld.provinces, units: oldUnits),
      newWorld: RegionData(provinces: ws.newWorld.provinces, units: newUnits),
    ),
  );
}

/// Count of rival GPs with a spy present that have unlocked [techId].
/// Used for passive RP boost during research (Refs #3834 R2).
int spyResearchBoostGpCountForTech({
  required Game game,
  required String playerId,
  required String techId,
}) {
  if (techId.isEmpty) return 0;
  final rivalGpIdsWithSpy = <String>{};
  final ownerByProvince = ownerByProvinceIdMap(game.worldState);
  for (final u in game.worldState.allUnitsById.values) {
    if (u.ownerId != playerId) continue;
    if (!isSpyUnit(u.type)) continue;
    final territoryOwner = ownerByProvince[u.locationProvinceId];
    if (territoryOwner == null || territoryOwner == playerId) continue;
    if (game.playerById(territoryOwner) == null) continue;
    rivalGpIdsWithSpy.add(territoryOwner);
  }
  var count = 0;
  for (final rivalId in rivalGpIdsWithSpy) {
    final rival = game.playerById(rivalId);
    if (rival?.techUnlocked?[techId] == true) count++;
  }
  return count;
}

/// Applies spy RP boost multiplier to base research points (Refs #3834 R2).
int applySpyResearchBoostToPoints({
  required int basePoints,
  required int qualifyingRivalGpCount,
}) {
  if (basePoints <= 0 || qualifyingRivalGpCount <= 0) return basePoints;
  final multiplier =
      1.0 + qualifyingRivalGpCount * spyResearchBoostPerGp;
  return (basePoints * multiplier).round();
}
