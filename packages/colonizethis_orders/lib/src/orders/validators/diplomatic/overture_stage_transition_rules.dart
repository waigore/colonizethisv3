import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';

/// Declarative overture stage transition metadata for establish-overture
/// validation (Refs #3877).
final class OvertureStageTransitionRule {
  const OvertureStageTransitionRule({
    required this.requiredCurrentStage,
    required this.stageMismatchReason,
    this.treasuryCost,
    this.insufficientTreasuryReason,
    this.requiresDiplomaticExpertiseForMinorTribe = true,
  });

  final OvertureStage requiredCurrentStage;
  final String stageMismatchReason;
  final int? treasuryCost;
  final String? insufficientTreasuryReason;
  final bool requiresDiplomaticExpertiseForMinorTribe;
}

/// Ordered establish-overture stages validated through the shared transition
/// table in [establishOvertureSubValidator].
const Map<OvertureStage, OvertureStageTransitionRule>
kOvertureStageTransitionRules = <OvertureStage, OvertureStageTransitionRule>{
  OvertureStage.tradeConsulate: OvertureStageTransitionRule(
    requiredCurrentStage: OvertureStage.none,
    stageMismatchReason: 'Trade Consulate requires no existing overture',
    treasuryCost: overtureConsulateCost,
    insufficientTreasuryReason:
        'Insufficient treasury for Trade Consulate (need $overtureConsulateCost)',
  ),
  OvertureStage.embassy: OvertureStageTransitionRule(
    requiredCurrentStage: OvertureStage.tradeConsulate,
    stageMismatchReason:
        'Embassy requires existing Trade Consulate with that faction',
    treasuryCost: overtureEmbassyCost,
    insufficientTreasuryReason:
        'Insufficient treasury for Embassy (need $overtureEmbassyCost)',
  ),
  OvertureStage.nap: OvertureStageTransitionRule(
    requiredCurrentStage: OvertureStage.embassy,
    stageMismatchReason:
        'Non-Aggression Pact requires existing Embassy with that faction',
    requiresDiplomaticExpertiseForMinorTribe: true,
  ),
};
