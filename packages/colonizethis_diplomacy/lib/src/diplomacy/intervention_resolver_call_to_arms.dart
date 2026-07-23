import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'diplomacy_event_logging.dart';
import 'diplomacy_phase_result.dart';
import 'diplomacy_shared_helpers.dart';
import 'intervention_resolver_cta_apply.dart';
import 'intervention_resolver_cta_war_pairs.dart';

export 'intervention_resolver_cta_apply.dart'
    show
        applyCallToArmsAccept,
        applyCallToArmsRefuse,
        cancelSubsidiesBetweenGps,
        processCallToArmsForWarPair;
export 'intervention_resolver_cta_war_pairs.dart'
    show gpGpWarPairsFromDeclareWarOrders;

class CallToArmsResult {
  CallToArmsResult(this.game, {this.pendingCallToArms});
  final Game game;
  final List<CallToArmsPending>? pendingCallToArms;
}

CallToArmsResult processCallToArms(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  int turn, {
  required DiplomacyFactionMembership factionMembership,
  required Set<String> formalAlliancePairKeysAtPhaseStart,
  List<CallToArmsDecision>? callToArmsDecisions,
  IntraTurnEventTally? eventTally,
}) {
  var state = game;
  final warPairs = gpGpWarPairsFromDeclareWarOrders(
    state,
    diploByPlayer,
    factionMembership,
  );
  final pending = <CallToArmsPending>[];

  for (final pair in warPairs) {
    state = processCallToArmsForWarPair(
      state,
      pair,
      turn,
      callToArmsDecisions,
      pending,
      factionMembership,
      formalAlliancePairKeysAtPhaseStart,
      eventTally: eventTally,
    );
  }

  pending.sort((a, b) {
    final c1 = a.allyGpId.compareTo(b.allyGpId);
    if (c1 != 0) return c1;
    final c2 = a.defenderGpId.compareTo(b.defenderGpId);
    if (c2 != 0) return c2;
    return a.aggressorGpId.compareTo(b.aggressorGpId);
  });

  if (pending.isNotEmpty) {
    return CallToArmsResult(state, pendingCallToArms: pending);
  }
  return CallToArmsResult(state);
}
