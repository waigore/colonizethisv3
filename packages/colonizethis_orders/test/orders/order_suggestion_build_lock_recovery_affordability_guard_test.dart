import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

/// Lock-recovery affordability regression guards (Refs #2924).
///
/// Issue #2924 rescopes lock recovery to legitimate economic paths (World
/// Market sales / NW acquisition) and explicitly rejects any "train regiments
/// without treasury" bypass as cheating. These tests pin the affordability
/// contract that the lock-recovery work must never weaken:
///
/// - No AI exemption: a broke GP (`treasury < cheapestRegimentBuildTreasuryCost`)
///   with no riches-to-treasury inflow gets **zero** regiment build candidates
///   from `suggestBuildOrders`.
/// - No human waiver: a human player at `treasury == 0` is treated identically;
///   the normal build-validation path rejects the regiment build.
///
/// SPEC:
/// - `SPEC/program/orders.md` § `BuildOrderValidator` (affordability via
///   `ProjectedCostEngine`; no AI exemption documented or permitted).
/// - `SPEC/program/order-suggestions.md` § Build orders (only validator-accepted
///   candidates are surfaced).
const _topology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [],
);

/// Game with one owned province whose owner has zero treasury, fabric (the
/// peasant_levies build input) and peasants for labour, but **no riches** in
/// the stockpile, so no riches-to-treasury phase can fund a regiment build.
Game _brokeNoRichesGame({required bool isHuman}) {
  final base = TestFixtures.gameWithSingleOwnedProvince(
    ownerPlayerId: 'p1',
    provinceId: 'oldWorld|p1',
    treasury: 0,
    isHuman: isHuman,
  );
  final player = base.players.single;
  return base.copyWith(
    players: [
      player.copyWith(
        stockpile: const Stockpile().applyDelta(CommodityCatalog.fabric.id, 5),
        workerPool: const WorkerPool(peasants: 5),
      ),
    ],
  );
}

bool _isRegimentBuild(Object order) {
  if (order is! BuildUnitOrder) return false;
  return RegimentEconomyCatalog.byId.containsKey(order.unitType);
}

void main() {
  group('suggestBuildOrders lock-recovery affordability guard (Refs #2924)', () {
    test(
        'positive control: a broke GP with riches CAN train the cheapest '
        'regiment (proves the negative guard is non-vacuous)', () {
      final base = TestFixtures.gameWithSingleOwnedProvince(
        ownerPlayerId: 'p1',
        provinceId: 'oldWorld|p1',
        treasury: 0,
        isHuman: false,
      );
      final player = base.players.single;
      final game = base.copyWith(
        players: [
          player.copyWith(
            stockpile: const Stockpile()
                .applyDelta(CommodityCatalog.spices.id, 50)
                .applyDelta(CommodityCatalog.fabric.id, 5),
            workerPool: const WorkerPool(peasants: 5),
          ),
        ],
      );
      final view = buildPlayerView(game, _topology, 'p1');

      final suggestions =
          suggestBuildOrders(view, game, _topology, const Orders());

      expect(
        suggestions.map((o) => o.unitType),
        contains('peasant_levies'),
        reason: 'pending riches-to-treasury should fund the cheapest regiment',
      );
    });

    test(
        'affordability regression guard: AI GP at treasury 0 with no riches '
        'gets zero regiment build candidates (no AI bypass)', () {
      final game = _brokeNoRichesGame(isHuman: false);
      final view = buildPlayerView(game, _topology, 'p1');

      // Precondition: treasury is below the cheapest regiment build cost.
      expect(
        game.players.single.treasury,
        lessThan(cheapestRegimentBuildTreasuryCost()),
      );

      final suggestions =
          suggestBuildOrders(view, game, _topology, const Orders());

      expect(
        suggestions.where(_isRegimentBuild),
        isEmpty,
        reason:
            'no regiment may be suggested when treasury < cheapest build cost '
            'and there is no riches-to-treasury inflow (no affordability bypass)',
      );
    });

    test(
        'human-player guard: human at treasury 0 with no riches gets zero '
        'regiment suggestions (no human waiver)', () {
      final game = _brokeNoRichesGame(isHuman: true);
      final view = buildPlayerView(game, _topology, 'p1');

      final suggestions =
          suggestBuildOrders(view, game, _topology, const Orders());

      expect(suggestions.where(_isRegimentBuild), isEmpty);
    });

    test(
        'human-player guard: the build-validation path rejects a human regiment '
        'build at treasury 0 (UI submission path, no waiver)', () {
      final game = _brokeNoRichesGame(isHuman: true);
      const candidate = BuildUnitOrder(
        unitType: 'peasant_levies',
        isMilitary: true,
        spawnProvinceId: 'oldWorld|p1',
      );

      final result = OrderEngine(initialOrders: const Orders())
          .addBuildOrderWithContext(game, _topology, 'p1', candidate);

      expect(
        result.isAccepted,
        isFalse,
        reason: 'no waiver path may accept a regiment build at zero treasury '
            'for any player, human or AI',
      );
    });
  });
}
