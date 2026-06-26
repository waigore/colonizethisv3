/// Friendship-and-trade-pact (FTP) human-input value types for the Diplomacy
/// phase.
///
/// [FtpOffer] is surfaced when an FTP proposal targets a human GP that must
/// accept or reject it; [FtpDecision] carries that target GP's reply. Split out
/// of `diplomacy_phase_result.dart` so each diplomacy-phase value type lives in
/// its own file (Refs #3419 step 9). SPEC/game/diplomacy.md § Friendship and
/// trade pacts; SPEC/program/turn-resolution-phases.md § Blocking human input.
library;

import 'value_equality.dart';

/// One FTP proposal awaiting the target GP's accept/reject decision.
class FtpOffer with ValueEquality {
  const FtpOffer({
    required this.proposerGpId,
    required this.targetGpId,
  });

  final String proposerGpId;
  final String targetGpId;

  @override
  List<Object?> get equalityFields => [proposerGpId, targetGpId];
}

/// Target GP's decision for one [FtpOffer].
class FtpDecision with ValueEquality {
  const FtpDecision({
    required this.proposerGpId,
    required this.targetGpId,
    required this.accepted,
  });

  final String proposerGpId;
  final String targetGpId;
  final bool accepted;

  @override
  List<Object?> get equalityFields => [proposerGpId, targetGpId, accepted];
}
