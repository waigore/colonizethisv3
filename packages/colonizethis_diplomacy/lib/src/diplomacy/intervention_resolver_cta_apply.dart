import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'diplomacy_event_logging.dart';
import 'diplomacy_phase_result.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_shared_helpers.dart';
import 'intervention_resolver_cta_decisions.dart';

export 'intervention_resolver_cta_decisions.dart';
export 'intervention_resolver_cta_subsidy.dart';

Game processCallToArmsForWarPair(
  Game state,
  ({String aggressor, String defender}) pair,
  int turn,
  List<CallToArmsDecision>? callToArmsDecisions,
  List<CallToArmsPending> pending,
  DiplomacyFactionMembership factionMembership,
  Set<String> formalAlliancePairKeysAtPhaseStart, {
  IntraTurnEventTally? eventTally,
}) {
  final aggressorGpId = pair.aggressor;
  final defenderGpId = pair.defender;
  for (final p in state.players) {
    final allyGpId = p.id;
    if (allyGpId == defenderGpId || allyGpId == aggressorGpId) continue;
    if (factionsAtWar(state, allyGpId, aggressorGpId)) continue;
    final rel = getRelation(state, allyGpId, defenderGpId);
    // Mutual defence requires a persisted FORMAL alliance that existed at the
    // end of the preceding turn (snapshot taken at phase start, before this
    // turn's alliance orders resolve). The informal Allied relation band must
    // not trigger Call to Arms on its own. SPEC/game/diplomacy.md § Alliances.
    final hadFormalAlliance = formalAlliancePairKeysAtPhaseStart.contains(
      pairKey(allyGpId, defenderGpId),
    );
    if (rel == null || !rel.atPeace || !hadFormalAlliance) {
      continue;
    }

    // Canonical pending-human-decision flow (diplomacy_shared_helpers.dart):
    // human ally applies a supplied decision or suspends pending; otherwise the
    // AI rule resolves immediately. Call-to-arms intentionally keys the split on
    // the override-aware isAiControlled (negated) rather than isTargetHumanGp,
    // preserving the existing aiControlByGpId-aware behaviour.
    state = resolveHumanGatedDecision<CallToArmsDecision, Game>(
      isHumanControlled: !isAiControlled(state, allyGpId),
      decisions: callToArmsDecisions,
      matches: (d) =>
          d.allyGpId == allyGpId &&
          d.defenderGpId == defenderGpId &&
          d.aggressorGpId == aggressorGpId,
      onAiResolve: () {
        final aggressorOw = provinceCountOwnedBy(state, aggressorGpId);
        final aiTurn = state.worldState.turnState.turnNumber;
        if (isBelowObserverConquestQuota(aggressorOw)) {
          return applyCallToArmsRefuse(
            state,
            allyGpId,
            defenderGpId,
            aiTurn,
            aggressorGpId: aggressorGpId,
            factionMembership: factionMembership,
            eventTally: eventTally,
          );
        }
        if (atWarGreatPowerCount(state, allyGpId, factionMembership) >= 1) {
          return applyCallToArmsRefuse(
            state,
            allyGpId,
            defenderGpId,
            aiTurn,
            aggressorGpId: aggressorGpId,
            factionMembership: factionMembership,
            eventTally: eventTally,
          );
        }
        final accept = rel.score >= callToArmsAiAcceptMinRelationScore;
        if (accept) {
          return applyCallToArmsAccept(
            state,
            allyGpId,
            aggressorGpId,
            aiTurn,
            eventTally: eventTally,
          );
        }
        return applyCallToArmsRefuse(
          state,
          allyGpId,
          defenderGpId,
          aiTurn,
          aggressorGpId: aggressorGpId,
          factionMembership: factionMembership,
          eventTally: eventTally,
        );
      },
      onPending: () {
        pending.add(
          CallToArmsPending(
            allyGpId: allyGpId,
            defenderGpId: defenderGpId,
            aggressorGpId: aggressorGpId,
          ),
        );
        return state;
      },
      onHumanDecision: (decision) {
        if (decision.accepted) {
          return applyCallToArmsAccept(
            state,
            allyGpId,
            aggressorGpId,
            turn,
            eventTally: eventTally,
          );
        }
        return applyCallToArmsRefuse(
          state,
          allyGpId,
          defenderGpId,
          turn,
          aggressorGpId: aggressorGpId,
          factionMembership: factionMembership,
          eventTally: eventTally,
        );
      },
    );
  }
  return state;
}
