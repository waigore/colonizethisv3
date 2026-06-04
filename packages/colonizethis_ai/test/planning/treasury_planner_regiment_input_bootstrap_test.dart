/// Lock-recovery seller regiment build-input bootstrap (Refs #2847 § H8).
///
/// A below-quota zero-NW lock-recovery seller accumulates treasury by selling
/// food but its bid `need` is otherwise cleared every turn, so it can never
/// buy the cheapest regiment's build-input commodity. `peasant_levies` (the
/// universal cheapest regiment) requires its `buildInputs` commodities in the
/// stockpile, so a seller that has recovered treasury to/above the
/// regiment threshold yet holds zero of those inputs and zero regiments stays
/// trapped — `suggestBuildOrders` returns no regiment candidate. These tests
/// pin the narrow carve-out that lets such a seller emit a single build-input
/// bid so the recovered treasury can convert into the army it was recovering
/// for.
library;

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _fabricId = 'fabric';

Game _lockRecoverySellerGame({
  required int treasury,
  required int fabricHeld,
  int owProvinces = 3,
  bool hasRegiment = false,
  bool zeroNewWorld = true,
}) {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  var stockpile = const Stockpile().applyDelta('grain', 80);
  if (fabricHeld > 0) {
    stockpile = stockpile.applyDelta(_fabricId, fabricHeld);
  }
  return Game(
    id: 'g-regiment-input-bootstrap',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < owProvinces; i++)
            Province(id: '$ow|p_$i', regionId: ow, ownerId: 'gp1'),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          if (!zeroNewWorld) Province(id: '$nw|n_0', regionId: nw, ownerId: 'gp1'),
        ],
      ),
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
      'timber': 20,
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

void main() {
  group('lock-recovery seller regiment build-input bootstrap (Refs #2847 H8)', () {
    final threshold = cheapestRegimentBuildTreasuryCost();
    final fabricInput =
        RegimentEconomyCatalog.peasantLevies.buildInputs[_fabricId];

    test('peasant_levies requires fabric (guards the fixture assumption)', () {
      expect(
        fabricInput,
        isNotNull,
        reason:
            'This slice assumes the cheapest regiment consumes fabric; if the '
            'catalog changes, the carve-out and these tests must follow.',
      );
      expect(fabricInput, greaterThan(0));
    });

    test(
      'recovered-treasury seller holding zero fabric and zero regiments '
      'emits a fabric build-input bid',
      () {
        final game = _lockRecoverySellerGame(
          treasury: threshold,
          fabricHeld: 0,
        );
        final bids =
            _run(game).where((o) => o.type == TradeOrderType.bid).toList();
        final fabricBids =
            bids.where((o) => o.commodityId == _fabricId).toList();
        expect(
          fabricBids,
          isNotEmpty,
          reason:
              'A seller above the regiment threshold with no regiment and no '
              'fabric must bid for the missing regiment build input.',
        );
        expect(fabricBids.first.quantity, greaterThanOrEqualTo(fabricInput!));
      },
    );

    test('seller still below the regiment threshold emits no fabric bid', () {
      final game = _lockRecoverySellerGame(
        treasury: threshold - 1,
        fabricHeld: 0,
      );
      final fabricBids = _run(game)
          .where((o) =>
              o.type == TradeOrderType.bid && o.commodityId == _fabricId)
          .toList();
      expect(
        fabricBids,
        isEmpty,
        reason:
            'A broke seller must keep accumulating credits, not spend them on '
            'the build input before it can afford the regiment itself.',
      );
    });

    test('seller already holding the fabric input emits no fabric bid', () {
      final game = _lockRecoverySellerGame(
        treasury: threshold,
        fabricHeld: fabricInput!,
      );
      final fabricBids = _run(game)
          .where((o) =>
              o.type == TradeOrderType.bid && o.commodityId == _fabricId)
          .toList();
      expect(
        fabricBids,
        isEmpty,
        reason:
            'Once the build input is on hand the carve-out clears; the build '
            'pipeline can emit the regiment without a redundant bid.',
      );
    });

    test('seller that already holds a regiment emits no fabric bid', () {
      final game = _lockRecoverySellerGame(
        treasury: threshold,
        fabricHeld: 0,
        hasRegiment: true,
      );
      final fabricBids = _run(game)
          .where((o) =>
              o.type == TradeOrderType.bid && o.commodityId == _fabricId)
          .toList();
      expect(
        fabricBids,
        isEmpty,
        reason: 'The bootstrap targets the zero-regiment rebuild gap only.',
      );
    });

    test('quota-met (non-seller) GP above threshold emits no bootstrap bid', () {
      // owProvinces >= 10 lifts the GP out of the below-quota seller band, so
      // the lock-recovery seller carve-out does not apply.
      final game = _lockRecoverySellerGame(
        treasury: threshold,
        fabricHeld: 0,
        owProvinces: 12,
      );
      final fabricBids = _run(game)
          .where((o) =>
              o.type == TradeOrderType.bid && o.commodityId == _fabricId)
          .toList();
      expect(fabricBids, isEmpty);
    });
  });
}
