part of 'diplomatic_candidate_scoring.dart';

/// Shared diplomatic order-scoring inputs (Refs #3822 Phase 3).
typedef WarDesireForTarget = int Function(
  String targetFactionId,
  num relationScore,
);

/// Common projection for establish-overture, offer-peace, and declare-war
/// scoring families.
final class DiplomaticScoringContext {
  const DiplomaticScoringContext({
    required this.order,
    required this.nationId,
    required this.game,
    required this.snapshot,
    required this.provinceOwner,
    required this.currentTurn,
    required this.sameTurnPriorDiplomaticOrders,
    required this.warDesireForTarget,
  });

  final DiplomaticOrder order;
  final String nationId;
  final Game game;
  final AIWorldSnapshot snapshot;
  final Map<String, String> provinceOwner;
  final int currentTurn;
  final Orders? sameTurnPriorDiplomaticOrders;
  final WarDesireForTarget warDesireForTarget;
}

/// Establish-overture scoring inputs beyond [DiplomaticScoringContext].
final class EstablishOvertureScoringParams {
  const EstablishOvertureScoringParams({
    required this.thresholds,
    required this.improveRelationsCooldownTurns,
  });

  final PersonalityThresholds thresholds;
  final int improveRelationsCooldownTurns;
}

/// Offer-peace scoring inputs beyond [DiplomaticScoringContext].
final class OfferPeaceScoringParams {
  const OfferPeaceScoringParams({
    required this.agendaId,
    required this.thresholds,
    required this.invadableOwners,
  });

  final String agendaId;
  final PersonalityThresholds thresholds;
  final Set<String> invadableOwners;
}
