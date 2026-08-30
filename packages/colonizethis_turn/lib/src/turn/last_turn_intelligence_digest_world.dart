// World briefing lines for last-turn intelligence.

import 'package:colonizethis_models/colonizethis_models.dart';

List<IntelligenceWorldLine> intelligenceWorldLines({
  required TurnNewsDigest news,
  required Game end,
  required int resolvedTurn,
}) {
  final captures = <IntelligenceWorldLine>[];
  final diplomacy = <IntelligenceWorldLine>[];
  final overtures = <IntelligenceWorldLine>[];
  final discoveries = <IntelligenceWorldLine>[];
  final sea = <IntelligenceWorldLine>[];
  for (final line in news.lines) {
    switch (line) {
      case TurnNewsProvinceCapturedLine(
        :final provinceId,
        :final previousOwnerId,
        :final newOwnerId,
      ):
        captures.add(
          IntelligenceWorldLine(
            kind: IntelligenceWorldKind.provinceCaptured,
            provinceId: provinceId,
            factionIdA: previousOwnerId,
            factionIdB: newOwnerId,
          ),
        );
      case TurnNewsDiplomacyLine(
        :final factionIdA,
        :final factionIdB,
        :final kind,
      ):
        diplomacy.add(
          IntelligenceWorldLine(
            kind: kind == TurnNewsDiplomacyKind.war
                ? IntelligenceWorldKind.war
                : IntelligenceWorldKind.peace,
            factionIdA: factionIdA,
            factionIdB: factionIdB,
          ),
        );
      case TurnNewsOvertureAdvancedLine(
        :final offererGpId,
        :final targetFactionId,
        :final newStage,
      ):
        overtures.add(
          IntelligenceWorldLine(
            kind: IntelligenceWorldKind.overtureAdvanced,
            factionIdA: offererGpId,
            factionIdB: targetFactionId,
            overtureStage: newStage,
          ),
        );
      case TurnNewsProvinceDiscoveredLine(:final provinceId):
        discoveries.add(
          IntelligenceWorldLine(
            kind: IntelligenceWorldKind.provinceDiscovered,
            provinceId: provinceId,
          ),
        );
      case TurnNewsSeaZoneFleetLine(:final seaZoneId):
        sea.add(
          IntelligenceWorldLine(
            kind: IntelligenceWorldKind.seaZoneFleet,
            seaZoneId: seaZoneId,
          ),
        );
    }
  }
  return [
    ...captures,
    ...diplomacy,
    ...intelligenceAllianceWorldLines(end, resolvedTurn),
    ...overtures,
    ...discoveries,
    ...sea,
  ];
}

List<IntelligenceWorldLine> intelligenceAllianceWorldLines(
  Game end,
  int resolvedTurn,
) {
  final seen = <String>{};
  final out = <IntelligenceWorldLine>[];
  for (final e in end.diplomaticHistoryEvents) {
    if (e.turn != resolvedTurn) continue;
    final kind = switch (e.type) {
      DiplomaticEventType.allianceFormed =>
        IntelligenceWorldKind.allianceFormed,
      DiplomaticEventType.allianceBroken =>
        IntelligenceWorldKind.allianceBroken,
      _ => null,
    };
    if (kind == null) continue;
    final a = e.fromFactionId;
    final b = e.toFactionId;
    if (a == null || b == null || a.isEmpty || b.isEmpty) continue;
    final fa = a.compareTo(b) <= 0 ? a : b;
    final fb = a.compareTo(b) <= 0 ? b : a;
    final key = '$kind|$fa|$fb';
    if (!seen.add(key)) continue;
    out.add(IntelligenceWorldLine(kind: kind, factionIdA: fa, factionIdB: fb));
  }
  out.sort((x, y) {
    final ka = '${x.kind.name}|${x.factionIdA}|${x.factionIdB}';
    final kb = '${y.kind.name}|${y.factionIdA}|${y.factionIdB}';
    return ka.compareTo(kb);
  });
  return out;
}
