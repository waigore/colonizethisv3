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

    test(
      'fromJson falls back to defaults for unknown enums and missing fields',
      () {
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
      },
    );

    test('copyWith overrides only provided fields', () {
      final updated = relation.copyWith(
        score: 10,
        state: RelationState.atPeace,
      );
      expect(updated.score, 10);
      expect(updated.state, RelationState.atPeace);
      expect(updated.factionId1, 'A');
    });

    test(
      'formalAlliance defaults to false and is omitted from JSON when false',
      () {
        expect(relation.formalAlliance, isFalse);
        expect(relation.toJson().containsKey('formalAlliance'), isFalse);
        final restored = DiplomacyRelation.fromJson(relation.toJson());
        expect(restored.formalAlliance, isFalse);
      },
    );

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

    test(
      'fromJson drops formalAlliance for an at-war pair (war invariant)',
      () {
        // SPEC/game/diplomacy.md § Alliances: formalAlliance can never coexist
        // with atWar; an invalid legacy save is normalized on load.
        final restored = DiplomacyRelation.fromJson(const {
          'factionId1': 'A',
          'factionId2': 'B',
          'score': 80,
          'level': 'allied',
          'state': 'atWar',
          'formalAlliance': true,
        });
        expect(restored.state, RelationState.atWar);
        expect(restored.formalAlliance, isFalse);
      },
    );

    test('fromJson keeps formalAlliance for an at-peace pair', () {
      final restored = DiplomacyRelation.fromJson(const {
        'factionId1': 'A',
        'factionId2': 'B',
        'score': 80,
        'level': 'allied',
        'state': 'atPeace',
        'formalAlliance': true,
      });
      expect(restored.state, RelationState.atPeace);
      expect(restored.formalAlliance, isTrue);
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

  group('AllianceBreakCooldownState', () {
    test('toJson/fromJson round-trips', () {
      const cooldown = AllianceBreakCooldownState(
        factionId1: 'gp1',
        factionId2: 'gp2',
        sinceTurn: 4,
      );
      final restored = AllianceBreakCooldownState.fromJson(cooldown.toJson());
      expect(restored, cooldown);
    });
  });
}
