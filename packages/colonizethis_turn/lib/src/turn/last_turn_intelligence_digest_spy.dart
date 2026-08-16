// Spy-gated court reports for last-turn intelligence.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

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
  lines.addAll(_diplomaticSpyLines(end, courtId, resolvedTurn));
  lines.addAll(_captureSpyLines(worldNews, courtId));
  lines.addAll(_combatSpyLines(turnEvents, courtId));
  lines.addAll(_researchSpyLines(start, end, courtId, turnEvents));
  return lines;
}

List<IntelligenceSpyLine> _diplomaticSpyLines(
  Game end,
  String courtId,
  int resolvedTurn,
) {
  final matching =
      end.diplomaticHistoryEvents
          .where(
            (e) =>
                e.turn == resolvedTurn &&
                (e.participants.contains(courtId) ||
                    e.fromFactionId == courtId ||
                    e.toFactionId == courtId),
          )
          .toList()
        ..sort((a, b) => a.intraTurnIndex.compareTo(b.intraTurnIndex));
  return [
    for (final e in matching)
      IntelligenceSpyLine(
        kind: IntelligenceSpyKind.diplomatic,
        diplomaticType: e.type,
        fromFactionId: e.fromFactionId,
        toFactionId: e.toFactionId,
        overtureStage: e.overtureStage,
        amount: e.amount,
      ),
  ];
}

List<IntelligenceSpyLine> _captureSpyLines(
  TurnNewsDigest worldNews,
  String courtId,
) {
  final lines = <IntelligenceSpyLine>[];
  for (final line in worldNews.lines) {
    if (line is! TurnNewsProvinceCapturedLine) continue;
    if (line.newOwnerId == courtId) {
      lines.add(
        IntelligenceSpyLine(
          kind: IntelligenceSpyKind.captureMade,
          provinceId: line.provinceId,
          fromFactionId: line.previousOwnerId,
          toFactionId: line.newOwnerId,
        ),
      );
    } else if (line.previousOwnerId == courtId) {
      lines.add(
        IntelligenceSpyLine(
          kind: IntelligenceSpyKind.captureLost,
          provinceId: line.provinceId,
          fromFactionId: line.previousOwnerId,
          toFactionId: line.newOwnerId,
        ),
      );
    }
  }
  lines.sort((a, b) => (a.provinceId ?? '').compareTo(b.provinceId ?? ''));
  return lines;
}

List<IntelligenceSpyLine> _combatSpyLines(
  List<GameEvent> turnEvents,
  String courtId,
) {
  final lines = <IntelligenceSpyLine>[];
  for (final event in turnEvents) {
    switch (event) {
      case CombatResultEvent(
        :final provinceId,
        :final attackerId,
        :final defenderId,
        :final winnerId,
      ):
        if (attackerId != courtId && defenderId != courtId) continue;
        lines.add(
          IntelligenceSpyLine(
            kind: IntelligenceSpyKind.combat,
            provinceId: provinceId,
            fromFactionId: attackerId,
            toFactionId: defenderId,
            winnerId: winnerId,
          ),
        );
      case NavalCombatResultEvent(
        :final seaZoneId,
        :final side1OwnerId,
        :final side2OwnerId,
        :final winnerOwnerId,
      ):
        if (side1OwnerId != courtId && side2OwnerId != courtId) continue;
        lines.add(
          IntelligenceSpyLine(
            kind: IntelligenceSpyKind.navalCombat,
            seaZoneId: seaZoneId,
            fromFactionId: side1OwnerId,
            toFactionId: side2OwnerId,
            winnerId: winnerOwnerId,
          ),
        );
      default:
        break;
    }
  }
  return lines;
}

List<IntelligenceSpyLine> _researchSpyLines(
  Game start,
  Game end,
  String courtId,
  List<GameEvent> turnEvents,
) {
  final unlocked = <String>{};
  for (final event in turnEvents) {
    if (event is ResearchCompleteEvent && event.playerId == courtId) {
      unlocked.add(event.techId);
    }
  }
  final startTechs = start.playerById(courtId)?.techUnlocked ?? const {};
  final endTechs = end.playerById(courtId)?.techUnlocked ?? const {};
  for (final entry in endTechs.entries) {
    if (entry.value != true) continue;
    if (startTechs[entry.key] == true) continue;
    unlocked.add(entry.key);
  }
  final ids = unlocked.toList()..sort();
  return [
    for (final techId in ids)
      IntelligenceSpyLine(
        kind: IntelligenceSpyKind.researchComplete,
        techId: techId,
        fromFactionId: courtId,
      ),
  ];
}
