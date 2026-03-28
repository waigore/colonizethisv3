import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  late Game minimalGame;

  setUp(() {
    minimalGame = Game(
      id: 'g1',
      worldState: WorldState(
        turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: [Player(id: 'gp1', displayName: 'A', isHuman: true)],
    );
  });

  group('OvertureOffer', () {
    test('equality and hashCode', () {
      const a = OvertureOffer(
        offererGpId: 'gp1',
        targetFactionId: 'minor1',
        stage: OvertureStage.tradeConsulate,
      );
      const b = OvertureOffer(
        offererGpId: 'gp1',
        targetFactionId: 'minor1',
        stage: OvertureStage.tradeConsulate,
      );
      final c = OvertureOffer(
        offererGpId: 'gp2',
        targetFactionId: 'minor1',
        stage: OvertureStage.tradeConsulate,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('equality with non-identical equal instance', () {
      final a = OvertureOffer(
        offererGpId: 'gp1',
        targetFactionId: 't1',
        stage: OvertureStage.embassy,
      );
      final b = OvertureOffer(
        offererGpId: 'gp1',
        targetFactionId: 't1',
        stage: OvertureStage.embassy,
      );
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('OvertureDecision', () {
    test('equality and hashCode', () {
      const a = OvertureDecision(
        offererGpId: 'gp1',
        targetFactionId: 'minor1',
        stage: OvertureStage.embassy,
        accepted: true,
      );
      const b = OvertureDecision(
        offererGpId: 'gp1',
        targetFactionId: 'minor1',
        stage: OvertureStage.embassy,
        accepted: true,
      );
      const c = OvertureDecision(
        offererGpId: 'gp1',
        targetFactionId: 'minor1',
        stage: OvertureStage.embassy,
        accepted: false,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('DiplomacyPhaseResult', () {
    test('isPending true when pendingOvertures non-empty', () {
      final result = DiplomacyPhaseResult(
        minimalGame,
        pendingOvertures: [
          OvertureOffer(
            offererGpId: 'gp1',
            targetFactionId: 'gp2',
            stage: OvertureStage.tradeConsulate,
          ),
        ],
      );
      expect(result.isPending, isTrue);
    });

    test('isPending true when pendingInterventions non-empty', () {
      final result = DiplomacyPhaseResult(
        minimalGame,
        pendingInterventions: const [
          InterventionPrompt(
            aggressorGpId: 'gp2',
            defenderMinorOrTribeId: 'minor1',
            interveningGpId: 'gp1',
          ),
        ],
      );
      expect(result.isPending, isTrue);
    });

    test('isPending false when pendingOvertures null', () {
      final result = DiplomacyPhaseResult(minimalGame);
      expect(result.isPending, isFalse);
    });

    test('isPending false when pendingOvertures empty', () {
      final result = DiplomacyPhaseResult(minimalGame, pendingOvertures: []);
      expect(result.isPending, isFalse);
    });
  });

  group('TurnResolutionResult', () {
    test('TurnResolutionComplete holds game', () {
      final result = TurnResolutionComplete(minimalGame);
      expect(result.game, minimalGame);
    });

    test('TurnResolutionPendingOvertures holds game and list', () {
      final offers = [
        OvertureOffer(
          offererGpId: 'gp1',
          targetFactionId: 'gp2',
          stage: OvertureStage.embassy,
        ),
      ];
      final result = TurnResolutionPendingOvertures(
        game: minimalGame,
        pendingOvertures: offers,
      );
      expect(result.game, minimalGame);
      expect(result.pendingOvertures, offers);
    });
  });
}
