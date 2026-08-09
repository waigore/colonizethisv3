/// Diplomatic order models. SPEC/program/diplomacy-resolution.
///
/// Concern split from former monolithic `diplomacy.dart` (Refs #4068).

import 'overtures.dart';

/// Diplomatic order types. SPEC/program/diplomacy-resolution.
enum DiplomaticOrderType {
  declareWar,
  offerPeace,
  alliance,

  /// Voluntarily break an existing formal alliance with a Great Power. Applies
  /// the unified alliance-break penalty. SPEC/game/diplomacy.md § Alliances.
  breakAlliance,
  establishOverture,
  establishFtp,
  grantAid,
  setSubsidy,

  /// Boycott another Great Power on behalf of the issuer's colonies: blocks all
  /// trade between the target GP and every Tribe that is a colony of the issuer
  /// (Refs #3753 R6). SPEC/game/diplomacy.md § GP–Tribe Rules (Boycott).
  boycott,

  /// Remove an active boycott the issuer holds against a Great Power
  /// (Refs #3753 R6). SPEC/game/diplomacy.md § GP–Tribe Rules (Boycott).
  revokeBoycott,
}

/// Base for diplomatic orders.
class DiplomaticOrder {
  const DiplomaticOrder({
    required this.type,
    required this.targetFactionId,
    this.amount,
    this.overtureStage,
  });

  final DiplomaticOrderType type;
  final String targetFactionId;
  final int? amount;
  final OvertureStage? overtureStage;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'targetFactionId': targetFactionId,
    if (amount != null) 'amount': amount,
    if (overtureStage != null) 'overtureStage': overtureStage!.name,
  };

  static DiplomaticOrder fromJson(Map<String, dynamic> json) => DiplomaticOrder(
    type: DiplomaticOrderType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => DiplomaticOrderType.declareWar,
    ),
    targetFactionId: json['targetFactionId'] as String,
    amount: json['amount'] as int?,
    overtureStage: json['overtureStage'] != null
        ? OvertureStage.values.firstWhere(
            (e) => e.name == json['overtureStage'],
            orElse: () => OvertureStage.none,
          )
        : null,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiplomaticOrder &&
          type == other.type &&
          targetFactionId == other.targetFactionId &&
          amount == other.amount &&
          overtureStage == other.overtureStage;

  @override
  int get hashCode => Object.hash(type, targetFactionId, amount, overtureStage);
}

/// Intervention choice when Minor with Embassy is attacked. SPEC/game/diplomacy.md.
enum InterventionChoice { intervene, doNothing, protest }
