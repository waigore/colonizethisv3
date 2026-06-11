/// The Diplomacy phase result plus a single import/export surface for the
/// per-interaction human-input value types.
///
/// The pure data types describing the human-input prompts the Diplomacy phase
/// can surface (overtures, FTP proposals, interventions, calls to arms) now
/// live one-per-file under `phase_types/` (Refs #3419 step 9). This file
/// retains [DiplomacyPhaseResult] and re-exports those value types so the
/// existing public surface is preserved: the turn orchestrator's
/// [TurnResolutionResult] (in `turn/turn_resolution_result.dart`) still depends
/// on this single file one-way (turn -> diplomacy) without the diplomacy domain
/// importing `turn/` (Refs #3290 Phase 0), and the package barrel keeps
/// publishing every value type transitively.
/// SPEC/program/turn-resolution-phases.md § Blocking human input;
/// SPEC/game/diplomacy.md § Intervention.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'phase_types/call_to_arms_pending.dart';
import 'phase_types/ftp_offer.dart';
import 'phase_types/intervention_prompt.dart';
import 'phase_types/overture_offer.dart';

export 'phase_types/call_to_arms_pending.dart';
export 'phase_types/ftp_offer.dart';
export 'phase_types/intervention_prompt.dart';
export 'phase_types/overture_offer.dart';

/// Result of the Diplomacy phase: complete or pending human input.
class DiplomacyPhaseResult {
  const DiplomacyPhaseResult(
    this.game, {
    this.pendingOvertures,
    this.pendingFtpOffers,
    this.pendingInterventions,
    this.pendingCallToArms,
  });

  final Game game;
  /// Non-null when phase suspended because an overture targets a human GP.
  final List<OvertureOffer>? pendingOvertures;
  /// Non-null when phase suspended because an FTP proposal targets a human GP.
  final List<FtpOffer>? pendingFtpOffers;
  /// Non-null when phase suspended for intervention choices (GP with embassy or purchased land).
  final List<InterventionPrompt>? pendingInterventions;
  /// Non-null when phase suspended because a human ally must accept/refuse call to arms.
  final List<CallToArmsPending>? pendingCallToArms;

  bool get isPending =>
      (pendingOvertures != null && pendingOvertures!.isNotEmpty) ||
      (pendingFtpOffers != null && pendingFtpOffers!.isNotEmpty) ||
      (pendingInterventions != null && pendingInterventions!.isNotEmpty) ||
      (pendingCallToArms != null && pendingCallToArms!.isNotEmpty);
}
