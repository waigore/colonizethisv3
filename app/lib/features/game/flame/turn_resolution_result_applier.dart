import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

import '../../../../config/ct_e2e_turn_snapshot_refresh.dart';
import '../../../../providers/games_provider.dart';

void applyTurnResolutionResult(WidgetRef ref, TurnResolutionResult result) {
  final gameN = ref.read(currentGameProvider.notifier);
  final ordersN = ref.read(currentOrdersProvider.notifier);
  final dipN = ref.read(pendingDiplomacyProvider.notifier);
  switch (result) {
    case TurnResolutionComplete():
      gameN.setGame(result.game);
      ordersN.clear();
      dipN.clear();
    case TurnResolutionPendingOvertures():
      gameN.setGame(result.game);
      dipN.setOvertures(result.pendingOvertures);
    case TurnResolutionPendingFtp():
      gameN.setGame(result.game);
      dipN.setFtp(result.pendingFtpOffers);
    case TurnResolutionPendingIntervention():
      gameN.setGame(result.game);
      dipN.setIntervention(result.pendingInterventions);
    case TurnResolutionPendingCallToArms():
      gameN.setGame(result.game);
      dipN.setCallToArms(result.pendingCallToArms);
  }
  refreshCtE2eNavalPanelSnapshotAfterTurnIfEnabled(ref);
}
