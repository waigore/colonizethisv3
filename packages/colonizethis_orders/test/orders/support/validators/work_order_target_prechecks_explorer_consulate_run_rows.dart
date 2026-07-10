// Scenario run tear-offs for explorer consulate prechecks (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/diplomatic_access_helpers.dart';
import 'package:colonizethis_orders/src/orders/validators/work_order_target_prechecks.dart';
import 'package:colonizethis_test/test.dart';

import 'work_order_target_prechecks_explorer_consulate_fixtures.dart';

void wotpecRunRejectsExploreWithoutConsulate() {
  final game = explorerConsulatePrecheckGame();
  final player = game.players.single;
  final ctx = WorkOrderTargetPrecheckContext(
    game: game,
    player: player,
    playerId: explorerConsulatePrecheckPlayerId,
    treasury: 0,
    civilianEmbassyWorkAllowed: (_, __) => false,
    devExclusiveTiles: const {},
    factionMembership: DiplomacyFactionMembership.from(game),
  );
  final order = WorkOrder(
    unitId: 'e1',
    target: kWorkTargetExplore,
    targetTileKey: explorerConsulatePrecheckTileKey,
  );
  final r = runWorkOrderTargetPrecheck(
    ctx,
    order,
    explorerConsulatePrecheckTribeProvinceId,
    'tribe1',
    kUnitTypeExplorer,
  );
  expect(r, isNotNull);
  expect(r!.status, OrderValidationStatus.rejected);
  expect(r.reason, kReasonConsulateRequiredForExplore);
}
