import '../perception/perception_snapshot.dart';
import 'expand_phase_planner_economy.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'planning_imports.dart' hide cheapestRegimentBuildTreasuryCost;
import 'treasury_lock_recovery_seller.dart';
import 'treasury_planner_constants.dart';

/// Per-turn lock-recovery aggregates computed in one `game.players` pass (Refs
/// #3288). Replaces repeated O(players) scans inside the treasury hot path.
final class LockRecoveryGameScan {
  LockRecoveryGameScan._({
    required this.sortedGpIds,
    required this.anyBrokeGreatPower,
    required this.anySellerNeedsRegimentBuildInput,
    required this.anySellerNeedsCastIronLabourPeasantRecruitFabric,
    required this.anySellerNeedsCastIronImprovementInput,
    required this.isLockRecoverySellerByPlayerId,
    required this.designatedBuyerId,
  });

  final List<String> sortedGpIds;
  final bool anyBrokeGreatPower;
  final bool anySellerNeedsRegimentBuildInput;
  final bool anySellerNeedsCastIronLabourPeasantRecruitFabric;
  final bool anySellerNeedsCastIronImprovementInput;
  final Map<String, bool> isLockRecoverySellerByPlayerId;
  final String designatedBuyerId;

  factory LockRecoveryGameScan.fromGame(
    Game game, {
    AIWorldSnapshot? snapshot,
  }) {
    final regimentThreshold = cheapestRegimentBuildTreasuryCost();
    final affluenceThreshold = treasuryAffluenceThreshold();
    final sortedGpIds = <String>[];
    var anyBrokeGreatPower = false;
    var anySellerNeedsRegimentBuildInput = false;
    var anySellerNeedsCastIronLabourPeasantRecruitFabric = false;
    var anySellerNeedsCastIronImprovementInput = false;
    final isLockRecoverySellerByPlayerId = <String, bool>{};
    final affluentNonSellerIds = <String>[];

    for (final player in game.players) {
      sortedGpIds.add(player.id);
      if (player.treasury < regimentThreshold) {
        anyBrokeGreatPower = true;
      }
      final isSeller = isBelowQuotaZeroNwLockRecoverySellerInternal(
        game: game,
        playerId: player.id,
        snapshot: snapshot?.playerId == player.id ? snapshot : null,
      );
      isLockRecoverySellerByPlayerId[player.id] = isSeller;
      if (isSeller) {
        if (lockRecoverySellerNeedsRegimentBuildInput(
          game,
          player,
          regimentThreshold: regimentThreshold,
        )) {
          anySellerNeedsRegimentBuildInput = true;
        }
        if (lockRecoverySellerNeedsCastIronLabourPeasantRecruitFabric(
          game,
          player,
        )) {
          anySellerNeedsCastIronLabourPeasantRecruitFabric = true;
        }
        if (lockRecoverySellerNeedsCastIronImprovementInput(game, player)) {
          anySellerNeedsCastIronImprovementInput = true;
        }
      }
      if (player.treasury >= affluenceThreshold && !isSeller) {
        affluentNonSellerIds.add(player.id);
      }
    }
    sortedGpIds.sort();
    affluentNonSellerIds.sort();

    final designatedBuyerId =
        !anyBrokeGreatPower || affluentNonSellerIds.isEmpty
        ? ''
        : affluentNonSellerIds[game.worldState.turnState.turnNumber %
              affluentNonSellerIds.length];

    return LockRecoveryGameScan._(
      sortedGpIds: sortedGpIds,
      anyBrokeGreatPower: anyBrokeGreatPower,
      anySellerNeedsRegimentBuildInput: anySellerNeedsRegimentBuildInput,
      anySellerNeedsCastIronLabourPeasantRecruitFabric:
          anySellerNeedsCastIronLabourPeasantRecruitFabric,
      anySellerNeedsCastIronImprovementInput:
          anySellerNeedsCastIronImprovementInput,
      isLockRecoverySellerByPlayerId: isLockRecoverySellerByPlayerId,
      designatedBuyerId: designatedBuyerId,
    );
  }

  bool isLockRecoverySeller(String playerId) =>
      isLockRecoverySellerByPlayerId[playerId] ?? false;
}
