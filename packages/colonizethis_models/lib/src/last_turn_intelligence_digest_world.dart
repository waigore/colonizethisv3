// World briefing lines for last-turn intelligence.
// Extracted so last_turn_intelligence_digest.dart stays under the models
// physical-line cap (Refs #4136). SPEC/program/intelligence-digest.md.

import 'diplomacy.dart';

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
