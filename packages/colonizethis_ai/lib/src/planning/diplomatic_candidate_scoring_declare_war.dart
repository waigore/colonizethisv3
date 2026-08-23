import 'diplomatic_candidate_scoring_declare_war_bonuses.dart';
import 'diplomatic_candidate_scoring_declare_war_context.dart';
import 'diplomatic_candidate_scoring_declare_war_suppression.dart';
import 'diplomatic_candidate_scoring_declare_war_suppression_adjacent_gp.dart';
import 'diplomatic_candidate_scoring_declare_war_suppression_war_concentration.dart';
import 'planning_imports.dart';

/// Declare-war score ladder.
///
/// Entry point [scoreDeclareWarDiplomaticOrder] accepts a prebuilt
/// [DeclareWarTargetContext], then walks the suppression chain
/// ([_declareWarSuppressedScore]) before bonus addends. Call sites build
/// the context once (Refs #3967). Suppression helpers live in
/// `diplomatic_candidate_scoring_declare_war_suppression.dart` (Refs #4602
/// Slice A). Behaviour is unchanged.
int scoreDeclareWarDiplomaticOrder(
  DeclareWarTargetContext ctx, {
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  final suppressed = _declareWarSuppressedScore(
    ctx,
    sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
  );
  if (suppressed != null) {
    return suppressed;
  }
  return scoreDeclareWarBonuses(ctx);
}

/// Returns a suppressed score when declare-war should not proceed; null = score.
///
/// Chain order is unchanged: DEVELOP → COLONIAL-lite → EXPAND-colonial →
/// stalled-OW → adjacent-GP → war-concentration → relation/cooldown.
int? _declareWarSuppressedScore(
  DeclareWarTargetContext ctx, {
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  return declareWarSuppressedDevelopPhaseScore(ctx) ??
      declareWarSuppressedColonialLiteScore(ctx) ??
      declareWarSuppressedExpandColonialScore(ctx) ??
      declareWarSuppressedStalledOwFrontierScore(ctx) ??
      declareWarSuppressedAdjacentGpScore(
        ctx,
        sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
      ) ??
      declareWarSuppressedWarConcentrationScore(
        ctx,
        sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
      ) ??
      declareWarSuppressedRelationAndCooldownScore(ctx);
}
