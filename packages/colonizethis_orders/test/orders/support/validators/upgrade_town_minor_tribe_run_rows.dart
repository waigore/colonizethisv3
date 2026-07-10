// Scenario run tear-offs for upgrade_town Minor/Tribe (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';
import 'package:colonizethis_orders/src/orders/validators/work_order_target_prechecks.dart';
import 'package:colonizethis_orders/src/orders/work_tile_candidacy/work_tile_candidacy.dart';
import 'package:colonizethis_test/test.dart';

import 'upgrade_town_minor_tribe_fixtures.dart';

void utmtRunPrefilterIncludesMinorTownWhenEmbassyAndPeace() {
  const minorTown = '$utmtOw|p2|0|0';
  final game = utmtMinorTownEmbassyPeaceGame();
  final tiles = rawCandidateTilesForWorkTarget(
    game: game,
    playerId: utmtGpId,
    workTarget: kWorkTargetUpgradeTown,
    playerOwnedProvinceIds: {'$utmtOw|p1'},
  );
  expect(tiles, contains(minorTown));
}

void utmtRunPrecheckRejectsUpgradeTownWhenAtWarWithTribe() {
  const tribeId = 'tribe1';
  const townKey = '$utmtOw|p2|0|0';
  final game = utmtWarTribeUpgradeGame();
  final ctx = WorkOrderTargetPrecheckContext(
    game: game,
    player: game.players.single,
    playerId: utmtGpId,
    treasury: 1000,
    civilianEmbassyWorkAllowed: (_, _) => false,
    devExclusiveTiles: const {},
  );
  final result = precheckUpgradeTown(
    ctx,
    WorkOrder(
      unitId: 'u1',
      target: kWorkTargetUpgradeTown,
      targetTileKey: townKey,
    ),
    '$utmtOw|p2',
    tribeId,
    kUnitTypeBuilder,
  );
  expect(result?.reason, contains('at war'));
}
