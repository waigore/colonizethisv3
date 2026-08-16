// Spy-court lines for last-turn intelligence.
// Extracted so last_turn_intelligence_digest.dart stays under the models
// physical-line cap (Refs #4136). SPEC/program/intelligence-digest.md.

import 'diplomacy.dart';
import 'model_collection_equality.dart';

enum IntelligenceSpyKind {
  diplomatic,
  captureMade,
  captureLost,
  researchComplete,
  combat,
  navalCombat,
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
