import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'spy_resolution_models.dart';
import 'spy_resolution_support.dart';
import 'turn_logging.dart';
import 'turn_resolution_seeds.dart';

export 'spy_research_boost.dart'
    show
        applySpyResearchBoostToPoints,
        spyResearchBoostGpCountForTech,
        spyResearchBoostRivalIdsForTech;
export 'spy_resolution_models.dart'
    show SpyCaughtDetail, SpyDefectedDetail, SpyResolutionResult;

/// Resolves spy kill rolls, diplomacy penalties, and defection rolls.
/// Runs after Diplomacy and before Research. SPEC/program/turn-resolution-phases.md.
SpyResolutionResult resolveSpyPhase(Game game, {Random? random}) {
  final turn = game.worldState.turnState.turnNumber;
  final rand = spyPhaseRandom(game, override: random);
  final ownerByProvince = ownerByProvinceIdMap(game.worldState);
  final garrisonByProvince = garrisonRegimentCountByProvince(game);
  final counterEspGpIds = greatPowersWithEmpireWideCounterEspionage(game);

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
    final garrisonBonus = (garrisonByProvince[provinceId] ?? 0).clamp(
      0,
      spyGarrisonKillChanceCapPercent,
    );
    final counterEspBonus = counterEspionageKillBonusPercent(
      territoryOwner,
      counterEspGpIds,
    );
    final killChancePercent =
        spyBaseKillChancePercent + garrisonBonus + counterEspBonus;
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

  final nextGame = gameWithSpyUnits(
    game,
    units,
  ).copyWith(diplomacyRelations: relations);
  return SpyResolutionResult(
    game: nextGame,
    killedSpyUnitIds: killedIds,
    defectedSpyUnitIds: defectedIds,
    caughtSpies: caughtDetails,
    defectedSpies: defectedDetails,
    diplomacyPenaltiesApplied: diplomacyHits,
  );
}
