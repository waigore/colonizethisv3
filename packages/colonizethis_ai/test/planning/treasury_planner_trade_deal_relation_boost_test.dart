/// Trade-deal relation-boost-aware bid preference in `runTreasuryPlanner`
/// (Refs #3758 S9/R10; SPEC/ai/treasury-planner.md
/// § Trade-deal relation-boost-aware bid preference).
///
/// The planner prefers, among otherwise-admissible buys, the commodity sold by
/// the peace-time below-neutral partner whose completed world-market deal would
/// earn the largest trade-deal relation boost (`+2.0 + 0.2S + 0.4E`). The
/// preferred commodity is passed through the `preferredBidCommodityId` /
/// `preferCommodityId` ordering hint so it is admitted first under the bid-type
/// / cargo / treasury caps; nothing else about emission changes.
///
/// Bid needs are produced via the production-input path: assigning
/// `bronze_from_copper_tin` and `fabric_from_wool` against an empty stockpile
/// creates input deficits for `copper`, `tin` and `wool`. At the embassy
/// bid-type cap the suggester admits candidates in ascending commodity-id
/// order, so by default `copper` is admitted while the later-sorting `tin` /
/// `wool` are dropped; the preference moves a preferred commodity to the front
/// so it is admitted instead.
library;

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/treasury_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _ow = 'oldWorld';
const _gp = 'gpC';

// Raw-material inputs of the assigned recipes. With an empty stockpile they all
// surface as bid needs. At the embassy bid-type cap (3) the suggester admits
// candidates in ascending commodity-id order, so by default `copper` is
// admitted while the later-sorting `tin` / `wool` are dropped. The relation-
// boost preference moves a preferred commodity to the front so it is admitted
// instead.
const _defaultAdmitted = 'copper';
const _defaultDropped = 'tin';
const _defaultDroppedAlt = 'wool';

const _assignments = <AssignedRecipe>[
  AssignedRecipe(recipeId: 'bronze_from_copper_tin', assignedLabour: 4),
  AssignedRecipe(recipeId: 'fabric_from_wool', assignedLabour: 4),
];

TradeOrder _standingOffer(String commodityId) => TradeOrder(
  commodityId: commodityId,
  type: TradeOrderType.offer,
  quantity: 50,
  priority: 5,
);

Game _game({
  required List<MinorNation> minors,
  required Map<String, List<TradeOrder>> standingOffers,
  List<SubsidyState> subsidyStates = const [],
  List<OvertureState> overtureStates = const [],
}) {
  return Game(
    id: 'g_trade_deal_pref',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$_ow|p1', regionId: _ow, ownerId: _gp),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: _gp,
        displayName: 'Castile',
        isHuman: false,
        capitalProvinceId: '$_ow|p1',
        // Empty stockpile: the bronze recipe's copper + tin inputs are an
        // unmet deficit, so both surface as bid needs (F1–F3 input path).
        stockpile: const Stockpile(),
        treasury: cheapestRegimentBuildTreasuryCost() + 50000,
      ),
    ],
    minorNations: minors,
    subsidyStates: subsidyStates,
    overtureStates: overtureStates,
    worldMarketState: WorldMarketState.withDefaultPrices(const {
      _defaultAdmitted: 100,
      _defaultDropped: 100,
      _defaultDroppedAlt: 100,
    }).copyWith(carryForwardOffersByFactionId: standingOffers),
  );
}

/// Embassy with [targetId] (bumps the bid-type cap to 3 so both copper and tin
/// bids can be admitted, and supplies the embassy boost term for [targetId]).
OvertureState _embassy(String targetId) =>
    OvertureState(gpId: _gp, targetId: targetId, stage: OvertureStage.embassy);

AIWorldSnapshot _snapshot(Map<String, DiplomacyRelation> relations) =>
    AIWorldSnapshot(
      playerId: _gp,
      threats: const ThreatSummary(),
      opportunities: const OpportunitySummary(),
      conquest: const ConquestSummary(),
      economy: const EconomySummary(),
      relations: relations,
    );

DiplomacyRelation _rel(
  String other,
  num score, {
  RelationState state = RelationState.atPeace,
}) => DiplomacyRelation(
  factionId1: _gp,
  factionId2: other,
  score: score,
  state: state,
);

List<TradeOrder> _run(Game game, {AIWorldSnapshot? snapshot}) =>
    runTreasuryPlanner(
      game: game,
      playerId: _gp,
      stockpile: game.players.first.stockpile,
      productionAssignments: _assignments,
      treasury: game.players.first.treasury,
      snapshot: snapshot,
    );

bool _hasBid(List<TradeOrder> orders, String commodityId) => orders.any(
  (o) => o.type == TradeOrderType.bid && o.commodityId == commodityId,
);

