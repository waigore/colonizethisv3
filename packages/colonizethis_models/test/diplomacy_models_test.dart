import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('DiplomacyRelation', () {
    const relation = DiplomacyRelation(
      factionId1: 'A',
      factionId2: 'B',
      score: 70,
      level: RelationLevel.friendly,
      state: RelationState.atWar,
      sinceTurn: 3,
      lastInteractionTurn: 5,
    );

    test('toJson/fromJson round-trips all fields', () {
      final restored = DiplomacyRelation.fromJson(relation.toJson());
      expect(restored.factionId1, 'A');
      expect(restored.factionId2, 'B');
      expect(restored.score, 70);
      expect(restored.level, RelationLevel.friendly);
      expect(restored.state, RelationState.atWar);
      expect(restored.sinceTurn, 3);
      expect(restored.lastInteractionTurn, 5);
    });

    test('atWar/atPeace and involvesNation reflect state and parties', () {
      expect(relation.atWar, isTrue);
      expect(relation.atPeace, isFalse);
      expect(relation.involvesNation('A'), isTrue);
      expect(relation.involvesNation('B'), isTrue);
      expect(relation.involvesNation('C'), isFalse);
    });

    test('fromJson falls back to defaults for unknown enums and missing fields', () {
      final restored = DiplomacyRelation.fromJson({
        'factionId1': 'X',
        'factionId2': 'Y',
        'level': 'bogus',
        'state': 'bogus',
      });
      expect(restored.score, 50);
      expect(restored.level, RelationLevel.neutral);
      expect(restored.state, RelationState.atPeace);
      expect(restored.sinceTurn, 0);
      expect(restored.lastInteractionTurn, 0);
    });

    test('copyWith overrides only provided fields', () {
      final updated = relation.copyWith(score: 10, state: RelationState.atPeace);
      expect(updated.score, 10);
      expect(updated.state, RelationState.atPeace);
      expect(updated.factionId1, 'A');
    });

    test('formalAlliance defaults to false and is omitted from JSON when false', () {
      expect(relation.formalAlliance, isFalse);
      expect(relation.toJson().containsKey('formalAlliance'), isFalse);
      final restored = DiplomacyRelation.fromJson(relation.toJson());
      expect(restored.formalAlliance, isFalse);
    });

    test('decimal score round-trips through JSON (0.1 precision)', () {
      const fractional = DiplomacyRelation(
        factionId1: 'A',
        factionId2: 'B',
        score: 73.5,
      );
      final restored = DiplomacyRelation.fromJson(fractional.toJson());
      expect(restored.score, 73.5);
      expect(restored.score, isA<double>());
    });

    test('legacy integer score migrates to decimal (x1.0) on load', () {
      final restored = DiplomacyRelation.fromJson(const {
        'factionId1': 'A',
        'factionId2': 'B',
        'score': 50,
        'level': 'neutral',
        'state': 'atPeace',
      });
      expect(restored.score, 50);
      expect(restored.score, isA<double>());
      expect(restored.score == 50.0, isTrue);
    });

    test('copyWith accepts a fractional decimal score', () {
      final updated = relation.copyWith(score: 50.4);
      expect(updated.score, 50.4);
    });

    test('formalAlliance round-trips through JSON when true', () {
      const allied = DiplomacyRelation(
        factionId1: 'A',
        factionId2: 'B',
        score: 80,
        level: RelationLevel.allied,
        formalAlliance: true,
      );
      final json = allied.toJson();
      expect(json['formalAlliance'], isTrue);
      final restored = DiplomacyRelation.fromJson(json);
      expect(restored.formalAlliance, isTrue);
      expect(allied.copyWith().formalAlliance, isTrue);
      expect(allied.copyWith(formalAlliance: false).formalAlliance, isFalse);
    });
  });

  group('OvertureState', () {
    const overture = OvertureState(
      gpId: 'gp1',
      targetId: 'mn1',
      stage: OvertureStage.embassy,
      sinceTurn: 2,
    );

    test('toJson/fromJson round-trips', () {
      final restored = OvertureState.fromJson(overture.toJson());
      expect(restored.gpId, 'gp1');
      expect(restored.targetId, 'mn1');
      expect(restored.stage, OvertureStage.embassy);
      expect(restored.sinceTurn, 2);
    });

    test('hasEmbassy/hasConsulate reflect stage', () {
      expect(overture.hasEmbassy, isTrue);
      expect(overture.hasConsulate, isTrue);

      const none = OvertureState(gpId: 'gp1', targetId: 'mn2');
      expect(none.hasEmbassy, isFalse);
      expect(none.hasConsulate, isFalse);

      const consulate = OvertureState(
        gpId: 'gp1',
        targetId: 'mn3',
        stage: OvertureStage.tradeConsulate,
      );
      expect(consulate.hasEmbassy, isFalse);
      expect(consulate.hasConsulate, isTrue);
    });

    test('fromJson falls back to none for unknown stage', () {
      final restored = OvertureState.fromJson({
        'gpId': 'gp1',
        'targetId': 'mn4',
        'stage': 'bogus',
      });
      expect(restored.stage, OvertureStage.none);
    });

    test('copyWith overrides only provided fields', () {
      final updated = overture.copyWith(stage: OvertureStage.nap);
      expect(updated.stage, OvertureStage.nap);
      expect(updated.gpId, 'gp1');
    });
  });

  group('DiplomaticOrder', () {
    test('toJson omits null optionals; fromJson round-trips full payload', () {
      const minimal = DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: 'B',
      );
      final minJson = minimal.toJson();
      expect(minJson.containsKey('amount'), isFalse);
      expect(minJson.containsKey('overtureStage'), isFalse);
      expect(DiplomaticOrder.fromJson(minJson), minimal);

      const full = DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: 'C',
        amount: 50,
        overtureStage: OvertureStage.embassy,
      );
      final restored = DiplomaticOrder.fromJson(full.toJson());
      expect(restored, full);
      expect(restored.amount, 50);
      expect(restored.overtureStage, OvertureStage.embassy);
    });

    test('fromJson falls back to declareWar for unknown type', () {
      final restored = DiplomaticOrder.fromJson({
        'type': 'bogus',
        'targetFactionId': 'D',
      });
      expect(restored.type, DiplomaticOrderType.declareWar);
    });

    test('equality and hashCode consider all fields', () {
      const a = DiplomaticOrder(
        type: DiplomaticOrderType.grantAid,
        targetFactionId: 'B',
        amount: 10,
      );
      const b = DiplomaticOrder(
        type: DiplomaticOrderType.grantAid,
        targetFactionId: 'B',
        amount: 10,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == b.copyWithAmount(20), isFalse);
    });
  });

  group('SubsidyState (percent model, Refs #3753 R3)', () {
    const subsidy = SubsidyState(payerId: 'gp1', targetId: 'mn1', percent: 10);

    test('toJson/fromJson round-trips', () {
      final restored = SubsidyState.fromJson(subsidy.toJson());
      expect(restored, subsidy);
      expect(restored.percent, 10);
      expect(subsidy.toJson()['percent'], 10);
    });

    test('copyWith and equality', () {
      final updated = subsidy.copyWith(percent: 15);
      expect(updated.percent, 15);
      expect(updated.payerId, 'gp1');
      expect(subsidy == updated, isFalse);
      expect(subsidy.hashCode,
          const SubsidyState(payerId: 'gp1', targetId: 'mn1', percent: 10)
              .hashCode);
    });

    test('legacy £/turn save decodes to percent 0 (dropped by migration)', () {
      final legacy = SubsidyState.fromJson(
        const {'payerId': 'gp1', 'targetId': 'mn1', 'amountPerTurn': 500},
      );
      expect(legacy.percent, 0);
      expect(isValidSubsidyPercent(legacy.percent), isFalse);
    });

    test('isValidSubsidyPercent enforces 5-20 step 5', () {
      expect(isValidSubsidyPercent(5), isTrue);
      expect(isValidSubsidyPercent(20), isTrue);
      expect(isValidSubsidyPercent(10), isTrue);
      expect(isValidSubsidyPercent(0), isFalse);
      expect(isValidSubsidyPercent(7), isFalse);
      expect(isValidSubsidyPercent(25), isFalse);
    });
  });

  group('ColonyState', () {
    const colony = ColonyState(
      tribeId: 'tribe1',
      colonyOfGpId: 'gp1',
      sinceTurn: 4,
    );

    test('toJson/fromJson round-trips', () {
      final restored = ColonyState.fromJson(colony.toJson());
      expect(restored, colony);
      expect(restored.tribeId, 'tribe1');
      expect(restored.colonyOfGpId, 'gp1');
      expect(restored.sinceTurn, 4);
    });

    test('fromJson defaults sinceTurn to 0 when missing', () {
      final restored = ColonyState.fromJson(const {
        'tribeId': 'tribe1',
        'colonyOfGpId': 'gp1',
      });
      expect(restored.sinceTurn, 0);
    });

    test('copyWith and equality', () {
      final updated = colony.copyWith(colonyOfGpId: 'gp2');
      expect(updated.colonyOfGpId, 'gp2');
      expect(updated.tribeId, 'tribe1');
      expect(colony == updated, isFalse);
      expect(
        colony.hashCode,
        const ColonyState(tribeId: 'tribe1', colonyOfGpId: 'gp1', sinceTurn: 4)
            .hashCode,
      );
    });
  });

  group('BoycottState (Refs #3753 R6)', () {
    const boycott = BoycottState(
      gpId: 'gp1',
      targetGpId: 'gp2',
      sinceTurn: 5,
    );

    test('toJson/fromJson round-trips', () {
      final restored = BoycottState.fromJson(boycott.toJson());
      expect(restored, boycott);
      expect(restored.gpId, 'gp1');
      expect(restored.targetGpId, 'gp2');
      expect(restored.sinceTurn, 5);
    });

    test('fromJson defaults sinceTurn to 0 when missing', () {
      final restored = BoycottState.fromJson(const {
        'gpId': 'gp1',
        'targetGpId': 'gp2',
      });
      expect(restored.sinceTurn, 0);
    });

    test('copyWith and equality', () {
      final updated = boycott.copyWith(targetGpId: 'gp3');
      expect(updated.targetGpId, 'gp3');
      expect(updated.gpId, 'gp1');
      expect(boycott == updated, isFalse);
      expect(
        boycott.hashCode,
        const BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 5)
            .hashCode,
      );
    });
  });

  group('DiplomaticEvent', () {
    const event = DiplomaticEvent(
      turn: 7,
      intraTurnIndex: 1,
      type: DiplomaticEventType.allianceFormed,
      participants: {'A', 'B'},
      fromFactionId: 'A',
      toFactionId: 'B',
      overtureStage: OvertureStage.nap,
      amount: 5,
      reason: 'mutual defense',
      wasAiInitiator: true,
    );

    test('toJson/fromJson round-trips all fields', () {
      final restored = DiplomaticEvent.fromJson(event.toJson());
      expect(restored.turn, 7);
      expect(restored.intraTurnIndex, 1);
      expect(restored.type, DiplomaticEventType.allianceFormed);
      expect(restored.participants, {'A', 'B'});
      expect(restored.fromFactionId, 'A');
      expect(restored.toFactionId, 'B');
      expect(restored.overtureStage, OvertureStage.nap);
      expect(restored.amount, 5);
      expect(restored.reason, 'mutual defense');
      expect(restored.wasAiInitiator, isTrue);
      expect(restored, event);
    });

    test('toJson omits null/false optionals', () {
      const minimal = DiplomaticEvent(
        turn: 1,
        intraTurnIndex: 0,
        type: DiplomaticEventType.peace,
        participants: {'A', 'B'},
      );
      final json = minimal.toJson();
      expect(json.containsKey('fromFactionId'), isFalse);
      expect(json.containsKey('amount'), isFalse);
      expect(json.containsKey('wasAiInitiator'), isFalse);
      expect(DiplomaticEvent.fromJson(json), minimal);
    });

    test('fromJson falls back to declareWar for unknown type', () {
      final restored = DiplomaticEvent.fromJson({
        'turn': 1,
        'intraTurnIndex': 0,
        'type': 'bogus',
        'participants': const ['A'],
      });
      expect(restored.type, DiplomaticEventType.declareWar);
    });

    test('equality distinguishes differing participant sets', () {
      const other = DiplomaticEvent(
        turn: 7,
        intraTurnIndex: 1,
        type: DiplomaticEventType.allianceFormed,
        participants: {'A', 'C'},
        fromFactionId: 'A',
        toFactionId: 'B',
        overtureStage: OvertureStage.nap,
        amount: 5,
        reason: 'mutual defense',
        wasAiInitiator: true,
      );
      expect(event == other, isFalse);
    });
  });

  group('InterventionChoice', () {
    test('exposes all variants', () {
      expect(InterventionChoice.values, [
        InterventionChoice.intervene,
        InterventionChoice.doNothing,
        InterventionChoice.protest,
      ]);
    });
  });
}

extension on DiplomaticOrder {
  DiplomaticOrder copyWithAmount(int amount) => DiplomaticOrder(
        type: type,
        targetFactionId: targetFactionId,
        amount: amount,
        overtureStage: overtureStage,
      );
}
