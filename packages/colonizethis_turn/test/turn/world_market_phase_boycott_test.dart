import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/src/turn/phases/world_market_phase.dart';
import 'package:colonizethis_turn/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_turn/src/turn/turn_resolver_config.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

/// Phase-handler integration for the #3753 R6 boycott colony trade embargo.
/// Tribe `tribeT` (a colony of GP `gpA`) offers timber; the boycotted GP `gpB`
/// and a non-boycotted GP `gpD` both bid. The boycott `(gpA, gpB)` blocks the
/// `tribeT ↔ gpB` deal so the supply flows to `gpD`.
///
/// SPEC anchors:
/// - `SPEC/game/diplomacy.md` § GP–Tribe Rules (Boycott).
/// - `SPEC/program/world-market-resolution.md` § Deal matching engine
///   (boycott exclusion).
const _tribeT = 'tribeT';

Game _boycottGame({required bool boycottActive}) {
  return TestFixtures.minimalGame(
    players: const [
      Player(
        id: 'gpA',
        displayName: 'GP A',
        isHuman: false,
        treasury: 1000,
        stockpile: Stockpile.empty,
      ),
      Player(
        id: 'gpB',
        displayName: 'GP B (boycotted)',
        isHuman: false,
        treasury: 1000,
        stockpile: Stockpile.empty,
      ),
      Player(
        id: 'gpD',
        displayName: 'GP D',
        isHuman: false,
        treasury: 1000,
        stockpile: Stockpile.empty,
      ),
    ],
    tribes: const [Tribe(id: _tribeT, displayName: 'Tribe T')],
  ).copyWith(
    colonyStates: const [
      ColonyState(tribeId: _tribeT, colonyOfGpId: 'gpA', sinceTurn: 1),
    ],
    boycottStates: boycottActive
        ? const [BoycottState(gpId: 'gpA', targetGpId: 'gpB', sinceTurn: 1)]
        : const [],
    worldMarketState: WorldMarketState.empty.copyWith(
      prices: const {'timber': 10},
    ),
  );
}

Game _runPhase({
  required Game game,
  required Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
}) {
  final acc = TurnPipelineState(game: game);
  final config = TurnResolverConfig(
    topology: const MapTopology(nodes: [], edges: []),
    orders: Orders(tradeOrdersByPlayerId: tradeOrdersByPlayerId),
  );
  return (worldMarketTurnPhaseHandler(acc, config, 3) as TurnPhaseStepContinue)
      .pipeline
      .game;
}

List<TradeOrder> _offer(int quantity) => [
  TradeOrder(
    commodityId: 'timber',
    type: TradeOrderType.offer,
    quantity: quantity,
    priority: 1,
  ),
];

List<TradeOrder> _bid(int quantity) => [
  TradeOrder(
    commodityId: 'timber',
    type: TradeOrderType.bid,
    quantity: quantity,
    priority: 1,
  ),
];

int _timberOf(Game game, String playerId) =>
    game.players.firstWhere((p) => p.id == playerId).stockpile.quantityOf(
      'timber',
    );

void main() {
  group('worldMarketTurnPhaseHandler — #3753 R6 boycott exclusion', () {
    test('boycotted GP is blocked; supply flows to the non-boycotted GP', () {
      final next = _runPhase(
        game: _boycottGame(boycottActive: true),
        tradeOrdersByPlayerId: {
          // gpB sorts first by faction id but is boycotted; only 5 units exist.
          _tribeT: _offer(5),
          'gpB': _bid(5),
          'gpD': _bid(5),
        },
      );

      expect(_timberOf(next, 'gpB'), 0);
      expect(_timberOf(next, 'gpD'), 5);
    });

    test('without a boycott the same orders fill for the (now) target GP', () {
      final next = _runPhase(
        game: _boycottGame(boycottActive: false),
        tradeOrdersByPlayerId: {
          _tribeT: _offer(5),
          'gpB': _bid(5),
          'gpD': _bid(5),
        },
      );

      // No boycott: default ascending-faction-id ordering serves gpB first.
      expect(_timberOf(next, 'gpB'), 5);
      expect(_timberOf(next, 'gpD'), 0);
    });
  });
}
