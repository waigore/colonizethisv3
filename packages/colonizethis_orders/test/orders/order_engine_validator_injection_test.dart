import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/order_engine.dart';
import 'package:colonizethis_orders/src/orders/order_resolution_context.dart';
import 'package:colonizethis_orders/src/orders/validators/army_move_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/build_order_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic_order_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/move_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/naval_order_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/recruit_worker_order_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/work_order_validator.dart';
import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_resolver.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

class _AlwaysRejectMoveValidator extends MoveValidator {
  const _AlwaysRejectMoveValidator();

  @override
  OrderValidationResult validate(
    MoveOrder order,
    Game game,
    String playerId,
    OrderResolutionContext context,
    List<DiplomaticOrder> diplomaticOrders,
    MapTopology topology, {
    required bool previousRejected,
    DiplomacyFactionMembership? factionMembership,
  }) {
    return OrderValidationResult.rejected('Injected move validator rejection');
  }
}

void main() {
  test('OrderEngine validator factory allows injected validators', () {
    final game = TestFixtures.minimalGame(
      players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
    );
    final topology = MapTopology(nodes: const [], edges: const []);
    final engine = OrderEngine(
      initialOrders: Orders(
        moveOrdersByPlayerId: {
          'p1': const [
            MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P1|0|0'),
          ],
        },
      ),
      validatorFactory:
          (
            Game game,
            Player player,
            String playerId,
            OrderResolutionContext resolution,
            MapTopology topology,
            List<DiplomaticOrder> diplomaticOrders,
            Map<String, TileMapResult>? tileMapByRegion,
            Set<String> civilianDraftMoveUnitIds,
            Set<String> devExclusiveTiles,
            Stockpile stockpile,
            int treasury,
            DiplomacyFactionMembership factionMembership,
            WorkerPool workerPool,
          ) {
            final workContext = buildWorkOrderValidationContext(
              game: game,
              player: player,
              playerId: playerId,
              resolution: resolution,
              devExclusiveTiles: devExclusiveTiles,
              tileMapByRegion: tileMapByRegion,
              civilianDraftMoveUnitIds: civilianDraftMoveUnitIds,
              diplomaticOrders: diplomaticOrders,
              topology: topology,
              factionMembership: factionMembership,
            );
            return OrderValidators(
              moveValidator: const _AlwaysRejectMoveValidator(),
              armyMoveValidator: const ArmyMoveValidator(),
              recruitWorkerValidator: RecruitWorkerOrderValidator(
                player: player,
              ),
              buildValidator: BuildOrderValidator(game: game, player: player),
              workValidator: WorkOrderValidator(
                context: workContext,
                stockpile: stockpile,
                treasury: treasury,
              ),
              diplomaticValidator: DiplomaticOrderValidator(
                game: game,
                playerId: playerId,
                initialTreasury: treasury,
              ),
              navalValidator: NavalOrderValidator(
                game: game,
                topology: topology,
                playerId: playerId,
              ),
            );
          },
    );

    final results = engine.validatePlayerOrdersWithContext(
      game,
      topology,
      'p1',
    );
    expect(results, hasLength(1));
    expect(results.single.isAccepted, isFalse);
    expect(results.single.reason, 'Injected move validator rejection');
  });

  test(
    'validatePlayerOrdersWithContext builds six validator bundles '
    '(shared move+army, then fresh per later category; #2391 AC7, #2692 S4)',
    () {
      var factoryCalls = 0;
      final game = TestFixtures.minimalGame();
      final topology = MapTopology(nodes: const [], edges: const []);
      final engine = OrderEngine(
        initialOrders: const Orders(),
        validatorFactory:
            (
              Game game,
              Player player,
              String playerId,
              OrderResolutionContext resolution,
              MapTopology topology,
              List<DiplomaticOrder> diplomaticOrders,
              Map<String, TileMapResult>? tileMapByRegion,
              Set<String> civilianDraftMoveUnitIds,
              Set<String> devExclusiveTiles,
              Stockpile stockpile,
              int treasury,
              DiplomacyFactionMembership factionMembership,
              WorkerPool workerPool,
            ) {
              factoryCalls++;
              return createOrderValidators(
                game: game,
                player: player,
                playerId: playerId,
                resolution: resolution,
                topology: topology,
                diplomaticOrders: diplomaticOrders,
                tileMapByRegion: tileMapByRegion,
                civilianDraftMoveUnitIds: civilianDraftMoveUnitIds,
                devExclusiveTiles: devExclusiveTiles,
                stockpile: stockpile,
                treasury: treasury,
                factionMembership: factionMembership,
                workerPool: workerPool,
              );
            },
      );

      engine.validatePlayerOrdersWithContext(game, topology, 'h1');
      expect(factoryCalls, 6);
    },
  );
}
