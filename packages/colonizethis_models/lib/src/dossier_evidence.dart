// Evidence entries for dossier. SPEC/ai/ai-dossier.md, SPEC/program/ai-events-and-dossier.md.
// Stored in game state; never exposes true hidden agenda.

/// One evidence entry: observable action that may indicate an agenda.
class DossierEvidenceEntry {
  const DossierEvidenceEntry({
    required this.observerId,
    required this.subjectId,
    required this.agendaType,
    required this.turnNumber,
    required this.description,
    this.scoreDelta = 1,
  });

  final String observerId;
  final String subjectId;
  final String agendaType;
  final int turnNumber;
  final String description;
  final int scoreDelta;

  Map<String, dynamic> toJson() => {
        'observerId': observerId,
        'subjectId': subjectId,
        'agendaType': agendaType,
        'turnNumber': turnNumber,
        'description': description,
        'scoreDelta': scoreDelta,
      };

  static DossierEvidenceEntry fromJson(Map<String, dynamic> json) {
    return DossierEvidenceEntry(
      observerId: json['observerId'] as String,
      subjectId: json['subjectId'] as String,
      agendaType: json['agendaType'] as String,
      turnNumber: json['turnNumber'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      scoreDelta: (json['scoreDelta'] as num?)?.toInt() ?? 1,
    );
  }
}
