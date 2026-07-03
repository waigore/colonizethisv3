import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('applyTradeInterception', () {
    test('returns as-is when overseasDelivered is empty', () {
      final game = tradeInterceptionGame(defaultRelation: RelationState.atWar);
      final result = applyTradeInterception(game, 'p1', {}, seed: 42);
      expect(result.reducedDelivered, isEmpty);
      expect(result.updatedFleets, game.worldState.fleets);
    });

    test('returns full delivered when no enemies at war', () {
      final game = tradeInterceptionGame();
      final delivered = {CommodityCatalog.grain.id: 10};
      final result = applyTradeInterception(game, 'p1', delivered, seed: 42);
      expect(result.reducedDelivered[CommodityCatalog.grain.id], 10);
      expect(result.updatedFleets, game.worldState.fleets);
    });

    test('returns full delivered when at war but no interceptor fleet', () {
      final game = tradeInterceptionGame(defaultRelation: RelationState.atWar);
      final delivered = {CommodityCatalog.grain.id: 12};
      final result = applyTradeInterception(game, 'p1', delivered, seed: 7);
      expect(result.reducedDelivered[CommodityCatalog.grain.id], 12);
      expect(result.updatedFleets, game.worldState.fleets);
    });

    test('reduces cargo when enemy has patrol fleet', () {
      final game = tradeInterceptionGame(
        defaultRelation: RelationState.atWar,
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p2',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: ['carrack'],
            mission: FleetMission.patrol,
          ),
        ],
      );
      final delivered = {CommodityCatalog.grain.id: 20};
      final result = applyTradeInterception(
        game,
        'p1',
        delivered,
        seed: 12345,
      );
      final reduced = result.reducedDelivered[CommodityCatalog.grain.id];
      expect(reduced, isNotNull);
      expect(reduced!, lessThan(20));
      expect(reduced, greaterThan(0));
    });

    test('is deterministic for a fixed seed', () {
      final game = tradeInterceptionGame(
        defaultRelation: RelationState.atWar,
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p2',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: ['carrack'],
            mission: FleetMission.patrol,
          ),
        ],
      );
      final delivered = {CommodityCatalog.grain.id: 20};
      final a = applyTradeInterception(game, 'p1', delivered, seed: 999);
      final b = applyTradeInterception(game, 'p1', delivered, seed: 999);
      expect(
        a.reducedDelivered[CommodityCatalog.grain.id],
        b.reducedDelivered[CommodityCatalog.grain.id],
      );
    });

    // Slice B of #3470: privateering trade-raid bonus.
    // SPEC/program/naval-movement-resolution.md § Trade/Transport Interception.
    test('enemy without privateering reduces cargo by the baseline', () {
      final game = tradeInterceptionPrivateeringGame(
        enemyHasPrivateering: false,
      );
      final result = applyTradeInterception(
        game,
        'p1',
        {CommodityCatalog.grain.id: 100},
        seed: 42,
      );
      // ratio = 4/7; pCargoEffective ≈ 0.2265 => keep ≈ round(77.35) = 77.
      expect(result.reducedDelivered[CommodityCatalog.grain.id], 77);
    });

    test('enemy with privateering reduces cargo more (strictly less kept)', () {
      final baseline = applyTradeInterception(
        tradeInterceptionPrivateeringGame(enemyHasPrivateering: false),
        'p1',
        {CommodityCatalog.grain.id: 100},
        seed: 42,
      );
      final boosted = applyTradeInterception(
        tradeInterceptionPrivateeringGame(enemyHasPrivateering: true),
        'p1',
        {CommodityCatalog.grain.id: 100},
        seed: 42,
      );
      final keptBaseline = baseline.reducedDelivered[CommodityCatalog.grain.id]!;
      final keptBoosted = boosted.reducedDelivered[CommodityCatalog.grain.id]!;
      // 5/8 ratio => pCargoEffective ≈ 0.2578 => keep ≈ round(74.22) = 74.
      expect(keptBoosted, 74);
      expect(keptBoosted, lessThan(keptBaseline));
    });

    test('privateering trade-raid result is deterministic for a fixed seed', () {
      final a = applyTradeInterception(
        tradeInterceptionPrivateeringGame(enemyHasPrivateering: true),
        'p1',
        {CommodityCatalog.grain.id: 100},
        seed: 999,
      );
      final b = applyTradeInterception(
        tradeInterceptionPrivateeringGame(enemyHasPrivateering: true),
        'p1',
        {CommodityCatalog.grain.id: 100},
        seed: 999,
      );
      expect(
        a.reducedDelivered[CommodityCatalog.grain.id],
        b.reducedDelivered[CommodityCatalog.grain.id],
      );
    });

    test('can remove merchant ships when interception triggers and RNG hits', () {
      final game = tradeInterceptionGame(
        defaultRelation: RelationState.atWar,
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p2',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: ['carrack', 'carrack'],
            mission: FleetMission.blockade,
          ),
          Fleet(
            id: 'f2',
            ownerId: 'p1',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: ['fluyte', 'fluyte', 'fluyte'],
          ),
        ],
      );
      final delivered = {CommodityCatalog.grain.id: 30};
      var shipRemoved = false;
      for (var seed = 0; seed < 500 && !shipRemoved; seed++) {
        final result = applyTradeInterception(
          game,
          'p1',
          delivered,
          seed: seed,
        );
        final p1Fleets = result.updatedFleets
            .where((f) => f.ownerId == 'p1')
            .toList();
        final totalShips = p1Fleets.fold<int>(
          0,
          (s, f) => s + f.shipTypeIds.length,
        );
        if (totalShips < 3) {
          shipRemoved = true;
          expect(result.reducedDelivered, isNotEmpty);
        }
      }
      expect(shipRemoved, isTrue, reason: 'some seed should trigger ship loss');
    });
  });
}
