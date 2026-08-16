// Last-turn intelligence digest. SPEC/program/intelligence-digest.md.

import 'diplomacy.dart';
import 'model_collection_equality.dart';

enum IntelligenceWorldKind {
  provinceCaptured,
  war,
  peace,
  allianceFormed,
  allianceBroken,
  overtureAdvanced,
  provinceDiscovered,
  seaZoneFleet,
}

enum IntelligenceSpyKind {
  diplomatic,
  captureMade,
  captureLost,
  researchComplete,
  combat,
  navalCombat,
}

class IntelligenceWorldLine {
  const IntelligenceWorldLine({
    required this.kind,
    this.factionIdA,
    this.factionIdB,
    this.provinceId,
    this.seaZoneId,
    this.overtureStage,
  });

  final IntelligenceWorldKind kind;
  final String? factionIdA;
  final String? factionIdB;
  final String? provinceId;
  final String? seaZoneId;
  final OvertureStage? overtureStage;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    if (factionIdA != null) 'factionIdA': factionIdA,
    if (factionIdB != null) 'factionIdB': factionIdB,
    if (provinceId != null) 'provinceId': provinceId,
    if (seaZoneId != null) 'seaZoneId': seaZoneId,
    if (overtureStage != null) 'overtureStage': overtureStage!.name,
  };

  static IntelligenceWorldLine fromJson(Map<String, dynamic> json) {
    return IntelligenceWorldLine(
      kind: IntelligenceWorldKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => IntelligenceWorldKind.war,
      ),
      factionIdA: json['factionIdA'] as String?,
      factionIdB: json['factionIdB'] as String?,
      provinceId: json['provinceId'] as String?,
      seaZoneId: json['seaZoneId'] as String?,
      overtureStage: json['overtureStage'] != null
          ? OvertureStage.values.firstWhere(
              (e) => e.name == json['overtureStage'],
              orElse: () => OvertureStage.none,
            )
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntelligenceWorldLine &&
          kind == other.kind &&
          factionIdA == other.factionIdA &&
          factionIdB == other.factionIdB &&
          provinceId == other.provinceId &&
          seaZoneId == other.seaZoneId &&
          overtureStage == other.overtureStage;

  @override
  int get hashCode => Object.hash(
    kind,
    factionIdA,
    factionIdB,
    provinceId,
    seaZoneId,
    overtureStage,
  );
}

class IntelligenceSpyLine {
  const IntelligenceSpyLine({
    required this.kind,
    this.diplomaticType,
    this.fromFactionId,
    this.toFactionId,
    this.provinceId,
    this.seaZoneId,
    this.techId,
    this.winnerId,
    this.overtureStage,
    this.amount,
  });

  final IntelligenceSpyKind kind;
  final DiplomaticEventType? diplomaticType;
  final String? fromFactionId;
  final String? toFactionId;
  final String? provinceId;
  final String? seaZoneId;
  final String? techId;
  final String? winnerId;
  final OvertureStage? overtureStage;
  final int? amount;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    if (diplomaticType != null) 'diplomaticType': diplomaticType!.name,
    if (fromFactionId != null) 'fromFactionId': fromFactionId,
    if (toFactionId != null) 'toFactionId': toFactionId,
    if (provinceId != null) 'provinceId': provinceId,
    if (seaZoneId != null) 'seaZoneId': seaZoneId,
    if (techId != null) 'techId': techId,
    if (winnerId != null) 'winnerId': winnerId,
    if (overtureStage != null) 'overtureStage': overtureStage!.name,
    if (amount != null) 'amount': amount,
  };

  static IntelligenceSpyLine fromJson(Map<String, dynamic> json) {
    return IntelligenceSpyLine(
      kind: IntelligenceSpyKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => IntelligenceSpyKind.diplomatic,
      ),
      diplomaticType: json['diplomaticType'] != null
          ? DiplomaticEventType.values.firstWhere(
              (e) => e.name == json['diplomaticType'],
              orElse: () => DiplomaticEventType.declareWar,
            )
          : null,
      fromFactionId: json['fromFactionId'] as String?,
      toFactionId: json['toFactionId'] as String?,
      provinceId: json['provinceId'] as String?,
      seaZoneId: json['seaZoneId'] as String?,
      techId: json['techId'] as String?,
      winnerId: json['winnerId'] as String?,
      overtureStage: json['overtureStage'] != null
          ? OvertureStage.values.firstWhere(
              (e) => e.name == json['overtureStage'],
              orElse: () => OvertureStage.none,
            )
          : null,
      amount: (json['amount'] as num?)?.toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntelligenceSpyLine &&
          kind == other.kind &&
          diplomaticType == other.diplomaticType &&
          fromFactionId == other.fromFactionId &&
          toFactionId == other.toFactionId &&
          provinceId == other.provinceId &&
          seaZoneId == other.seaZoneId &&
          techId == other.techId &&
          winnerId == other.winnerId &&
          overtureStage == other.overtureStage &&
          amount == other.amount;

  @override
  int get hashCode => Object.hash(
    kind,
    diplomaticType,
    fromFactionId,
    toFactionId,
    provinceId,
    seaZoneId,
    techId,
    winnerId,
    overtureStage,
    amount,
  );
}

