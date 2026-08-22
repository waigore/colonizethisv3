import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'order_validators.dart';

/// Treasury available for build validation after pending riches cash-in.
int projectedTreasuryForBuildValidation({
  required Game game,
  required Stockpile stockpile,
  required int treasury,
}) =>
    treasury +
    pendingRichesTreasuryDelta(
      stockpile: stockpile,
      richesCashMultiplier: game.richesCashMultiplier,
    );

/// Shared recruit-worker validator construction for full-pass and incremental
/// probe paths (Refs #3877).
RecruitWorkerOrderValidator createProjectedRecruitWorkerValidator({
  required Player player,
  required Stockpile stockpile,
  required int treasury,
  required WorkerPool workerPool,
}) => RecruitWorkerOrderValidator.withProjectedEconomy(
  player: player,
  stockpile: stockpile,
  treasury: treasury,
  workerPool: workerPool,
);

/// Shared build validator construction for full-pass and incremental probe
/// paths (Refs #3877).
BuildOrderValidator createProjectedBuildValidator({
  required Game game,
  required Player player,
  required Stockpile stockpile,
  required int treasury,
  required WorkerPool workerPool,
}) => BuildOrderValidator.withProjectedEconomy(
  game: game,
  player: player,
  stockpile: stockpile,
  treasury: projectedTreasuryForBuildValidation(
    game: game,
    stockpile: stockpile,
    treasury: treasury,
  ),
  workerPool: workerPool,
);

/// Shared diplomatic validator construction for full-pass and incremental
/// probe paths (Refs #3877).
DiplomaticOrderValidator createProjectedDiplomaticValidator({
  required Game game,
  required String playerId,
  required int initialTreasury,
  required DiplomacyFactionMembership factionMembership,
}) => DiplomaticOrderValidator(
  game: game,
  playerId: playerId,
  initialTreasury: initialTreasury,
  factionMembership: factionMembership,
);
