import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('CurrentWork', () {
    const work = CurrentWork(
      workTarget: 'build_farm',
      tileKey: 'r1|p1|2|3',
      totalTurns: 5,
      remainingTurns: 2,
    );

    test('toJson/fromJson round-trips', () {
      final restored = CurrentWork.fromJson(work.toJson());
      expect(restored, work);
      expect(restored.workTarget, 'build_farm');
      expect(restored.remainingTurns, 2);
    });

    test('fromJson defaults turn counts when missing', () {
      final restored = CurrentWork.fromJson({
        'workTarget': 'explore',
        'tileKey': 'r1|p1|0|0',
      });
      expect(restored.totalTurns, 0);
      expect(restored.remainingTurns, 0);
    });

    test('copyWith and equality', () {
      final updated = work.copyWith(remainingTurns: 1);
      expect(updated.remainingTurns, 1);
      expect(updated.totalTurns, 5);
      expect(work == updated, isFalse);
      expect(work.hashCode, work.copyWith().hashCode);
    });
  });

  group('General', () {
    const general = General(id: 'g1', ownerId: 'p1', medals: 3);

    test('toJson omits zero medals and round-trips', () {
      const plain = General(id: 'g2', ownerId: 'p1');
      expect(plain.toJson().containsKey('medals'), isFalse);
      expect(General.fromJson(plain.toJson()), plain);

      final json = general.toJson();
      expect(json['medals'], 3);
      expect(General.fromJson(json), general);
    });

    test('copyWith and equality', () {
      final updated = general.copyWith(medals: 0);
      expect(updated.medals, 0);
      expect(updated.id, 'g1');
      expect(general == const General(id: 'g1', ownerId: 'p1', medals: 3), isTrue);
      expect(general.hashCode,
          const General(id: 'g1', ownerId: 'p1', medals: 3).hashCode);
    });
  });

  group('DossierEvidenceEntry', () {
    const entry = DossierEvidenceEntry(
      observerId: 'o1',
      subjectId: 's1',
      agendaType: 'expansionist',
      turnNumber: 4,
      description: 'Built up army',
      scoreDelta: 2,
    );

    test('toJson/fromJson round-trips all fields', () {
      final restored = DossierEvidenceEntry.fromJson(entry.toJson());
      expect(restored.observerId, 'o1');
      expect(restored.subjectId, 's1');
      expect(restored.agendaType, 'expansionist');
      expect(restored.turnNumber, 4);
      expect(restored.description, 'Built up army');
      expect(restored.scoreDelta, 2);
    });

    test('fromJson applies defaults for missing optionals', () {
      final restored = DossierEvidenceEntry.fromJson({
        'observerId': 'o2',
        'subjectId': 's2',
        'agendaType': 'militarist',
      });
      expect(restored.turnNumber, 0);
      expect(restored.description, '');
      expect(restored.scoreDelta, 1);
    });
  });

  group('AISeedBundle', () {
    test('fromTurnSeed is deterministic for the same seed', () {
      final a = AISeedBundle.fromTurnSeed(12345);
      final b = AISeedBundle.fromTurnSeed(12345);
      expect(a.perceptionSeed, b.perceptionSeed);
      expect(a.goalSeed, b.goalSeed);
      expect(a.agendaSeed, b.agendaSeed);
    });

    test('different turn seeds derive different bundles', () {
      final a = AISeedBundle.fromTurnSeed(1);
      final b = AISeedBundle.fromTurnSeed(2);
      expect(a.goalSeed == b.goalSeed, isFalse);
    });

    test('explicit constructor retains supplied sub-seeds', () {
      const bundle = AISeedBundle(
        perceptionSeed: 1,
        goalSeed: 2,
        economySeed: 3,
        militarySeed: 4,
        diplomacySeed: 5,
        researchSeed: 6,
        tacticalSeed: 7,
        dialogueSeed: 8,
        agendaSeed: 9,
      );
      expect(bundle.economySeed, 3);
      expect(bundle.tacticalSeed, 7);
      expect(bundle.agendaSeed, 9);
    });
  });

  group('AssignedRecipe', () {
    test('stores recipe id and labour', () {
      const recipe = AssignedRecipe(recipeId: 'r-iron', assignedLabour: 3);
      expect(recipe.recipeId, 'r-iron');
      expect(recipe.assignedLabour, 3);
    });

    test('asserts labour is non-negative', () {
      expect(
        () => AssignedRecipe(recipeId: 'r', assignedLabour: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('AIConfig', () {
    test('exposes leader, personality, agenda and modifiers', () {
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'expansionist',
        hiddenAgendaId: 'colonial',
        difficultyModifiers: {'startGold': 100},
      );
      expect(config.leaderId, 'victoria');
      expect(config.personalityId, 'expansionist');
      expect(config.hiddenAgendaId, 'colonial');
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

      final captured = digest.lines[0] as TurnNewsProvinceCapturedLine;
      expect(captured.newOwnerId, 'A');
      final diplo = digest.lines[1] as TurnNewsDiplomacyLine;
      expect(diplo.kind, TurnNewsDiplomacyKind.war);
      final overture = digest.lines[2] as TurnNewsOvertureAdvancedLine;
      expect(overture.newStage, OvertureStage.embassy);
      final discovered = digest.lines[3] as TurnNewsProvinceDiscoveredLine;
      expect(discovered.provinceId, 'r1|p2');
      final fleet = digest.lines[4] as TurnNewsSeaZoneFleetLine;
      expect(fleet.seaZoneId, 'sz1');
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
      expect(a == const WorkerIdleCounts(peasants: 2), isFalse);
    });
  });
}
