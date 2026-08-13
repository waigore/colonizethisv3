import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_phase_result.dart';

class OverturePaymentsResult {
  OverturePaymentsResult(this.game, [this.pendingOvertures]);
  final Game game;
  final List<OvertureOffer>? pendingOvertures;
}

/// Result of processing one establish-overture order: the (possibly updated)
/// rolling state, or an [earlyExit] when the phase must suspend for human input.
typedef OvertureOrderStep = ({
  List<Player> players,
  List<OvertureState> overtures,
  Game state,
  Player player,
  OverturePaymentsResult? earlyExit,
});
