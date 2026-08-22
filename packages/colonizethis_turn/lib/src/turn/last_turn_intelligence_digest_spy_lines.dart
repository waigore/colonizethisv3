import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

List<IntelligenceSpyLine> diplomaticSpyLines(
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

List<IntelligenceSpyLine> captureSpyLines(
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

List<IntelligenceSpyLine> combatSpyLines(
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

List<IntelligenceSpyLine> researchSpyLines(
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
