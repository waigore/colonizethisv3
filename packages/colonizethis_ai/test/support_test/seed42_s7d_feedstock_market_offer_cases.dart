// Case bodies for seed42_s7d_feedstock_helpers_test market-offer pins
// (Refs #3997 Phase 8).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/seed42_s7d_feedstock_helpers.dart';

void registerSeed42S7dFeedstockMarketOfferCases() {
  final timberId = CommodityCatalog.timber.id;
  final ironId = CommodityCatalog.iron.id;

  group('recordSeed42S7dCastIronMarketOfferCounters', () {
    final castIronId = CommodityCatalog.castIron.id;

    TradeOrder offer(String id) => TradeOrder(
      commodityId: id,
      type: TradeOrderType.offer,
      quantity: 1,
      priority: 1,
    );
    TradeOrder bid(String id) => TradeOrder(
      commodityId: id,
      type: TradeOrderType.bid,
      quantity: 1,
      priority: 1,
    );

    test(
      'positive: another faction offers castIron => present bumped, absent not',
      () {
        final present = <String, int>{'gp3': 0};
        final absent = <String, int>{'gp3': 0};
        recordSeed42S7dCastIronMarketOfferCounters(
          feedstockGateActiveThisTurn: {'gp3'},
          tradeOrdersByPlayerId: {
            'gp1': [offer(castIronId)],
            'gp3': [bid(castIronId)],
          },
          castIronCommodityId: castIronId,
          presentTurns: present,
          absentTurns: absent,
        );
        expect(present['gp3'], 1);
        expect(absent['gp3'], 0);
      },
    );

    test(
      'negative: no other faction offers castIron (only own offer + others\' '
      'bids / unrelated offers) => absent bumped, present not',
      () {
        final present = <String, int>{'gp3': 0};
        final absent = <String, int>{'gp3': 0};
        recordSeed42S7dCastIronMarketOfferCounters(
          feedstockGateActiveThisTurn: {'gp3'},
          tradeOrdersByPlayerId: {
            // The seller's own castIron offer must not count as supply.
            'gp3': [offer(castIronId)],
            // Other GPs bid castIron (demand, not supply) or offer a
            // different commodity — neither is releasable castIron supply.
            'gp1': [bid(castIronId), offer(timberId)],
            'gp2': [offer(ironId)],
          },
          castIronCommodityId: castIronId,
          presentTurns: present,
          absentTurns: absent,
        );
        expect(present['gp3'], 0);
        expect(absent['gp3'], 1);
      },
    );

    test('gates strictly on the active set — inactive GPs are untouched', () {
      final present = <String, int>{'gp3': 0, 'gp4': 0};
      final absent = <String, int>{'gp3': 0, 'gp4': 0};
      recordSeed42S7dCastIronMarketOfferCounters(
        feedstockGateActiveThisTurn: {'gp3'},
        tradeOrdersByPlayerId: {
          'gp1': [offer(castIronId)],
        },
        castIronCommodityId: castIronId,
        presentTurns: present,
        absentTurns: absent,
      );
      expect(present['gp3'], 1);
      expect(present['gp4'], 0);
      expect(absent['gp4'], 0);
    });
  });

  group('recordSeed42S7dFabricMarketOfferCounters (Refs #2847)', () {
    final fabricId = CommodityCatalog.fabric.id;

    TradeOrder offer(String id) => TradeOrder(
      commodityId: id,
      type: TradeOrderType.offer,
      quantity: 1,
      priority: 1,
    );
    TradeOrder bid(String id) => TradeOrder(
      commodityId: id,
      type: TradeOrderType.bid,
      quantity: 1,
      priority: 1,
    );

    test(
      'positive: another faction offers fabric => present bumped, absent not',
      () {
        final present = <String, int>{'gp3': 0};
        final absent = <String, int>{'gp3': 0};
        recordSeed42S7dFabricMarketOfferCounters(
          fabricMarketPathActiveThisTurn: {'gp3'},
          tradeOrdersByPlayerId: {
            'gp1': [offer(fabricId)],
            'gp3': [bid(fabricId)],
          },
          presentTurns: present,
          absentTurns: absent,
        );
        expect(present['gp3'], 1);
        expect(absent['gp3'], 0);
      },
    );

    test(
      'negative: no other faction offers fabric => absent bumped, present not',
      () {
        final present = <String, int>{'gp3': 0};
        final absent = <String, int>{'gp3': 0};
        recordSeed42S7dFabricMarketOfferCounters(
          fabricMarketPathActiveThisTurn: {'gp3'},
          tradeOrdersByPlayerId: {
            'gp3': [offer(fabricId)],
            'gp1': [bid(fabricId)],
            'gp2': [offer(CommodityCatalog.timber.id)],
          },
          presentTurns: present,
          absentTurns: absent,
        );
        expect(present['gp3'], 0);
        expect(absent['gp3'], 1);
      },
    );

    test('gates strictly on the active set — inactive GPs are untouched', () {
      final present = <String, int>{'gp3': 0, 'gp5': 0};
      final absent = <String, int>{'gp3': 0, 'gp5': 0};
      recordSeed42S7dFabricMarketOfferCounters(
        fabricMarketPathActiveThisTurn: {'gp3'},
        tradeOrdersByPlayerId: {
          'gp2': [offer(fabricId)],
        },
        presentTurns: present,
        absentTurns: absent,
      );
      expect(present['gp3'], 1);
      expect(present['gp5'], 0);
      expect(absent['gp5'], 0);
    });
  });

  group('recordSeed42S7dOtherFactionOfferCounters (shared, Refs #3749)', () {
    final timberCommodityId = CommodityCatalog.timber.id;

    TradeOrder offer(String id) => TradeOrder(
      commodityId: id,
      type: TradeOrderType.offer,
      quantity: 1,
      priority: 1,
    );
    TradeOrder bid(String id) => TradeOrder(
      commodityId: id,
      type: TradeOrderType.bid,
      quantity: 1,
      priority: 1,
    );

    test(
      'positive: another faction offers the commodity => present bumped',
      () {
        final present = <String, int>{'gp3': 0};
        final absent = <String, int>{'gp3': 0};
        recordSeed42S7dOtherFactionOfferCounters(
          activeThisTurn: {'gp3'},
          tradeOrdersByPlayerId: {
            'gp1': [offer(timberCommodityId)],
            'gp3': [bid(timberCommodityId)],
          },
          commodityId: timberCommodityId,
          presentTurns: present,
          absentTurns: absent,
        );
        expect(present['gp3'], 1);
        expect(absent['gp3'], 0);
      },
    );

    test(
      'negative: own offer + others\' bids/unrelated offers => absent bumped',
      () {
        final present = <String, int>{'gp3': 0};
        final absent = <String, int>{'gp3': 0};
        recordSeed42S7dOtherFactionOfferCounters(
          activeThisTurn: {'gp3'},
          tradeOrdersByPlayerId: {
            'gp3': [offer(timberCommodityId)],
            'gp1': [bid(timberCommodityId)],
            'gp2': [offer(ironId)],
          },
          commodityId: timberCommodityId,
          presentTurns: present,
          absentTurns: absent,
        );
        expect(present['gp3'], 0);
        expect(absent['gp3'], 1);
      },
    );
  });
}
