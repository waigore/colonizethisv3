import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/diplomacy_game_fixtures.dart';

void main() {
  group('dossier evidence (Phase 6)', () {
    test('AI declare war on weaker GP appends warmonger evidence for human observer', () {
      final game = diplomacyGame(
        id: 'g1',
        turnNumber: 2,
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI Strong', isHuman: false, militaryLevel: 3),
          Player(id: 'gp3', displayName: 'AI Weak', isHuman: false, militaryLevel: 1),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'gp3',
            score: 50,
            level: RelationLevel.neutral,
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': const [
            DiplomaticOrder(type: DiplomaticOrderType.declareWar, targetFactionId: 'gp3'),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      final evidence = after.dossierEvidenceEntries;
      expect(evidence.any((e) =>
          e.observerId == 'gp1' && e.subjectId == 'gp2' && e.agendaType == 'warmonger' && e.scoreDelta == 2),
          isTrue);
      expect(evidence.any((e) => e.description.contains('weaker neighbor')), isTrue);
    });

    test('AI declare war on ally appends backstabber evidence for human observer', () {
      final game = diplomacyGame(
        id: 'g1',
        turnNumber: 2,
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
          Player(id: 'gp3', displayName: 'Other', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'gp3',
            score: 80,
            level: RelationLevel.allied,
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': const [
            DiplomaticOrder(type: DiplomaticOrderType.declareWar, targetFactionId: 'gp3'),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      final evidence = after.dossierEvidenceEntries;
      expect(evidence.any((e) =>
          e.observerId == 'gp1' && e.subjectId == 'gp2' && e.agendaType == 'backstabber' && e.scoreDelta == 3),
          isTrue);
      expect(evidence.any((e) => e.description.contains('ally')), isTrue);
    });

    test('AI offer peace appends peacemaker evidence for human observer', () {
      final game = diplomacyGame(
        id: 'g1',
        turnNumber: 2,
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
          Player(id: 'gp3', displayName: 'Other', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'gp3',
            score: 40,
            level: RelationLevel.neutral,
            state: RelationState.atWar,
          ),
        ],
      );
      // GP–GP peace requires both sides to offer peace (SPEC/game/diplomacy.md).
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': const [
            DiplomaticOrder(type: DiplomaticOrderType.offerPeace, targetFactionId: 'gp3'),
          ],
          'gp3': const [
            DiplomaticOrder(type: DiplomaticOrderType.offerPeace, targetFactionId: 'gp2'),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      final evidence = after.dossierEvidenceEntries;
      expect(evidence.any((e) =>
          e.observerId == 'gp1' && e.subjectId == 'gp2' && e.agendaType == 'peacemaker' && e.scoreDelta == 1),
          isTrue);
    });

    test('human declare war does not append evidence', () {
      final game = diplomacyGame(
        id: 'g1',
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 50,
            level: RelationLevel.neutral,
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(type: DiplomaticOrderType.declareWar, targetFactionId: 'gp2'),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      expect(after.dossierEvidenceEntries, isEmpty);
    });
  });
}
