import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/diplomatic_access_helpers.dart';
import 'package:colonizethis_orders/src/orders/validators/work_order_target_prechecks.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('workOrderTargetPrechecks explorer consulate', () {
    test(
      'precheckExplorerConsulateInMinorTribe rejects explore without Consulate',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        const tribeProvinceId = '$ow|t1';
        const tileKey = '$tribeProvinceId|0|0';
        final game = TestFixtures.minimalGame(
          id: 'g1',
          players: const [
            Player(id: playerId, displayName: 'GP One', isHuman: false),
          ],
          tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe One')],
          overtureStates: const [],
        );
        final player = game.players.single;
        final ctx = WorkOrderTargetPrecheckContext(
          game: game,
          player: player,
          playerId: playerId,
          treasury: 0,
          civilianEmbassyWorkAllowed: (_, __) => false,
          devExclusiveTiles: const {},
          factionMembership: DiplomacyFactionMembership.from(game),
        );
        final order = WorkOrder(
          unitId: 'e1',
          target: kWorkTargetExplore,
          targetTileKey: tileKey,
        );
        final r = runWorkOrderTargetPrecheck(
          ctx,
          order,
          tribeProvinceId,
          'tribe1',
          kUnitTypeExplorer,
        );
        expect(r, isNotNull);
        expect(r!.status, OrderValidationStatus.rejected);
        expect(r.reason, kReasonConsulateRequiredForExplore);
      },
    );
  });
}
