import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_service_provider.dart';
import 'game_summary_support.dart';
import 'games_provider.dart';
import '../features/game/widgets/shell/shell_player_context.dart';

final _labourFeedingHudLog = packageLogger('labour_feeding_hud');

/// Post-extraction labour and forces-feeding preview for the map tab bar.
/// SPEC/ui/empire-overview.md § Labour and feeding indicator (Refs #4506).
class LabourFeedingHudSummary {
  const LabourFeedingHudSummary({
    required this.labourReadiness,
    required this.forcesFeeding,
    this.notDefined = false,
  });

  const LabourFeedingHudSummary.notDefined()
    : labourReadiness = const LabourReadinessSnapshot(
        effectiveLabour: 0,
        fullCapacity: 0,
        tierStatuses: [],
      ),
      forcesFeeding = const ForceFeedingSnapshot(
        totalRegiments: 0,
        fullyFedRegiments: 0,
        totalShips: 0,
        fullyFedShips: 0,
        landCombatTier: ForceFeedingCombatTier.full,
        navalCombatTier: ForceFeedingCombatTier.full,
        forcesFoodDemand: 0,
      ),
      notDefined = true;

  final LabourReadinessSnapshot labourReadiness;
  final ForceFeedingSnapshot forcesFeeding;
  final bool notDefined;
}

final labourFeedingHudSummaryProvider = Provider<LabourFeedingHudSummary>((
  ref,
) {
  final game = ref.watch(currentGameProvider);
  if (game == null) {
    return const LabourFeedingHudSummary.notDefined();
  }
  return computeGameSummary<LabourFeedingHudSummary>(
    game: game,
    shell: ref.watch(shellPlayerContextProvider),
    orders: ref.watch(currentOrdersProvider),
    gameService: ref.watch(gameServiceProvider),
    whenNoGame: const LabourFeedingHudSummary.notDefined(),
    notDefined: (shell) =>
        shell.treasuryNotDefined ||
        shell.cargoNotDefined ||
        !shell.showPlayerChrome,
    whenNotDefined: () => const LabourFeedingHudSummary.notDefined(),
    log: _labourFeedingHudLog,
    compute: (context) {
      final regimentCounts = regimentTypeCountsForPlayer(
        context.game.worldState,
        context.playerId,
      );
      final shipCounts = shipTypeCountsForPlayer(
        context.game.worldState,
        context.playerId,
      );
      final foodCounts = MilitaryNavyFoodCounts(
        regimentCountsById: regimentCounts,
        shipCountsById: shipCounts,
      );
      final previewInputs = economyPreviewInputs(
        tileMapByRegion: context.tileMapByRegion,
        currentOrders: context.orders,
      );
      final labourReadiness = labourReadinessForPlayer(
        game: context.game,
        topology: context.topology,
        playerId: context.playerId,
        foodCounts: foodCounts,
        inputs: previewInputs,
      );
      final forcesFeeding = forcesFeedingForPlayer(
        game: context.game,
        topology: context.topology,
        playerId: context.playerId,
        foodCounts: foodCounts,
        inputs: previewInputs,
      );
      return LabourFeedingHudSummary(
        labourReadiness: labourReadiness,
        forcesFeeding: forcesFeeding,
      );
    },
    onError: (_, _) => const LabourFeedingHudSummary.notDefined(),
  );
});
