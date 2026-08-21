import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Concern-split densify from model_value_types_test (Refs #4571).

void main() {
  group('AIConfig', () {
    test('exposes leader, personality, agenda and modifiers', () {
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'expansionist',
        hiddenAgendaId: 'colonial',
        difficultyModifiers: {'startGold': 100},
      );
      expect(config.leaderId, 'victoria');
      expect(config.difficultyModifiers['startGold'], 100);
    });

    test('defaults difficultyModifiers to empty', () {
      const config = AIConfig(
        leaderId: 'napoleon',
        personalityId: 'militarist',
        hiddenAgendaId: 'conqueror',
      );
      expect(config.difficultyModifiers, isEmpty);
    });
  });
  group('EconomyPlan', () {
    test('retains production assignments, cargo preference and trade orders', () {
      const plan = EconomyPlan(
        productionAssignments: [
          AssignedRecipe(recipeId: 'r1', assignedLabour: 2),
        ],
        cargoPreference: CargoPreference.strongCargo,
      );
      expect(plan.productionAssignments, hasLength(1));
      expect(plan.cargoPreference, CargoPreference.strongCargo);
      expect(plan.tradeOrders, isEmpty);
    });

    test('CargoPreference enum exposes all variants', () {
      expect(CargoPreference.values, [
        CargoPreference.none,
        CargoPreference.preferCargo,
        CargoPreference.strongCargo,
      ]);
    });
  });
  group('StrategicOrderResult', () {
    test('bundles orders and economy plan', () {
      const result = StrategicOrderResult(
        orders: Orders(),
        economyPlan: EconomyPlan(
          productionAssignments: [],
          cargoPreference: CargoPreference.none,
        ),
      );
      expect(result.orders, isA<Orders>());
      expect(result.economyPlan.cargoPreference, CargoPreference.none);
    });
  });
  group('TurnNewsDigest', () {
    test('holds resolved turn number and its line types', () {
      const digest = TurnNewsDigest(
        resolvedTurnNumber: 8,
        lines: [
          TurnNewsProvinceCapturedLine(
            provinceId: 'r1|p1',
            previousOwnerId: 'D',
            newOwnerId: 'A',
          ),
          TurnNewsDiplomacyLine(
            factionIdA: 'A',
            factionIdB: 'B',
            kind: TurnNewsDiplomacyKind.war,
          ),
          TurnNewsOvertureAdvancedLine(
            offererGpId: 'gp1',
            targetFactionId: 'mn1',
            newStage: OvertureStage.embassy,
          ),
          TurnNewsProvinceDiscoveredLine(provinceId: 'r1|p2'),
          TurnNewsSeaZoneFleetLine(seaZoneId: 'sz1'),
        ],
      );
      expect(digest.resolvedTurnNumber, 8);
      expect(digest.lines, hasLength(5));
      expect((digest.lines[0] as TurnNewsProvinceCapturedLine).newOwnerId, 'A');
      expect((digest.lines[1] as TurnNewsDiplomacyLine).kind,
          TurnNewsDiplomacyKind.war);
      expect((digest.lines[2] as TurnNewsOvertureAdvancedLine).newStage,
          OvertureStage.embassy);
      expect(
        (digest.lines[3] as TurnNewsProvinceDiscoveredLine).provinceId,
        'r1|p2',
      );
      expect((digest.lines[4] as TurnNewsSeaZoneFleetLine).seaZoneId, 'sz1');
    });

    test('TurnNewsDiplomacyKind exposes war and peace', () {
      expect(TurnNewsDiplomacyKind.values,
          [TurnNewsDiplomacyKind.war, TurnNewsDiplomacyKind.peace]);
    });
  });
  group('WorkerIdleCounts', () {
    test('zero constant has no idle workers', () {
      expect(WorkerIdleCounts.zero.peasants, 0);
      expect(WorkerIdleCounts.zero.effectiveLabour, 0);
    });

    test('effectiveLabour weights tiers like WorkerPool', () {
      const counts = WorkerIdleCounts(
        peasants: 1,
        apprentices: 1,
        journeymen: 1,
        masters: 1,
      );
      final expected = WorkerPool.labourPerPeasantTurn +
          WorkerPool.labourPerApprenticeTurn +
          WorkerPool.labourPerJourneymanTurn +
          WorkerPool.labourPerMasterTurn;
      expect(counts.effectiveLabour, expected);
    });

    test('asserts non-negative counts', () {
      expect(
        () => WorkerIdleCounts(peasants: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equality and hashCode consider all tiers', () {
      const a = WorkerIdleCounts(peasants: 2, masters: 1);
      const b = WorkerIdleCounts(peasants: 2, masters: 1);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const WorkerIdleCounts(peasants: 2)));
    });
  });
}
