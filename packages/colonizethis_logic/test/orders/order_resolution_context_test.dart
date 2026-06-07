import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/orders/order_resolution_context.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_world/src/world/unit_lookup.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../test_fixtures.dart';

void main() {
  test(
    'buildOrderResolutionContext reuses view and cached units (Refs #2836)',
    () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      const playerId = 'p1';
      final topology = MapTopology(nodes: const [], edges: const []);
      final view = buildPlayerView(game, topology, playerId);
      final units = game.worldState.allUnitsById;

      final ctx = buildOrderResolutionContext(
        game: game,
        topology: topology,
        playerId: playerId,
        view: view,
        unitsById: units,
      );

    expect(identical(ctx.view, view), isTrue);
    expect(identical(ctx.unitsById, units), isTrue);
    expect(identical(ctx.provinceById, view.provincesById), isTrue);
    },
  );

  test('orderResolutionContextFromView aliases provincesById', () {
    final game = TestFixtures.minimalGame(
      players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
    );
    const playerId = 'p1';
    final topology = MapTopology(nodes: const [], edges: const []);
    final view = buildPlayerView(game, topology, playerId);

    final ctx = orderResolutionContextFromView(view, game);

    expect(identical(ctx.view, view), isTrue);
    expect(identical(ctx.provinceById, view.provincesById), isTrue);
    expect(identical(ctx.unitsById, game.worldState.allUnitsById), isTrue);
  });
}
