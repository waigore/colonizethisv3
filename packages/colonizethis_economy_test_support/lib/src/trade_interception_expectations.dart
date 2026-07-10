// dart format off
// Compact trade interception assertions (Refs #3939 phase 3 slice 37 / 65).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';
import 'trade_interception_scenarios.dart';

Fleet _patrolFleet({String id = 'f1'}) => Fleet(id: id, ownerId: 'p2', seaZoneId: 'sea1', regionId: 'oldWorld', shipTypeIds: const ['carrack'], mission: FleetMission.patrol);

TradeInterceptionResult _apply({required Game game, Map<String, int> delivered = const {}, int seed = 42}) => applyTradeInterception(game, 'p1', delivered, seed: seed);

void _expectUnchanged(TradeInterceptionResult result, Game game, Map<String, int> delivered) {
  for (final entry in delivered.entries) {
    expect(result.reducedDelivered[entry.key], entry.value);
  }
  if (delivered.isEmpty) {
    expect(result.reducedDelivered, isEmpty);
  }
  expect(result.updatedFleets, game.worldState.fleets);
}

/// Pins for [applyTradeInterception] rows.
enum ApplyTradeInterceptionTarget { emptyOverseas, noEnemiesAtWar, atWarNoInterceptor, enemyPatrolReduces, deterministicSeed, privateeringBaseline, privateeringBoosted, privateeringDeterministic, shipRemovalLoop }

void runApplyTradeInterceptionExpectation(ApplyTradeInterceptionTarget target) {
  switch (target) {
    case ApplyTradeInterceptionTarget.emptyOverseas:
      final game = tradeInterceptionGame(defaultRelation: RelationState.atWar);
      _expectUnchanged(_apply(game: game), game, const {});
    case ApplyTradeInterceptionTarget.noEnemiesAtWar:
      final game = tradeInterceptionGame();
      const delivered = {'grain': 10};
      _expectUnchanged(_apply(game: game, delivered: delivered), game, delivered);
    case ApplyTradeInterceptionTarget.atWarNoInterceptor:
      final game = tradeInterceptionGame(defaultRelation: RelationState.atWar);
      const delivered = {'grain': 12};
      _expectUnchanged(_apply(game: game, delivered: delivered, seed: 7), game, delivered);
    case ApplyTradeInterceptionTarget.enemyPatrolReduces:
      final game = tradeInterceptionGame(defaultRelation: RelationState.atWar, fleets: [_patrolFleet()]);
      final result = _apply(game: game, delivered: const {'grain': 20}, seed: 12345);
      final reduced = result.reducedDelivered['grain'];
      expect(reduced, isNotNull);
      expect(reduced!, lessThan(20));
      expect(reduced, greaterThan(0));
    case ApplyTradeInterceptionTarget.deterministicSeed:
      final game = tradeInterceptionGame(defaultRelation: RelationState.atWar, fleets: [_patrolFleet()]);
      const delivered = {'grain': 20};
      final a = _apply(game: game, delivered: delivered, seed: 999);
      final b = _apply(game: game, delivered: delivered, seed: 999);
      expect(a.reducedDelivered['grain'], b.reducedDelivered['grain']);
    case ApplyTradeInterceptionTarget.privateeringBaseline:
      expect(_apply(game: tradeInterceptionPrivateeringGame(enemyHasPrivateering: false), delivered: const {'grain': 100}).reducedDelivered['grain'], 77);
    case ApplyTradeInterceptionTarget.privateeringBoosted:
      const delivered = {'grain': 100};
      final keptBaseline = _apply(game: tradeInterceptionPrivateeringGame(enemyHasPrivateering: false), delivered: delivered).reducedDelivered['grain']!;
      final keptBoosted = _apply(game: tradeInterceptionPrivateeringGame(enemyHasPrivateering: true), delivered: delivered).reducedDelivered['grain']!;
      expect(keptBoosted, 74);
      expect(keptBoosted, lessThan(keptBaseline));
    case ApplyTradeInterceptionTarget.privateeringDeterministic:
      final game = tradeInterceptionPrivateeringGame(enemyHasPrivateering: true);
      const delivered = {'grain': 100};
      final a = _apply(game: game, delivered: delivered, seed: 999);
      final b = _apply(game: game, delivered: delivered, seed: 999);
      expect(a.reducedDelivered['grain'], b.reducedDelivered['grain']);
    case ApplyTradeInterceptionTarget.shipRemovalLoop:
      final game = tradeInterceptionGame(
        defaultRelation: RelationState.atWar,
        fleets: [
          Fleet(id: 'f1', ownerId: 'p2', seaZoneId: 'sea1', regionId: 'oldWorld', shipTypeIds: const ['carrack', 'carrack'], mission: FleetMission.blockade),
          Fleet(id: 'f2', ownerId: 'p1', seaZoneId: 'sea1', regionId: 'oldWorld', shipTypeIds: const ['fluyte', 'fluyte', 'fluyte']),
        ],
      );
      const delivered = {'grain': 30};
      var shipRemoved = false;
      for (var seed = 0; seed < 500 && !shipRemoved; seed++) {
        final result = _apply(game: game, delivered: delivered, seed: seed);
        final totalShips = result.updatedFleets.where((f) => f.ownerId == 'p1').fold<int>(0, (s, f) => s + f.shipTypeIds.length);
        if (totalShips < 3) {
          shipRemoved = true;
          expect(result.reducedDelivered, isNotEmpty);
        }
      }
      expect(shipRemoved, isTrue, reason: 'some seed should trigger ship loss');
  }
}

