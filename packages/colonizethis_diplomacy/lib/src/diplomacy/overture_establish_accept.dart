import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_phase_result.dart';
import 'diplomacy_relation_constants.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_shared_helpers.dart';
import 'overture_establish_types.dart';

/// Accept by rule for Minor/Tribe: Consulate/Embassy/NAP always accepted.
/// SPEC/game/diplomacy.md.
bool minorOrTribeAcceptsByRule(OvertureStage stage) {
  return stage == OvertureStage.tradeConsulate ||
      stage == OvertureStage.embassy ||
      stage == OvertureStage.nap;
}

/// AI GP target: accept if relation score >= neutral (Neutral or better).
/// Current product rule.
bool aiGpAcceptsOverture(Game game, String offererGpId, String targetGpId) {
  final rel = getRelation(game, offererGpId, targetGpId);
  final score = rel?.score ?? relationScoreNeutral;
  return score >= relationScoreNeutral;
}

/// Returns pending result when human GP must respond; otherwise acceptance flag.
({bool accepted, OverturePaymentsResult? pending}) resolveOvertureAcceptance({
  required Game state,
  required String gpId,
  required String targetId,
  required OvertureStage stage,
  required bool targetIsMinorOrTribe,
  required List<Player> players,
  required List<OvertureState> overtures,
  List<OvertureDecision>? overtureDecisions,
}) {
  if (targetIsMinorOrTribe) {
    return (accepted: minorOrTribeAcceptsByRule(stage), pending: null);
  }
  // Canonical pending-human-decision flow (diplomacy_shared_helpers.dart):
  // human target applies a supplied decision or suspends pending; otherwise the
  // AI rule resolves immediately.
  return resolveHumanGatedDecision<
    OvertureDecision,
    ({bool accepted, OverturePaymentsResult? pending})
  >(
    isHumanControlled: isTargetHumanGp(state, targetId),
    decisions: overtureDecisions,
    matches: (d) =>
        d.offererGpId == gpId &&
        d.targetFactionId == targetId &&
        d.stage == stage,
    onAiResolve: () =>
        (accepted: aiGpAcceptsOverture(state, gpId, targetId), pending: null),
    onPending: () {
      final pending = [
        OvertureOffer(
          offererGpId: gpId,
          targetFactionId: targetId,
          stage: stage,
        ),
      ];
      final wrapped = state.copyWith(
        players: players,
        overtureStates: overtures,
      );
      return (
        accepted: false,
        pending: OverturePaymentsResult(wrapped, pending),
      );
    },
    onHumanDecision: (decision) => (accepted: decision.accepted, pending: null),
  );
}
