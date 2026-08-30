import 'package:colonizethis_logic/ai_api.dart'
    show peerLockRecoverySellerNeededProducibleImprovementInputs;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'treasury_lock_recovery.dart';

/// Seller-role flags shared by surplus/need maps and lock-recovery bid shaping.
final class TreasuryLockRecoverySellerFlags {
  const TreasuryLockRecoverySellerFlags({
    required this.lockRecoveryScan,
    required this.isLockRecoverySeller,
    required this.isRegimentBuildInputMarketSupplier,
  });

  final LockRecoveryGameScan lockRecoveryScan;
  final bool isLockRecoverySeller;
  final bool isRegimentBuildInputMarketSupplier;
}

TreasuryLockRecoverySellerFlags resolveTreasuryLockRecoverySellerFlags({
  required Game game,
  required String playerId,
  AIWorldSnapshot? snapshot,
}) {
  final lockRecoveryScan = LockRecoveryGameScan.fromGame(
    game,
    snapshot: snapshot,
  );
  final isLockRecoverySeller = lockRecoveryScan.isLockRecoverySeller(playerId);
  final regimentBuildInputMarketSupplyActive =
      lockRecoveryScan.anySellerNeedsRegimentBuildInput ||
      lockRecoveryScan.anySellerNeedsCastIronLabourPeasantRecruitFabric ||
      peerLockRecoverySellerNeededProducibleImprovementInputs(
        game,
        excludePlayerId: playerId,
      ).isNotEmpty;
  final isRegimentBuildInputMarketSupplier =
      regimentBuildInputMarketSupplyActive && !isLockRecoverySeller;
  return TreasuryLockRecoverySellerFlags(
    lockRecoveryScan: lockRecoveryScan,
    isLockRecoverySeller: isLockRecoverySeller,
    isRegimentBuildInputMarketSupplier: isRegimentBuildInputMarketSupplier,
  );
}