ApplyTradeInterceptionScenario applyTradeInterceptionScenario({required String label, required ApplyTradeInterceptionTarget target, String? refs}) => (label: label, run: () => runApplyTradeInterceptionExpectation(target), refs: refs);

/// Pins for [scanTradeInterceptionInputs] rows.
enum TradeInterceptionScanTarget { noEnemyPatrol, merchantEscortCount, enemyBlockade, privateeringScales }

TradeInterceptionScan _scan(List<Fleet> fleets, {Set<String> enemiesAtWar = const {'p2'}, Set<String> privateeringOwners = const {}}) => scanTradeInterceptionInputs(fleets, enemiesAtWar, 'p1', privateeringOwners);

void runTradeInterceptionScanExpectation(TradeInterceptionScanTarget target) {
  switch (target) {
    case TradeInterceptionScanTarget.noEnemyPatrol:
      final scan = _scan([
        tradeInterceptionScanFleet(ownerId: 'p1', shipTypeIds: const ['fluyte']),
      ]);
      expect(scan.interceptScore, 0.0);
      expect(scan.hasBlockade, isFalse);
      expect(scan.playerMerchantShips, 1);
    case TradeInterceptionScanTarget.merchantEscortCount:
      final scan = _scan([
        tradeInterceptionScanFleet(ownerId: 'p1', shipTypeIds: const ['fluyte', 'carrack']),
        tradeInterceptionScanFleet(ownerId: 'p1', shipTypeIds: const ['sloop']),
      ]);
      expect(scan.playerMerchantShips, 2);
      expect(scan.escortStrength, greaterThan(0.0));
      expect(kMerchantShipTypeIds, containsAll(<String>{'fluyte', 'carrack'}));
    case TradeInterceptionScanTarget.enemyBlockade:
      final scan = _scan([
        tradeInterceptionScanFleet(ownerId: 'p2', shipTypeIds: const ['sloop'], mission: FleetMission.blockade),
      ]);
      expect(scan.hasBlockade, isTrue);
      expect(scan.interceptScore, greaterThan(0.0));
    case TradeInterceptionScanTarget.privateeringScales:
      List<Fleet> enemyPatrol() => [
        tradeInterceptionScanFleet(ownerId: 'p2', shipTypeIds: const ['sloop']),
      ];
      final baseline = _scan(enemyPatrol());
      final boosted = _scan(enemyPatrol(), privateeringOwners: const {'p2'});
      expect(baseline.interceptScore, greaterThan(0.0));
      expect(boosted.interceptScore, closeTo(baseline.interceptScore * kPrivateeringTradeRaidBonus, 1e-9));
  }
}

TradeInterceptionScanScenario tradeInterceptionScanScenario({required String label, required TradeInterceptionScanTarget target, String? refs}) => (label: label, run: () => runTradeInterceptionScanExpectation(target), refs: refs);
// dart format on
