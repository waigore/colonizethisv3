/// Diplomacy phase resolution. SPEC/program/diplomacy-resolution.md.
/// Steps: overture payments (two-way accept/reject), advance overtures,
/// Join Empire/Colony, alliance proposals, Declare War/Peace, intervention
/// (GP embassy or purchased land when a GP declares war on a Minor/Tribe),
/// relation modifiers, score update.
library;

import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../turn/turn_resolution_result.dart';
import 'package:colonizethis_world/src/world/faction_membership.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';

export 'package:colonizethis_world/src/world/faction_membership.dart';
import 'alliance_resolver.dart';
import 'diplomacy_relation_lookup.dart';
import 'ftp_resolver.dart';
import 'diplomacy_subsidies_relations_resolver.dart';
import 'intervention_resolver.dart';
import 'overture_resolver.dart';
import 'war_resolver.dart';

export 'diplomacy_relation_lookup.dart';
export 'diplomacy_subsidies_relations_resolver.dart'
    show kWorldMarketBaselineBidTypeCap, tradeSlotsForGp, worldMarketBidTypeCap;
export 'ftp_resolver.dart'
    show aiGpAcceptsFtp, breakFtpOnEmbassyLoss, breakFtpOnWar;
export 'diplomacy_relation_lookup.dart'
    show ftpPairKeysFromGame, hasEmbassyOverture, hasFtpPartnership;
export 'intervention_resolver.dart'
    show applyInterventionChoice, needsInterventionChoice;

final diploLog = logicLog;

/// Target GP is "nearly defeated" for Join Empire: ≤3 provinces and does not hold its original capital tile province. SPEC/game/diplomacy.md.
bool isGreatPowerNearlyDefeatedForJoinEmpire(
  Game game,
  String gpId, {
  DiplomacyFactionMembership? factionMembership,
}) {
  final isGp =
      factionMembership?.isGreatPower(gpId) ?? isGreatPower(game, gpId);
  if (!isGp) return false;
  final player = game.playerById(gpId);
  final capId = player?.capitalProvinceId;
  if (capId == null) return false;
  final capProv = game.worldState.tryGetProvince(capId);
  if (capProv == null) return false;
  if (capProv.ownerId == gpId) return false;
  final n = provinceCountOwnedBy(game, gpId);
  return n <= 3;
}

/// Resolves Diplomacy phase. Runs before Movement per turn-resolution-phases.
/// When an AI applies declare war or offer peace, [onDialogue] is invoked with
/// a [DialogueEvent] (SPEC/ai/dialogue-and-mood.md).
/// Returns [DiplomacyPhaseResult]: when an overture targets a human GP and
/// [overtureDecisions] does not supply a decision, returns pending so turn
/// resolution can block. When [overtureDecisions] is provided (resume path),
/// applies those decisions and does not suspend.
/// Call to arms: after GP–GP war declarations, allies of the defender may need
/// to join or refuse; [callToArmsDecisions] supplies human responses on resume.
DiplomacyPhaseResult resolveDiplomacyPhase(
  Game game,
  Orders orders, {
  void Function(DialogueEvent)? onDialogue,
  List<OvertureDecision>? overtureDecisions,
  List<FtpDecision>? ftpDecisions,
  List<InterventionDecision>? interventionDecisions,
  List<CallToArmsDecision>? callToArmsDecisions,
}) {
  diploLog.d('diplomacy phase start');
  final turn = game.worldState.turnState.turnNumber;
  var state = game;

  final diploByPlayer = orders.diplomaticOrdersByPlayerId;
  var factionMembership = DiplomacyFactionMembership.from(game);

  // 1. Process overture offers (two-way: target accepts/rejects)
  final overtureResult = processOverturePayments(
    state,
    diploByPlayer,
    turn,
    factionMembership: factionMembership,
    overtureDecisions: overtureDecisions,
  );
  state = overtureResult.game;
  if (overtureResult.pendingOvertures != null &&
      overtureResult.pendingOvertures!.isNotEmpty) {
    diploLog.d('diplomacy phase suspended (pending overture decisions)');
    return DiplomacyPhaseResult(
      state,
      pendingOvertures: overtureResult.pendingOvertures,
    );
  }

  // 2. Advance in-progress overtures (turn delays)
  state = advanceOvertures(state, turn);

  // 3. Resolve Join Empire/Colony
  state = resolveJoinEmpireColony(state, diploByPlayer, turn);
  factionMembership = DiplomacyFactionMembership.from(state);

  // 4. Process alliance proposals and responses
  state = processAlliances(
    state,
    diploByPlayer,
    turn,
    factionMembership: factionMembership,
  );

  // 4b. Process FTP proposals (GP–GP, two-way accept)
  final ftpResult = processFtpProposals(
    state,
    diploByPlayer,
    turn,
    factionMembership: factionMembership,
    ftpDecisions: ftpDecisions,
  );
  state = ftpResult.game;
  if (ftpResult.pendingFtpOffers != null &&
      ftpResult.pendingFtpOffers!.isNotEmpty) {
    diploLog.d('diplomacy phase suspended (pending FTP decisions)');
    return DiplomacyPhaseResult(
      state,
      pendingFtpOffers: ftpResult.pendingFtpOffers,
    );
  }

  // 5. Process Declare War and Peace
  state = processWarAndPeace(
    state,
    diploByPlayer,
    turn,
    factionMembership: factionMembership,
    onDialogue: onDialogue,
  );

  // 5b. Intervention (Diplomacy phase, after war declarations on Minor/Tribe)
  final interventionResult = resolveOutstandingInterventionsForMinorTribeWars(
    state,
    diploByPlayer,
    turn,
    factionMembership: factionMembership,
    interventionDecisions: interventionDecisions,
  );
  if (interventionResult.pendingInterventions != null &&
      interventionResult.pendingInterventions!.isNotEmpty) {
    return DiplomacyPhaseResult(
      interventionResult.game,
      pendingInterventions: interventionResult.pendingInterventions,
    );
  }
  state = interventionResult.game;

  // 5c. Call to arms (allies of GP declared upon). SPEC/game/diplomacy.md.
  final ctaResult = processCallToArms(
    state,
    diploByPlayer,
    turn,
    factionMembership: factionMembership,
    callToArmsDecisions: callToArmsDecisions,
  );
  state = ctaResult.game;
  if (ctaResult.pendingCallToArms != null &&
      ctaResult.pendingCallToArms!.isNotEmpty) {
    diploLog.d('diplomacy phase suspended (pending call to arms)');
    return DiplomacyPhaseResult(
      state,
      pendingCallToArms: ctaResult.pendingCallToArms,
    );
  }

  // 6. War terminates agreements with target
  state = terminateAgreementsOnWar(state);
  state = breakFtpOnWar(state, turn);
  state = breakFtpOnEmbassyLoss(state, turn);

  // 7. Process ongoing subsidies (+2 per 500 ducats, max +8 per turn)
  // Note: Convergence happens AFTER subsidies
  state = processOngoingSubsidies(
    state,
    turn,
    factionMembership: factionMembership,
  );

  // 8. Apply relation convergence (+/1 toward 50 for all non-war relations)
  state = applyRelationConvergence(state, turn);

  // 9. Apply relation modifiers (grants, etc.)
  state = applyRelationModifiersAndUpdateScores(state, diploByPlayer, turn);

  diploLog.d('diplomacy phase end');
  return DiplomacyPhaseResult(state);
}
