import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/diplomacy/diplomacy_resolver.dart';
import 'package:colonizethis_logic/src/orders/order_resolution_context.dart';
import 'package:colonizethis_logic/src/orders/order_validators.dart';
import 'package:colonizethis_logic/src/orders/validator_bundle.dart';
import 'package:colonizethis_logic/src/world/player_view.dart';
import 'package:colonizethis_logic/src/world/unit_lookup.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../test_fixtures.dart';

void main() {
  test('createOrderValidators returns wired validators (Refs #2391 AC6)', () {
    final game = TestFixtures.minimalGame(
      players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
    );
    final player = game.players.single;
    const playerId = 'p1';
    final topology = MapTopology(nodes: const [], edges: const []);
    final view = buildPlayerView(game, topology, playerId);
    final unitsById = unitsByIdFromWorld(game.worldState);
    const diplomaticOrders = <DiplomaticOrder>[];
    const civilianDraftMoveUnitIds = <String>{};
    const devExclusiveTiles = <String>{};
    final stockpile = player.stockpile;
    final treasury = player.treasury;
    final resolution = orderResolutionContextFromView(
      view,
      game,
      unitsById: unitsById,
    );

    final ctx = buildWorkOrderValidationContext(
      game: game,
      player: player,
      playerId: playerId,
      resolution: resolution,
      devExclusiveTiles: devExclusiveTiles,
      tileMapByRegion: null,
      civilianDraftMoveUnitIds: civilianDraftMoveUnitIds,
      diplomaticOrders: diplomaticOrders,
      topology: topology,
    );

    final bundle = createOrderValidators(
      game: game,
      player: player,
      playerId: playerId,
      view: view,
      topology: topology,
      unitsById: unitsById,
      diplomaticOrders: diplomaticOrders,
      tileMapByRegion: null,
      civilianDraftMoveUnitIds: civilianDraftMoveUnitIds,
      devExclusiveTiles: devExclusiveTiles,
      stockpile: stockpile,
      treasury: treasury,
      factionMembership: DiplomacyFactionMembership.from(game),
    );

    expect(ctx.playerId, playerId);
    expect(bundle.moveValidator, isA<MoveValidator>());
    expect(bundle.armyMoveValidator, isA<ArmyMoveValidator>());
    expect(bundle.recruitWorkerValidator, isA<RecruitWorkerOrderValidator>());
    expect(bundle.buildValidator, isA<BuildOrderValidator>());
    expect(bundle.workValidator, isA<WorkOrderValidator>());
    expect(bundle.diplomaticValidator, isA<DiplomaticOrderValidator>());
    expect(bundle.navalValidator, isA<NavalOrderValidator>());
  });
}
