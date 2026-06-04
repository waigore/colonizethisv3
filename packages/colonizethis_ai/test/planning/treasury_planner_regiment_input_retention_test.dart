/// Lock-recovery seller produced build-input retention
/// (Refs #2847 § H8-extraction).
///
/// The feedstock reservation (treasury-planner.md § Build-input feedstock
/// reservation) keeps the recipe feedstock (`wool` / `cotton`) from being sold
/// so a `fabric` run becomes feasible, and the economy-planner production boost
/// then runs that recipe. But the **produced build input** (`fabric`) is itself
/// an offerable commodity: a recovered below-quota zero-NW lock-recovery seller
/// is a strong-cargo Path-F seller that offers its surplus urgently every turn,
/// so the `fabric` the boost just produced is sold back into the world market
/// before it can accumulate to the `peasant_levies` build cost. These tests pin
/// the narrow offer-side carve-out that withholds the produced `fabric` build
/// input from the offer set while — and only while — the zero-regiment rebuild
/// carve-out is active.
library;

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _fabricId = 'fabric';
const _woolId = 'wool';

Game _lockRecoverySellerGame({
  required int treasury,
  required int fabricHeld,
  int woolHeld = 20,
  int owProvinces = 3,
  bool hasRegiment = false,
}) {
  const ow = 'oldWorld';
  var stockpile = const Stockpile().applyDelta('grain', 80);
  if (woolHeld > 0) {
    stockpile = stockpile.applyDelta(_woolId, woolHeld);
  }
  if (fabricHeld > 0) {
    stockpile = stockpile.applyDelta(_fabricId, fabricHeld);
  }
  return Game(
    id: 'g-regiment-input-retention',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < owProvinces; i++)
            Province(id: '$ow|p_$i', regionId: ow, ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      armies: [
        if (hasRegiment)
          const Army(
            id: 'army-gp1-field',
            ownerId: 'gp1',
            regionId: ow,
            stationedProvinceId: '$ow|p_0',
            regimentUnitIds: ['reg-1'],
          ),
      ],
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: '$ow|p_0',
        stockpile: stockpile,
        treasury: treasury,
      ),
    ],
    worldMarketState: WorldMarketState.withDefaultPrices(const {
      'grain': 10,
      _woolId: 20,
      _fabricId: 40,
    }),
  );
}

List<TradeOrder> _run(Game game) => runTreasuryPlanner(
      game: game,
      playerId: 'gp1',
      stockpile: game.players.first.stockpile,
      productionAssignments: const [],
      treasury: game.players.first.treasury,
    );

List<TradeOrder> _fabricOffers(List<TradeOrder> orders) => orders
    .where((o) => o.type == TradeOrderType.offer && o.commodityId == _fabricId)
    .toList();

void main() {
  group(
      'lock-recovery seller produced build-input retention '
      '(Refs #2847 H8-extraction)', () {
    final threshold = cheapestRegimentBuildTreasuryCost();
    // A large surplus the seller would otherwise offer absent the retention.
    const surplusFabric = 60;

    test('fabric is a peasant_levies build input (guards the fixture)', () {
      expect(
        RegimentEconomyCatalog.peasantLevies.buildInputs.containsKey(_fabricId),
        isTrue,
        reason:
            'This slice assumes the cheapest regiment consumes fabric, which '
            'the lock-recovery seller produces domestically.',
      );
    });

    test(
      'recovered-treasury seller with zero regiments withholds its surplus '
      'fabric from offers',
      () {
        final game = _lockRecoverySellerGame(
          treasury: threshold,
          fabricHeld: surplusFabric,
        );
        expect(
          _fabricOffers(_run(game)),
          isEmpty,
          reason:
              'The domestically produced build input must be retained so it '
              'accumulates to the peasant_levies build cost rather than being '
              'sold back into the world market as surplus.',
        );
      },
    );

    test('seller still below the regiment threshold keeps offering fabric', () {
      // The retention shares the bootstrap gate: a broke seller is not yet
      // rebuilding, so it keeps selling its surplus for liquidity.
      final game = _lockRecoverySellerGame(
        treasury: threshold - 1,
        fabricHeld: surplusFabric,
      );
      expect(
        _fabricOffers(_run(game)),
        isNotEmpty,
        reason:
            'A still-broke seller keeps selling surplus for liquidity; the '
            'retention only applies once treasury recovers.',
      );
    });

    test('seller that already holds a regiment keeps offering fabric', () {
      final game = _lockRecoverySellerGame(
        treasury: threshold,
        fabricHeld: surplusFabric,
        hasRegiment: true,
      );
      expect(
        _fabricOffers(_run(game)),
        isNotEmpty,
        reason: 'The retention targets the zero-regiment rebuild gap only.',
      );
    });

    test('quota-met (non-seller) GP above threshold keeps offering fabric', () {
      // owProvinces >= 10 lifts the GP out of the below-quota seller band.
      final game = _lockRecoverySellerGame(
        treasury: threshold,
        fabricHeld: surplusFabric,
        owProvinces: 12,
      );
      expect(
        _fabricOffers(_run(game)),
        isNotEmpty,
        reason: 'The retention is scoped to below-quota zero-NW sellers.',
      );
    });

    test('build-input retention path is deterministic', () {
      final game = _lockRecoverySellerGame(
        treasury: threshold,
        fabricHeld: surplusFabric,
      );
      expect(_run(game), equals(_run(game)));
    });
  });
}
