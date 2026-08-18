import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'orders_application_context.dart';
import 'orders_application_road_propagation.dart';

/// Bundles the six values every completed-work handler needs so each handler is
/// a single-argument `(CompletedWorkContext) -> BuildWorkState` closure instead
/// of repeating the wide positional signature in every function (Refs #3404).
typedef CompletedWorkContext = ({
  BuildWorkState state,
  Unit unit,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces,
  BuildWorkState Function(BuildWorkState, Unit, String) applyExploreCompletion,
});

typedef CompletedWorkHandler =
    BuildWorkState Function(CompletedWorkContext ctx);

BuildWorkState completedWorkBuildImprovement(CompletedWorkContext ctx) {
  final s = ctx.state;
  final u = ctx.unit;
  final cw = ctx.cw;
  final level = s.work.tileState.improvementLevel(cw.tileKey);
  var work = s.work.copyWith(
    tileState: s.work.tileState.setImprovement(
      cw.tileKey,
      (level + 1).clamp(0, 4),
    ),
  );
  var game = s.game;

  final resourceId = game.worldState.resourceAtTile(cw.tileKey);
  final mirrorCat = envyMirrorTechCategoryForExtractionResource(resourceId);
  if (mirrorCat == null) {
    return s.copyWith(work: work);
  }
  final turn = game.worldState.turnState.turnNumber;
  final owner = game.playerById(u.ownerId);
  if (owner != null && owner.isHuman) {
    game = game.copyWith(
      lastHumanCompletedResearchCategory: mirrorCat,
      lastHumanResearchCategoryCompletionTurn: turn,
    );
    return s.copyWith(game: game, work: work);
  }
  if (isAiControlledForEvidence(game, u.ownerId)) {
    final ev = evidenceForEnvyResearchMirror(
      game,
      u.ownerId,
      mirrorCat,
      turn,
      const [],
    );
    if (ev.isNotEmpty) {
      game = game.copyWith(
        dossierEvidenceEntries: [...game.dossierEvidenceEntries, ...ev],
      );
    }
  }
  return s.copyWith(game: game, work: work);
}

BuildWorkState updateProvinceAtUnitLocationForCompletedWork(
  CompletedWorkContext ctx,
  Province Function(Province province) update,
) {
  final s = ctx.state;
  final u = ctx.unit;
  final getProvinces = ctx.getProvinces;
  final replaceProvinces = ctx.replaceProvinces;
  final provinces = getProvinces();
  var replaced = false;
  final next = provinces.map((p) {
    if (!replaced && p.id == u.locationProvinceId) {
      replaced = true;
      return update(p);
    }
    return p;
  }).toList();
  if (!replaced) return s;
  return s.copyWith(work: replaceProvinces(s.work, next));
}

BuildWorkState completedWorkUpgradeTown(CompletedWorkContext ctx) {
  return updateProvinceAtUnitLocationForCompletedWork(
    ctx,
    (p) => p.copyWith(
      townDevelopmentLevel: normalizeTownDevelopmentLevel(
        p.townDevelopmentLevel + 1,
      ),
    ),
  );
}

BuildWorkState completedWorkExplore(CompletedWorkContext ctx) {
  final u = ctx.unit;
  return ctx.applyExploreCompletion(
    ctx.state,
    u,
    ProvinceId.regionIdFrom(u.locationProvinceId),
  );
}

BuildWorkState completedWorkBuildRoad(CompletedWorkContext ctx) {
  final s = ctx.state;
  final u = ctx.unit;
  final cw = ctx.cw;
  final roadLevel = s.work.tileState.roadLevel(cw.tileKey);
  final player = s.game.playerById(u.ownerId);
  final hasRoadConstruction =
      player?.techUnlocked?[kTechIdRoadConstruction] == true;
  final nextLevel = (roadLevel + 1).clamp(0, hasRoadConstruction ? 2 : 1);
  var tileState = s.work.tileState.setRoadLevel(cw.tileKey, nextLevel);

  final tileMap = s.tileMapByRegion;
  if (tileMap != null) {
    tileState = propagateRoadToAdjacentCapitalOrPort(
      tileKey: cw.tileKey,
      nextLevel: nextLevel,
      player: player,
      worldState: s.game.worldState,
      tileMapByRegion: tileMap,
      tileState: tileState,
    );
  }
  return s.copyWith(work: s.work.copyWith(tileState: tileState));
}

BuildWorkState completedWorkBuildPort(CompletedWorkContext ctx) {
  final s = ctx.state;
  final u = ctx.unit;
  final cw = ctx.cw;
  if (s.topology == null) {
    return s;
  }
  final parsedTile = parseTileKeyCoordinates(cw.tileKey);
  final regionIdFromTile =
      parsedTile?.regionId ?? ProvinceId.regionIdFrom(u.locationProvinceId);
  final localId =
      parsedTile?.provinceLocalId ??
      ProvinceId.localIdFrom(u.locationProvinceId);
  final fullProvinceId = ProvinceId.full(regionIdFromTile, localId);
  final seaZoneId = seaZoneIdForProvince(
    s.topology!,
    localId,
    regionId: regionIdFromTile,
  );
  if (seaZoneId == null) return s;
  final ports = Map<String, String>.from(s.work.portsByProvinceSeaboard)
    ..['$fullProvinceId|$seaZoneId'] = cw.tileKey;
  final tileState = s.work.tileState.setRoadLevel(cw.tileKey, 4);
  return s.copyWith(
    work: s.work.copyWith(portsByProvinceSeaboard: ports, tileState: tileState),
  );
}

BuildWorkState completedWorkBuildFort(CompletedWorkContext ctx) {
  final s = ctx.state;
  final u = ctx.unit;
  var next = updateProvinceAtUnitLocationForCompletedWork(
    ctx,
    (p) => p.copyWith(fortLevel: (p.fortLevel + 1).clamp(0, 3)),
  );
  if (s.topology != null && s.onDialogue != null) {
    final seed =
        ((s.game.globalGameSeed ?? 0) ^
                (s.game.worldState.turnState.turnNumber *
                    kDeterministicHashMixPrime32))
            .toInt();
    final events = dialogueEventsForReactiveFortsOnBorder(
      s.game,
      s.topology!,
      u.ownerId,
      u.locationProvinceId,
      seed,
    );
    for (final e in events) {
      s.onDialogue!(e);
    }
  }
  return next;
}

BuildWorkState completedWorkNoop(CompletedWorkContext ctx) => ctx.state;
