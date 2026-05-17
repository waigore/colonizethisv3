import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('build_cost', () {
    test('canAffordBuild returns false for unknown unit type', () {
      const player = Player(id: 'p1', displayName: 'P', isHuman: true);
      const workers = WorkerPool(peasants: 10);
      const stockpile = Stockpile();
      const order = BuildUnitOrder(
        unitType: 'unknown_unit_xyz',
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p1',
      );
      final result = canAffordBuild(player, order, workers, stockpile, 10000);
      expect(result.canAfford, isFalse);
      expect(result.reason, 'Insufficient resources');
    });

    test(
      'applyBuildCostDeduction returns unchanged state for unknown unit type',
      () {
        const player = Player(id: 'p1', displayName: 'P', isHuman: true);
        const workers = WorkerPool(peasants: 5);
        const stockpile = Stockpile();
        const order = BuildUnitOrder(
          unitType: 'unknown_unit_xyz',
          isMilitary: false,
          spawnProvinceId: 'oldWorld|p1',
        );
        final result = applyBuildCostDeduction(
          player,
          order,
          workers,
          stockpile,
          1000,
        );
        expect(result.workers.peasants, 5);
        expect(result.treasury, 1000);
      },
    );

    test('civilian Builder: apply matches catalog after canAfford true', () {
      const player = Player(id: 'p1', displayName: 'P', isHuman: true);
      const workers = WorkerPool(peasants: 10);
      final econ = CivilianEconomyCatalog.byId[kUnitTypeBuilder]!;
      var stockpile = const Stockpile();
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value);
      }
      const treasuryStart = 5000;
      const order = BuildUnitOrder(
        unitType: kUnitTypeBuilder,
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p1',
      );
      final check = canAffordBuild(
        player,
        order,
        workers,
        stockpile,
        treasuryStart,
      );
      expect(check.canAfford, isTrue);
      final after = applyBuildCostDeduction(
        player,
        order,
        workers,
        stockpile,
        treasuryStart,
      );
      expect(after.treasury, treasuryStart - econ.buildTreasuryCost);
      expect(after.workers.peasants, workers.peasants);
      for (final e in econ.buildInputs.entries) {
        expect(after.stockpile.quantityOf(e.key), 0);
      }
    });

    test(
      'military peasant_levies: apply matches catalog after canAfford true',
      () {
        const player = Player(id: 'p1', displayName: 'P', isHuman: true);
        const workers = WorkerPool(peasants: 3);
        final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
        var stockpile = const Stockpile();
        for (final e in econ.buildInputs.entries) {
          stockpile = stockpile.applyDelta(e.key, e.value);
        }
        final treasuryStart = econ.buildTreasuryCost + 500;
        const order = BuildUnitOrder(
          unitType: 'peasant_levies',
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p1',
        );
        final check = canAffordBuild(
          player,
          order,
          workers,
          stockpile,
          treasuryStart,
        );
        expect(check.canAfford, isTrue);
        final after = applyBuildCostDeduction(
          player,
          order,
          workers,
          stockpile,
          treasuryStart,
        );
        expect(after.treasury, treasuryStart - econ.buildTreasuryCost);
        expect(after.workers.peasants, workers.peasants - 1);
        for (final e in econ.buildInputs.entries) {
          expect(after.stockpile.quantityOf(e.key), 0);
        }
      },
    );

    test('naval carrack: apply matches catalog after canAfford true', () {
      const player = Player(id: 'p1', displayName: 'P', isHuman: true);
      const workers = WorkerPool(peasants: 10);
      final econ = ShipEconomyCatalog.byId['carrack']!;
      var stockpile = const Stockpile();
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value);
      }
      final treasuryStart = econ.buildTreasuryCost + 500;
      const order = BuildUnitOrder(
        unitType: 'carrack',
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p1',
      );
      final check = canAffordBuild(
        player,
        order,
        workers,
        stockpile,
        treasuryStart,
      );
      expect(check.canAfford, isTrue);
      final after = applyBuildCostDeduction(
        player,
        order,
        workers,
        stockpile,
        treasuryStart,
      );
      expect(after.treasury, treasuryStart - econ.buildTreasuryCost);
      expect(after.workers.peasants, workers.peasants - 1);
      for (final e in econ.buildInputs.entries) {
        expect(after.stockpile.quantityOf(e.key), 0);
      }
    });

    test('naval carrack: canAfford false when peasants are zero', () {
      const player = Player(id: 'p1', displayName: 'P', isHuman: true);
      const workers = WorkerPool(peasants: 0);
      final econ = ShipEconomyCatalog.byId['carrack']!;
      var stockpile = const Stockpile();
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value);
      }
      const order = BuildUnitOrder(
        unitType: 'carrack',
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p1',
      );
      final result = canAffordBuild(
        player,
        order,
        workers,
        stockpile,
        econ.buildTreasuryCost + 10,
      );
      expect(result.canAfford, isFalse);
      expect(result.reason, 'Insufficient workers');
    });

    test('naval fluyte: canAfford false when unlocking tech missing', () {
      const player = Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        techUnlocked: {},
      );
      const workers = WorkerPool(peasants: 10);
      final econ = ShipEconomyCatalog.byId['fluyte']!;
      var stockpile = const Stockpile();
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value);
      }
      const order = BuildUnitOrder(
        unitType: 'fluyte',
        isMilitary: false,
        spawnProvinceId: 'oldWorld|p1',
      );
      final result = canAffordBuild(
        player,
        order,
        workers,
        stockpile,
        econ.buildTreasuryCost + 500,
      );
      expect(result.canAfford, isFalse);
      expect(result.reason, 'Required technology not unlocked');
    });

    test('military lancers: canAfford false when unlocking tech missing', () {
      const player = Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        techUnlocked: {},
      );
      const workers = WorkerPool(peasants: 5);
      final econ = RegimentEconomyCatalog.byId['lancers']!;
      var stockpile = const Stockpile();
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value);
      }
      const order = BuildUnitOrder(
        unitType: 'lancers',
        isMilitary: true,
        spawnProvinceId: 'oldWorld|p1',
      );
      final result = canAffordBuild(
        player,
        order,
        workers,
        stockpile,
        econ.buildTreasuryCost + 500,
      );
      expect(result.canAfford, isFalse);
      expect(result.reason, 'Required technology not unlocked');
    });

    test('military peasant_levies: canAfford false when peasants are zero', () {
      const player = Player(id: 'p1', displayName: 'P', isHuman: true);
      const workers = WorkerPool(peasants: 0);
      final econ = RegimentEconomyCatalog.byId['peasant_levies']!;
      var stockpile = const Stockpile();
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, e.value);
      }
      const order = BuildUnitOrder(
        unitType: 'peasant_levies',
        isMilitary: true,
        spawnProvinceId: 'oldWorld|p1',
      );
      final result = canAffordBuild(
        player,
        order,
        workers,
        stockpile,
        econ.buildTreasuryCost + 500,
      );
      expect(result.canAfford, isFalse);
      expect(result.reason, 'Insufficient workers');
    });
  });
}
