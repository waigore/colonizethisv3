import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/ct_e2e_turn_snapshot_refresh.dart';
import '../../../../core/services/game_service.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';

/// Applies [TurnResolutionResult] to session notifiers and optional E2E snapshot
/// hooks without threading [WidgetRef] through helper signatures.
class TurnResolutionResultApplier {
  const TurnResolutionResultApplier({
    required this.gameNotifier,
    required this.ordersNotifier,
    required this.diplomacyNotifier,
    required this.gameService,
    required this.gameReader,
    required this.ordersReader,
  });

  final CurrentGameNotifier gameNotifier;
  final CurrentOrdersNotifier ordersNotifier;
  final PendingDiplomacyNotifier diplomacyNotifier;
  final GameService gameService;
  final Game? Function() gameReader;
  final Orders Function() ordersReader;

  void apply(TurnResolutionResult result) {
    switch (result) {
      case TurnResolutionComplete():
        gameNotifier.setGame(result.game);
        ordersNotifier.clear();
        diplomacyNotifier.clear();
      case TurnResolutionPendingOvertures():
        gameNotifier.setGame(result.game);
        diplomacyNotifier.setOvertures(result.pendingOvertures);
      case TurnResolutionPendingFtp():
        gameNotifier.setGame(result.game);
        diplomacyNotifier.setFtp(result.pendingFtpOffers);
      case TurnResolutionPendingIntervention():
        gameNotifier.setGame(result.game);
        diplomacyNotifier.setIntervention(result.pendingInterventions);
      case TurnResolutionPendingCallToArms():
        gameNotifier.setGame(result.game);
        diplomacyNotifier.setCallToArms(result.pendingCallToArms);
    }
    refreshCtE2eNavalPanelSnapshotAfterTurnIfEnabled(
      game: gameReader(),
      draftOrders: ordersReader(),
      gameService: gameService,
    );
  }
}

final turnResolutionResultApplierProvider =
    Provider<TurnResolutionResultApplier>((ref) {
      return TurnResolutionResultApplier(
        gameNotifier: ref.read(currentGameProvider.notifier),
        ordersNotifier: ref.read(currentOrdersProvider.notifier),
        diplomacyNotifier: ref.read(pendingDiplomacyProvider.notifier),
        gameService: ref.read(gameServiceProvider),
        gameReader: () => ref.read(currentGameProvider),
        ordersReader: () => ref.read(currentOrdersProvider),
      );
    });
