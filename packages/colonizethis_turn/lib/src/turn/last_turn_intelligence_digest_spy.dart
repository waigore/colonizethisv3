// Spy-gated court reports for last-turn intelligence.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'last_turn_intelligence_digest_spy_lines.dart';

Map<String, List<IntelligenceSpyCourtBlock>> intelligenceSpyReportsByObserver({
  required Game start,
  required Game end,
  required int resolvedTurn,
  required List<GameEvent> turnEvents,
  required TurnNewsDigest worldNews,
}) {
  final out = <String, List<IntelligenceSpyCourtBlock>>{};
  for (final observer in end.players) {
    final courts = _courtsHostingSpy(end, observer.id);
    if (courts.isEmpty) continue;
    final blocks = <IntelligenceSpyCourtBlock>[];
    for (final courtId in courts) {
      final lines = _spyLinesForCourt(
        start: start,
        end: end,
        courtId: courtId,
        resolvedTurn: resolvedTurn,
        turnEvents: turnEvents,
        worldNews: worldNews,
      );
      if (lines.isEmpty) continue;
      blocks.add(
        IntelligenceSpyCourtBlock(courtFactionId: courtId, lines: lines),
      );
    }
    if (blocks.isNotEmpty) out[observer.id] = blocks;
  }
  return out;
}

List<String> _courtsHostingSpy(Game game, String observerId) {
  final ownerByProvince = ownerByProvinceIdMap(game.worldState);
  final courts = <String>{};
  for (final u in game.worldState.allUnitsById.values) {
    if (u.ownerId != observerId) continue;
    if (!isSpyUnit(u.type)) continue;
    final territoryOwner = ownerByProvince[u.locationProvinceId];
    if (territoryOwner == null || territoryOwner.isEmpty) continue;
    if (territoryOwner == observerId) continue;
    courts.add(territoryOwner);
  }
  final sorted = courts.toList()..sort();
  return sorted;
}

List<IntelligenceSpyLine> _spyLinesForCourt({
  required Game start,
  required Game end,
  required String courtId,
  required int resolvedTurn,
  required List<GameEvent> turnEvents,
  required TurnNewsDigest worldNews,
}) {
  final lines = <IntelligenceSpyLine>[];
  lines.addAll(diplomaticSpyLines(end, courtId, resolvedTurn));
  lines.addAll(captureSpyLines(worldNews, courtId));
  lines.addAll(combatSpyLines(turnEvents, courtId));
  lines.addAll(researchSpyLines(start, end, courtId, turnEvents));
  return lines;
}