void main() {
  group(
    'runTreasuryPlanner trade-deal relation-boost bid preference (Refs #3758 S9)',
    () {
      test(
        'admits a below-neutral peace-time partner commodity that the default '
        'cap would otherwise drop',
        () {
          // minorB (score 40, below neutral, at peace) offers the late-sorting
          // commodity (tin) the default cap drops; minorC (score 50, neutral)
          // offers the early-sorting one (copper) the default cap keeps. The
          // preference moves tin to the front so it is admitted instead.
          final game = _game(
            minors: const [MinorNation(id: 'minorB'), MinorNation(id: 'minorC')],
            standingOffers: {
              'minorB': [_standingOffer(_defaultDropped)],
              'minorC': [_standingOffer(_defaultAdmitted)],
            },
            overtureStates: [_embassy('minorB')],
          );
          final withSnapshot = _run(
            game,
            snapshot: _snapshot({
              'minorB': _rel('minorB', 40),
              'minorC': _rel('minorC', 50),
            }),
          );
          final withoutSnapshot = _run(game);
          expect(
            _hasBid(withoutSnapshot, _defaultDropped),
            isFalse,
            reason: 'baseline: $_defaultDropped is dropped at the cap',
          );
          expect(
            _hasBid(withSnapshot, _defaultDropped),
            isTrue,
            reason:
                'preference admits below-neutral minorB commodity '
                '($_defaultDropped)',
          );
        },
      );

      test(
        'prefers the higher trade-deal-boost partner commodity (subsidy + '
        'embassy) over a lower-boost partner commodity',
        () {
          // Both partners are below neutral (score 40) and at peace. minorD
          // carries a 20% subsidy + an embassy (boost 6.4) and offers tin;
          // minorB has neither (boost 2.0) and offers wool. Both sort after the
          // default-admitted copper, so only the preferred one is admitted: the
          // higher-boost minorD's tin, not minorB's wool.
          final game = _game(
            minors: const [MinorNation(id: 'minorD'), MinorNation(id: 'minorB')],
            standingOffers: {
              'minorD': [_standingOffer(_defaultDropped)],
              'minorB': [_standingOffer(_defaultDroppedAlt)],
            },
            subsidyStates: const [
              SubsidyState(payerId: _gp, targetId: 'minorD', percent: 20),
            ],
            overtureStates: [_embassy('minorD')],
          );
          final orders = _run(
            game,
            snapshot: _snapshot({
              'minorD': _rel('minorD', 40),
              'minorB': _rel('minorB', 40),
            }),
          );
          expect(
            _hasBid(orders, _defaultDropped),
            isTrue,
            reason:
                'higher-boost minorD commodity ($_defaultDropped) is admitted',
          );
          expect(
            _hasBid(orders, _defaultDroppedAlt),
            isFalse,
            reason:
                'lower-boost minorB commodity ($_defaultDroppedAlt) is not '
                'preferred',
          );
        },
      );

      test(
        'is a no-op when no at-peace below-neutral partner offers a needed '
        'commodity (identical to a run without the snapshot)',
        () {
          // minorB (would-be qualifier) is at war; minorC is neutral. No partner
          // qualifies, so the preference resolves to null and the default cap
          // order applies unchanged.
          final game = _game(
            minors: const [MinorNation(id: 'minorB'), MinorNation(id: 'minorC')],
            standingOffers: {
              'minorB': [_standingOffer(_defaultDropped)],
              'minorC': [_standingOffer(_defaultAdmitted)],
            },
            overtureStates: [_embassy('minorB')],
          );
          final withSnapshot = _run(
            game,
            snapshot: _snapshot({
              'minorB': _rel('minorB', 40, state: RelationState.atWar),
              'minorC': _rel('minorC', 50),
            }),
          );
          final withoutSnapshot = _run(game);
          expect(
            _hasBid(withSnapshot, _defaultDropped),
            isFalse,
            reason:
                'no qualifying partner: $_defaultDropped stays dropped at cap',
          );
          expect(
            withSnapshot,
            equals(withoutSnapshot),
            reason: 'preference is a no-op without a qualifying partner',
          );
        },
      );

      test('is deterministic for identical inputs', () {
        Game build() => _game(
          minors: const [MinorNation(id: 'minorD'), MinorNation(id: 'minorB')],
          standingOffers: {
            'minorD': [_standingOffer(_defaultDropped)],
            'minorB': [_standingOffer(_defaultDroppedAlt)],
          },
          subsidyStates: const [
            SubsidyState(payerId: _gp, targetId: 'minorD', percent: 20),
          ],
          overtureStates: [_embassy('minorD')],
        );
        Map<String, DiplomacyRelation> relations() => {
          'minorD': _rel('minorD', 40),
          'minorB': _rel('minorB', 40),
        };
        final a = _run(build(), snapshot: _snapshot(relations()));
        final b = _run(build(), snapshot: _snapshot(relations()));
        expect(a, equals(b));
      });
    },
  );
}
