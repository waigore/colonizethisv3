import 'dart:convert';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';

import 'observer_extractable_rollup.dart';

/// Observer canonical snapshot (SPEC/program/run_observer_game-tool.md).
///
/// **v3 (Refs #2692 S10a):** Adds `workerPool` per player rollup
/// (`peasants`, `apprentices`, `journeymen`, `masters`) so workforce
/// growth and 15-regiment sustain can be verified from snapshots at
/// turn 100 without rerunning the campaign.
const int observerSnapshotSchemaVersion = 3;

Map<String, Object?> buildObserverSnapshotJson(
  Game game, {
  required int postResolutionTurnNumber,
  Map<String, TileMapResult>? tileMapByRegion,
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
