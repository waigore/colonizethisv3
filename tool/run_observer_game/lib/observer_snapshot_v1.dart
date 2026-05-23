import 'dart:convert';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';

import 'observer_extractable_rollup.dart';

/// Observer canonical snapshot (SPEC/program/run_observer_game-tool.md).
///
/// **v4 (Refs #2692 S10b):** Adds `luxuryStockpile` and
/// `lastTurnLuxuryProduction` per player rollup
/// (`refinedSugar`, `cigars`, `furHats`) so the workforce sustain
/// verifier can enforce Requirement §21 bullet 4 (`stockpile + production
/// >= trained-tier count`) for each luxury commodity at turn 100.
/// Older readers may continue treating absent fields as zero; the
/// schema version bump signals the new rollup is available.
///
/// **v3 (Refs #2692 S10a):** Adds `workerPool` per player rollup
/// (`peasants`, `apprentices`, `journeymen`, `masters`) so workforce
/// growth and 15-regiment sustain can be verified from snapshots at
/// turn 100 without rerunning the campaign.
const int observerSnapshotSchemaVersion = 4;

/// Luxury commodity ids whose production and stockpile are surfaced
/// in the v4 player rollup for workforce sustain verification.
/// Ordering matches `SPEC/game/workers-and-population.md` § Tech gates
/// (apprentice → journeyman → master).
const List<String> kObserverSnapshotLuxuryCommodityIds = <String>[
  'refinedSugar',
  'cigars',
  'furHats',
];

Map<String, Object?> buildObserverSnapshotJson(
  Game game, {
  required int postResolutionTurnNumber,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, Map<String, int>>? lastTurnProductionByRecipeByPlayerId,
}) {
  final mapping = game.turnTimeMapping ?? TurnTimeMapping.gdd01;

  final provinceRows = [
    ...allProvinces(
      game.worldState,
    ).map((p) => <String, String?>{'id': p.id, 'ownerId': p.ownerId}),
  ]..sort((a, b) => (a['id'] ?? '').compareTo(b['id'] ?? ''));

  final playerRollups = <Object?>[];
  for (final p in game.players) {
    final techKeys =
        (p.techUnlocked?.keys.map((k) => k.toString()).toList() ?? <String>[])
          ..sort();
    final pool = p.workerPool;
    final luxuryStockpile = <String, Object?>{
      for (final id in kObserverSnapshotLuxuryCommodityIds)
        id: p.stockpile.quantityOf(id),
    };
    final productionByRecipe =
        lastTurnProductionByRecipeByPlayerId?[p.id] ?? const <String, int>{};
    final lastTurnLuxuryProduction = <String, Object?>{
      for (final id in kObserverSnapshotLuxuryCommodityIds) id: 0,
    };
    for (final entry in productionByRecipe.entries) {
      final recipe = ProductionRecipesCatalog.byId[entry.key];
      if (recipe == null) continue;
      final outputCommodityId = recipe.outputCommodityId;
      if (!kObserverSnapshotLuxuryCommodityIds.contains(outputCommodityId)) {
        continue;
      }
      final outputQty = entry.value * recipe.outputQuantity;
      final current = lastTurnLuxuryProduction[outputCommodityId] as int;
      lastTurnLuxuryProduction[outputCommodityId] = current + outputQty;
    }
    playerRollups.add(<String, Object?>{
      'playerId': p.id,
      'displayName': p.displayName,
      'isHuman': p.isHuman,
      'greatPowerPowerScore': greatPowerPowerScore(game, p.id),
      'treasuryPounds': p.treasury,
      'regimentLikeUnitCountHint': aggregateMilitaryStrengthForPlayer(
        game,
        p.id,
      ).round(),
      'fleetShipCountHint': shipCountForFaction(game, p.id),
      'techUnlockedIds': techKeys,
      'workerPool': <String, Object?>{
        'peasants': pool.peasants,
        'apprentices': pool.apprentices,
        'journeymen': pool.journeymen,
        'masters': pool.masters,
      },
      'luxuryStockpile': luxuryStockpile,
      'lastTurnLuxuryProduction': lastTurnLuxuryProduction,
    });
  }

  final diplomacyBrief = [
    ...game.diplomacyRelations.map((r) {
      return '${r.factionId1}<->${r.factionId2}: score=${r.score} lvl=${r.level.name} '
          '${r.atWar ? "war" : "peace"}';
    }),
  ]..sort();

  final armiesBrief = [
    ...game.worldState.armies.map(
      (a) =>
          'army:${a.id} owner=${a.ownerId} region=${a.regionId} regiments=${a.regimentUnitIds.length}',
    ),
  ]..sort();

  final fleetsBrief = [
    ...game.worldState.fleets.map(
      (f) => 'fleet:${f.id} owner=${f.ownerId} ships=${f.shipTypeIds.length}',
    ),
  ]..sort();

  final extractableRollup = computeExtractableImprovementRollup(
    game,
    tileMapByRegion: tileMapByRegion,
  );

  return <String, Object?>{
    'observerSnapshotSchemaVersion': observerSnapshotSchemaVersion,
    'gameId': game.id,
    'turnNumber': postResolutionTurnNumber,
    'calendarYearAtTurnStart': mapping.yearAtTurn(
      postResolutionTurnNumber < 1 ? 1 : postResolutionTurnNumber,
    ),
    'calendarCampaignHalted': game.calendarCampaignHalted,
    'players': playerRollups,
    'provinceOwnershipSorted': provinceRows,
    'diplomacyRelationSummariesSorted': diplomacyBrief,
    'militaryArmySummariesSorted': armiesBrief,
    'militaryFleetSummariesSorted': fleetsBrief,
    'extractableResourceTileCount':
        extractableRollup.extractableResourceTileCount,
    'improvedExtractableResourceTileCount':
        extractableRollup.improvedExtractableResourceTileCount,
  };
}

String encodeObserverSnapshotJson(Map<String, Object?> snapshot) {
  return '${const JsonEncoder.withIndent('  ').convert(snapshot)}\n';
}

String renderObserverSnapshotHtml(String snapshotJsonPretty) =>
    '''<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8"><title>Observer snapshot</title></head>
<body>
<pre>${const HtmlEscape().convert(snapshotJsonPretty.trimRight())}</pre>
</body>
</html>
''';
