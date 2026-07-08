// Compact trade interception assertions (Refs #3939 phase 3 slice 37).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';
import 'trade_interception_scenarios.dart';

Fleet _patrolFleet({String id = 'f1'}) => Fleet(
      id: id,
      ownerId: 'p2',
      seaZoneId: 'sea1',
      regionId: 'oldWorld',
      shipTypeIds: const ['carrack'],
      mission: FleetMission.patrol,
    );

/// Pins for [applyTradeInterception] rows.
enum ApplyTradeInterceptionTarget {
  emptyOverseas,
  noEnemiesAtWar,
  atWarNoInterceptor,
  enemyPatrolReduces,
  deterministicSeed,
  privateeringBaseline,
  privateeringBoosted,
  privateeringDeterministic,
  shipRemovalLoop,
}

void runApplyTradeInterceptionExpectation(ApplyTradeInterceptionTarget target) {
  switch (target) {
    case ApplyTradeInterceptionTarget.emptyOverseas:
      final game =
          tradeInterceptionGame(defaultRelation: RelationState.atWar);
      final result = applyTradeInterception(game, 'p1', {}, seed: 42);
      expect(result.reducedDelivered, isEmpty);
      expect(result.updatedFleets, game.worldState.fleets);
    case ApplyTradeInterceptionTarget.noEnemiesAtWar:
      final game = tradeInterceptionGame();
      final delivered = {CommodityCatalog.grain.id: 10};
      final result = applyTradeInterception(game, 'p1', delivered, seed: 42);
      expect(result.reducedDelivered[CommodityCatalog.grain.id], 10);
      expect(result.updatedFleets, game.worldState.fleets);
    case ApplyTradeInterceptionTarget.atWarNoInterceptor:
      final game =
          tradeInterceptionGame(defaultRelation: RelationState.atWar);
      final delivered = {CommodityCatalog.grain.id: 12};
      final result = applyTradeInterception(game, 'p1', delivered, seed: 7);
      expect(result.reducedDelivered[CommodityCatalog.grain.id], 12);
      expect(result.updatedFleets, game.worldState.fleets);
    case ApplyTradeInterceptionTarget.enemyPatrolReduces:
      final game = tradeInterceptionGame(
        defaultRelation: RelationState.atWar,
        fleets: [_patrolFleet()],
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
    case ApplyTradeInterceptionTarget.deterministicSeed:
      final game = tradeInterceptionGame(
        defaultRelation: RelationState.atWar,
        fleets: [_patrolFleet()],
      );
      final delivered = {CommodityCatalog.grain.id: 20};
      final a = applyTradeInterception(game, 'p1', delivered, seed: 999);
      final b = applyTradeInterception(game, 'p1', delivered, seed: 999);
      expect(
        a.reducedDelivered[CommodityCatalog.grain.id],
        b.reducedDelivered[CommodityCatalog.grain.id],
      );
    case ApplyTradeInterceptionTarget.privateeringBaseline:
      final game =
          tradeInterceptionPrivateeringGame(enemyHasPrivateering: false);
      final result = applyTradeInterception(
        game,
        'p1',
        {CommodityCatalog.grain.id: 100},
        seed: 42,
      );
      expect(result.reducedDelivered[CommodityCatalog.grain.id], 77);
    case ApplyTradeInterceptionTarget.privateeringBoosted:
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
      final keptBaseline =
          baseline.reducedDelivered[CommodityCatalog.grain.id]!;
      final keptBoosted = boosted.reducedDelivered[CommodityCatalog.grain.id]!;
      expect(keptBoosted, 74);
      expect(keptBoosted, lessThan(keptBaseline));
    case ApplyTradeInterceptionTarget.privateeringDeterministic:
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
    case ApplyTradeInterceptionTarget.shipRemovalLoop:
      final game = tradeInterceptionGame(
        defaultRelation: RelationState.atWar,
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p2',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: const ['carrack', 'carrack'],
            mission: FleetMission.blockade,
          ),
          Fleet(
            id: 'f2',
            ownerId: 'p1',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: const ['fluyte', 'fluyte', 'fluyte'],
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
  }
}

ApplyTradeInterceptionScenario applyTradeInterceptionScenario({
  required String label,
  required ApplyTradeInterceptionTarget target,
  String? refs,
}) =>
    ApplyTradeInterceptionScenario(
      label: label,
      run: () => runApplyTradeInterceptionExpectation(target),
      refs: refs,
    );

/// Pins for [scanTradeInterceptionInputs] rows.
enum TradeInterceptionScanTarget {
  noEnemyPatrol,
  merchantEscortCount,
  enemyBlockade,
  privateeringScales,
}

void runTradeInterceptionScanExpectation(TradeInterceptionScanTarget target) {
  switch (target) {
    case TradeInterceptionScanTarget.noEnemyPatrol:
      final scan = scanTradeInterceptionInputs(
        [
          tradeInterceptionScanFleet(
            ownerId: 'p1',
            shipTypeIds: const ['fluyte'],
          ),
        ],
        const <String>{'p2'},
        'p1',
        const <String>{},
      );
      expect(scan.interceptScore, 0.0);
      expect(scan.hasBlockade, isFalse);
      expect(scan.playerMerchantShips, 1);
    case TradeInterceptionScanTarget.merchantEscortCount:
      final scan = scanTradeInterceptionInputs(
        [
          tradeInterceptionScanFleet(
            ownerId: 'p1',
            shipTypeIds: const ['fluyte', 'carrack'],
          ),
          tradeInterceptionScanFleet(
            ownerId: 'p1',
            shipTypeIds: const ['sloop'],
          ),
        ],
        const <String>{'p2'},
        'p1',
        const <String>{},
      );
      expect(scan.playerMerchantShips, 2);
      expect(scan.escortStrength, greaterThan(0.0));
      expect(
        kMerchantShipTypeIds,
        containsAll(<String>{'fluyte', 'carrack'}),
      );
    case TradeInterceptionScanTarget.enemyBlockade:
      final scan = scanTradeInterceptionInputs(
        [
          tradeInterceptionScanFleet(
            ownerId: 'p2',
            shipTypeIds: const ['sloop'],
            mission: FleetMission.blockade,
          ),
        ],
        const <String>{'p2'},
        'p1',
        const <String>{},
      );
      expect(scan.hasBlockade, isTrue);
      expect(scan.interceptScore, greaterThan(0.0));
    case TradeInterceptionScanTarget.privateeringScales:
      List<Fleet> enemyPatrol() => [
            tradeInterceptionScanFleet(
              ownerId: 'p2',
              shipTypeIds: const ['sloop'],
            ),
          ];
      final baseline = scanTradeInterceptionInputs(
        enemyPatrol(),
        const <String>{'p2'},
        'p1',
        const <String>{},
      );
      final boosted = scanTradeInterceptionInputs(
        enemyPatrol(),
        const <String>{'p2'},
        'p1',
        const <String>{'p2'},
      );
      expect(baseline.interceptScore, greaterThan(0.0));
      expect(
        boosted.interceptScore,
        closeTo(
          baseline.interceptScore * kPrivateeringTradeRaidBonus,
          1e-9,
        ),
      );
  }
}

TradeInterceptionScanScenario tradeInterceptionScanScenario({
  required String label,
  required TradeInterceptionScanTarget target,
  String? refs,
}) =>
    TradeInterceptionScanScenario(
      label: label,
      run: () => runTradeInterceptionScanExpectation(target),
      refs: refs,
    );
