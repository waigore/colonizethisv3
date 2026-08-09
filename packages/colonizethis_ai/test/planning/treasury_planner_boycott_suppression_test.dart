/// Boycott-aware bid suppression in `runTreasuryPlanner`
/// (Refs #3758 S7/R12; SPEC/ai/treasury-planner.md § Boycott-aware bid
/// suppression).
///
/// When a colony-holding GP boycotts the planning GP, the planner drops bids
/// for commodities the boycotted GP could only source from that colony Tribe.
/// The deal matcher already refuses those trades; suppressing the bid keeps the
/// capped bid slots for fillable commodities.
library;

import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'treasury_planner_satellite_support.dart';

/// Stockpile with every non-riches commodity at a comfortable surplus **except**
/// [kTreasuryBoycottColonyCommodity], so the affluent speculative-bid pass produces exactly one
/// bid need (for [kTreasuryBoycottColonyCommodity]).
Stockpile _stockpileShortOnlyOnColonyCommodity() {
  var stockpile = const Stockpile();
  for (final commodity in CommodityCatalog.all) {
    if (richesCommodityIds.contains(commodity.id)) continue;
    if (commodity.id == kTreasuryBoycottColonyCommodity) continue;
    stockpile = stockpile.applyDelta(
      commodity.id,
      kSpeculativeBidStockpileTarget * 4,
    );
  }
  return stockpile;
}



Map<String, TileMapResult> _tileMaps() => {
  kTreasuryBoycottNw: TileMapResult(
    width: 1,
    height: 1,
    grid: const [
      ['t1'],
    ],
    resourceGrid: const [
      [Resource.furs],
    ],
  ),
};

MapTopology _topology() => const MapTopology(
  nodes: [
    TopologyNode(id: 't1', regionId: kTreasuryBoycottNw, type: TopologyNodeType.province),
  ],
  edges: [],
);

List<TradeOrder> _run(Game game) => runTreasuryPlanner(TreasuryPlannerInput(
  game: game,
  playerId: 'gpC',
  stockpile: game.players.first.stockpile,
  productionAssignments: const [],
  treasury: game.players.first.treasury,
  tileMapByRegion: _tileMaps(),
  topology: _topology(),
));

bool _hasColonyCommodityBid(List<TradeOrder> orders) => orders.any(
  (o) =>
      o.type == TradeOrderType.bid && o.commodityId == kTreasuryBoycottColonyCommodity,
);

void main() {
  group('runTreasuryPlanner boycott-aware bid suppression (Refs #3758 S7)', () {
    final treasury = cheapestRegimentBuildTreasuryCost() + 5000;

    test(
      'emits a bid for the colony commodity when no boycott targets the buyer',
      () {
        final orders = _run(
          treasuryPlannerBoycottSuppressionGame(
            stockpile: _stockpileShortOnlyOnColonyCommodity(),
            treasury: treasury,
          ),
        );
        expect(
          _hasColonyCommodityBid(orders),
          isTrue,
          reason:
              'Without a boycott, the affluent speculative pass should bid for '
              'the only short commodity ($kTreasuryBoycottColonyCommodity).',
        );
      },
    );

    test(
      'suppresses the bid for the colony commodity when the colony holder '
      'boycotts the buyer',
      () {
        final orders = _run(
          treasuryPlannerBoycottSuppressionGame(
            stockpile: _stockpileShortOnlyOnColonyCommodity(),
            treasury: treasury,
            boycottStates: const [
              BoycottState(gpId: 'gpA', targetGpId: 'gpC', sinceTurn: 1),
            ],
          ),
        );
        expect(
          _hasColonyCommodityBid(orders),
          isFalse,
          reason:
              'The boycotting colony Tribe (t1) is the only source of '
              '$kTreasuryBoycottColonyCommodity, so the bid is dropped.',
        );
      },
    );

    test('is deterministic for identical inputs including boycott state', () {
      Game build() => treasuryPlannerBoycottSuppressionGame(
        stockpile: _stockpileShortOnlyOnColonyCommodity(),
        treasury: treasury,
        boycottStates: const [
          BoycottState(gpId: 'gpA', targetGpId: 'gpC', sinceTurn: 1),
        ],
      );
      final a = _run(build());
      final b = _run(build());
      expect(a, equals(b));
    });
  });
}
