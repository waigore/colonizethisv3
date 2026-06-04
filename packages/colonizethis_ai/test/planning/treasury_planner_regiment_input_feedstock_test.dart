/// Lock-recovery seller build-input feedstock reservation
/// (Refs #2847 § H8-supply).
///
/// The H8 bootstrap bid creates demand for the cheapest regiment's missing
/// build input (`fabric`), but on seed 42 no world-market seller offers
/// `fabric`, so the recovered seller must produce it domestically from `wool`
/// or `cotton`. A lock-recovery seller otherwise sells that feedstock as
/// surplus every turn, so it never accumulates to a feasible fabric run and the
/// economy planner's build-input production boost has nothing to convert. These
/// tests pin the narrow offer-side carve-out that withholds the fabric feedstock
/// from the offer set while — and only while — the zero-regiment rebuild
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
    id: 'g-regiment-input-feedstock',
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

List<TradeOrder> _woolOffers(List<TradeOrder> orders) => orders
    .where((o) => o.type == TradeOrderType.offer && o.commodityId == _woolId)
    .toList();

void main() {
  group('lock-recovery seller build-input feedstock reservation (Refs #2847 H8-supply)',
      () {
    final threshold = cheapestRegimentBuildTreasuryCost();
    final fabricInput =
        RegimentEconomyCatalog.peasantLevies.buildInputs[_fabricId];

    test('fabric is produced from wool/cotton (guards the fixture assumption)',
        () {
      expect(
        fabricInput,
        isNotNull,
        reason:
            'This slice assumes the cheapest regiment consumes fabric and that '
            'fabric is produced from a feedstock recipe.',
      );
      final fabricFeedstock = ProductionRecipesCatalog.all
          .where((r) => r.outputCommodityId == _fabricId)
          .expand((r) => r.inputQuantities.keys)
          .toSet();
      expect(
        fabricFeedstock,
        contains(_woolId),
        reason: 'A fabric recipe must consume wool for this fixture to hold.',
      );
    });

    test(
      'recovered-treasury seller with zero fabric and zero regiments '
      'withholds its surplus wool from offers',
      () {
        final game = _lockRecoverySellerGame(
          treasury: threshold,
          fabricHeld: 0,
        );
        expect(
          _woolOffers(_run(game)),
          isEmpty,
          reason:
              'The feedstock for the missing fabric build input must be '
              'retained so it accumulates to a feasible production run rather '
              'than being sold as surplus.',
        );
      },
    );

    test(
      'still-broke zero-regiment seller withholds wool (treasury-independent '
      'staging, Refs #2847 H8 production allocation)',
      () {
        // The economy planner produces fabric ahead of treasury recovery, so
        // the feedstock must be retained even while broke — otherwise the
        // wool / cotton is sold every broke turn and the fabric recipe never
        // reaches a feasible run.
        final game = _lockRecoverySellerGame(
          treasury: threshold - 1,
          fabricHeld: 0,
        );
        expect(
          _woolOffers(_run(game)),
          isEmpty,
          reason:
              'A broke zero-regiment lock-recovery seller stages feedstock: the '
              'wool is retained so it accumulates to a feasible fabric run.',
        );
      },
    );

    test('seller already holding the fabric input keeps offering wool', () {
      final game = _lockRecoverySellerGame(
        treasury: threshold,
        fabricHeld: fabricInput!,
      );
      expect(
        _woolOffers(_run(game)),
        isNotEmpty,
        reason:
            'Once the build input is on hand the reservation self-clears and '
            'the seller resumes offering its surplus feedstock.',
      );
    });

    test('seller that already holds a regiment keeps offering wool', () {
      final game = _lockRecoverySellerGame(
        treasury: threshold,
        fabricHeld: 0,
        hasRegiment: true,
      );
      expect(
        _woolOffers(_run(game)),
        isNotEmpty,
        reason: 'The reservation targets the zero-regiment rebuild gap only.',
      );
    });

    test('quota-met (non-seller) GP above threshold keeps offering wool', () {
      // owProvinces >= 10 lifts the GP out of the below-quota seller band.
      final game = _lockRecoverySellerGame(
        treasury: threshold,
        fabricHeld: 0,
        owProvinces: 12,
      );
      expect(_woolOffers(_run(game)), isNotEmpty);
    });

    test('feedstock-reservation path is deterministic', () {
      final game = _lockRecoverySellerGame(treasury: threshold, fabricHeld: 0);
      expect(_run(game), equals(_run(game)));
    });
  });
}
