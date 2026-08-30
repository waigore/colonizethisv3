import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OvertureState', () {
    const overture = OvertureState(
      gpId: 'gp1',
      targetId: 'mn1',
      stage: OvertureStage.embassy,
      sinceTurn: 2,
    );

    test('toJson/fromJson round-trips', () {
      expect(OvertureState.fromJson(overture.toJson()).gpId, 'gp1');
      expect(OvertureState.fromJson(overture.toJson()).stage, OvertureStage.embassy);
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
      expect(
        OvertureState.fromJson({
          'gpId': 'gp1',
          'targetId': 'mn4',
          'stage': 'bogus',
        }).stage,
        OvertureStage.none,
      );
    });

    test('copyWith overrides only provided fields', () {
      expect(overture.copyWith(stage: OvertureStage.nap).stage, OvertureStage.nap);
      expect(overture.copyWith(stage: OvertureStage.nap).gpId, 'gp1');
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
      expect(DiplomaticOrder.fromJson(full.toJson()), full);
    });

    test('fromJson falls back to declareWar for unknown type', () {
      expect(
        DiplomaticOrder.fromJson({
          'type': 'bogus',
          'targetFactionId': 'D',
        }).type,
        DiplomaticOrderType.declareWar,
      );
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
      expect(
        a,
        isNot(DiplomaticOrder(
          type: a.type,
          targetFactionId: a.targetFactionId,
          amount: 20,
          overtureStage: a.overtureStage,
        )),
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
      expect(DiplomaticEvent.fromJson(event.toJson()), event);
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
      expect(
        DiplomaticEvent.fromJson({
          'turn': 1,
          'intraTurnIndex': 0,
          'type': 'bogus',
          'participants': const ['A'],
        }).type,
        DiplomaticEventType.declareWar,
      );
    });

    test('equality distinguishes differing participant sets', () {
      expect(
        event,
        isNot(const DiplomaticEvent(
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
        )),
      );
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