class IntelligenceSpyCourtBlock {
  const IntelligenceSpyCourtBlock({
    required this.courtFactionId,
    required this.lines,
  });

  final String courtFactionId;
  final List<IntelligenceSpyLine> lines;

  Map<String, dynamic> toJson() => {
    'courtFactionId': courtFactionId,
    'lines': lines.map((e) => e.toJson()).toList(),
  };

  static IntelligenceSpyCourtBlock fromJson(Map<String, dynamic> json) {
    final raw = json['lines'] as List<dynamic>? ?? [];
    return IntelligenceSpyCourtBlock(
      courtFactionId: json['courtFactionId'] as String,
      lines: raw
          .map(
            (e) => IntelligenceSpyLine.fromJson(
              Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
            ),
          )
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntelligenceSpyCourtBlock &&
          courtFactionId == other.courtFactionId &&
          modelListEquals(lines, other.lines);

  @override
  int get hashCode => Object.hash(courtFactionId, Object.hashAll(lines));
}

/// Persisted last-turn briefing. Replaced each completed turn.
class LastTurnIntelligenceDigest {
  const LastTurnIntelligenceDigest({
    required this.resolvedTurnNumber,
    this.worldLines = const [],
    this.spyReportsByObserverId = const {},
  });

  final int resolvedTurnNumber;
  final List<IntelligenceWorldLine> worldLines;
  final Map<String, List<IntelligenceSpyCourtBlock>> spyReportsByObserverId;

  List<IntelligenceSpyCourtBlock> spyReportsFor(String observerId) =>
      spyReportsByObserverId[observerId] ?? const [];

  int spyLineCountFor(String observerId) {
    var n = 0;
    for (final block in spyReportsFor(observerId)) {
      n += block.lines.length;
    }
    return n;
  }

  int lineCountForObserver(String observerId) =>
      worldLines.length + spyLineCountFor(observerId);

  Map<String, dynamic> toJson() {
    final spyJson = <String, dynamic>{};
    final observerIds = spyReportsByObserverId.keys.toList()..sort();
    for (final id in observerIds) {
      spyJson[id] = spyReportsByObserverId[id]!.map((e) => e.toJson()).toList();
    }
    return {
      'resolvedTurnNumber': resolvedTurnNumber,
      'worldLines': worldLines.map((e) => e.toJson()).toList(),
      'spyReportsByObserverId': spyJson,
    };
  }

  static LastTurnIntelligenceDigest fromJson(Map<String, dynamic> json) {
    final worldRaw = json['worldLines'] as List<dynamic>? ?? [];
    final spyRaw =
        json['spyReportsByObserverId'] as Map<dynamic, dynamic>? ?? {};
    final spy = <String, List<IntelligenceSpyCourtBlock>>{};
    for (final entry in spyRaw.entries) {
      final list = entry.value as List<dynamic>? ?? [];
      spy[entry.key.toString()] = list
          .map(
            (e) => IntelligenceSpyCourtBlock.fromJson(
              Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
            ),
          )
          .toList();
    }
    return LastTurnIntelligenceDigest(
      resolvedTurnNumber: (json['resolvedTurnNumber'] as num).toInt(),
      worldLines: worldRaw
          .map(
            (e) => IntelligenceWorldLine.fromJson(
              Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
            ),
          )
          .toList(),
      spyReportsByObserverId: spy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LastTurnIntelligenceDigest &&
          resolvedTurnNumber == other.resolvedTurnNumber &&
          modelListEquals(worldLines, other.worldLines) &&
          modelMapOfListEquals(
            spyReportsByObserverId,
            other.spyReportsByObserverId,
          );

  @override
  int get hashCode => Object.hash(
    resolvedTurnNumber,
    Object.hashAll(worldLines),
    Object.hashAll(spyReportsByObserverId.entries),
  );
}
