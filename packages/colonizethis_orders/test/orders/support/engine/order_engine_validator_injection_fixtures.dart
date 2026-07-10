// Shared OrderEngine validator-injection scenario fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_engine.dart';
import 'package:colonizethis_orders/src/orders/order_resolution_context.dart';
import 'package:colonizethis_orders/src/orders/order_validators.dart';
import 'package:colonizethis_orders/src/orders/validators/army_move_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/build_order_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic_order_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/move_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/naval_order_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/recruit_worker_order_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/work_order_validator.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Injected move validator that always rejects for factory-injection scenarios.
class AlwaysRejectMoveValidator extends MoveValidator {
  const AlwaysRejectMoveValidator();

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

OrderEngine oeviEngineWithInjectedMoveValidator() {
  return OrderEngine(
    initialOrders: Orders(
      moveOrdersByPlayerId: {
        'p1': const [
          MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P1|0|0'),
        ],
      },
    ),
    validatorFactory: oeviInjectedMoveValidatorFactory,
  );
}

OrderValidators oeviInjectedMoveValidatorFactory(
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
    moveValidator: const AlwaysRejectMoveValidator(),
    armyMoveValidator: const ArmyMoveValidator(),
    recruitWorkerValidator: RecruitWorkerOrderValidator(player: player),
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
}

OrderEngine oeviEngineWithCountingFactory(void Function() onFactoryCall) {
  return OrderEngine(
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
          onFactoryCall();
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
}

Game oeviMinimalSinglePlayerGame() => TestFixtures.minimalGame(
  players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
);

Game oeviDefaultGame() => TestFixtures.minimalGame();

MapTopology oeviEmptyTopology() =>
    MapTopology(nodes: const [], edges: const []);
