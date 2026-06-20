// formatDiplomaticEvent — all [DiplomaticEventType] branches. SPEC/ui/diplomacy-panel.md.
import 'package:colonizethis_app/features/game/screens/diplomacy_detail_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  const humanId = 'human_gp';
  const otherId = 'other_gp';

  Game minimalGame({List<DiplomaticEvent> history = const []}) {
    return Game(
      id: 'fmt',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      turnTimeMapping: TurnTimeMapping.gdd01,
      players: const [
        Player(id: humanId, displayName: 'England', isHuman: true, treasury: 0),
        Player(id: otherId, displayName: 'France', isHuman: false, treasury: 0),
      ],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: humanId,
          factionId2: otherId,
          score: 50,
          state: RelationState.atPeace,
        ),
      ],
      diplomaticHistoryEvents: history,
    );
  }

  DiplomaticEvent ev(
    DiplomaticEventType type, {
    String? fromId,
    String? toId,
    OvertureStage? stage,
    int? amount,
    String? reason,
  }) {
    return DiplomaticEvent(
      turn: 1,
      intraTurnIndex: 0,
      type: type,
      participants: {humanId, otherId},
      fromFactionId: fromId ?? humanId,
      toFactionId: toId ?? otherId,
      overtureStage: stage,
      amount: amount,
      reason: reason,
    );
  }

  test('declareWar', () {
    final g = minimalGame();
    final s = formatDiplomaticEvent(
      ev(DiplomaticEventType.declareWar),
      g,
      humanId,
    );
    expect(s, contains('declared war'));
  });

  test('peace', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(ev(DiplomaticEventType.peace), g, humanId),
      contains('peace'),
    );
  });

  test('allianceFormed', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(ev(DiplomaticEventType.allianceFormed), g, humanId),
      contains('alliance'),
    );
  });

  test('allianceBroken', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(ev(DiplomaticEventType.allianceBroken), g, humanId),
      contains('Alliance'),
    );
  });

  test('overtureAccepted with stage', () {
    final g = minimalGame();
    final s = formatDiplomaticEvent(
      ev(DiplomaticEventType.overtureAccepted, stage: OvertureStage.embassy),
      g,
      humanId,
    );
    expect(s, contains('Embassy'));
  });

  test('overtureRejected', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(
        ev(DiplomaticEventType.overtureRejected, stage: OvertureStage.nap),
        g,
        humanId,
      ),
      contains('rejected'),
    );
  });

  test('joinEmpireResolved', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(
        ev(DiplomaticEventType.joinEmpireResolved),
        g,
        humanId,
      ),
      contains('absorbed'),
    );
  });

  test('grantAidApplied', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(
        ev(DiplomaticEventType.grantAidApplied, amount: 100),
        g,
        humanId,
      ),
      contains('100'),
    );
  });

  test('subsidySet', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(
        ev(DiplomaticEventType.subsidySet, amount: 5),
        g,
        humanId,
      ),
      contains('5'),
    );
  });

  test('subsidyUpdated', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(
        ev(DiplomaticEventType.subsidyUpdated, amount: 7),
        g,
        humanId,
      ),
      contains('7'),
    );
  });

  test('subsidyCancelled', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(
        ev(DiplomaticEventType.subsidyCancelled, reason: 'treasury'),
        g,
        humanId,
      ),
      contains('treasury'),
    );
  });

  test('interventionIntervene', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(
        ev(DiplomaticEventType.interventionIntervene),
        g,
        humanId,
      ),
      contains('intervened'),
    );
  });

  test('interventionDoNothing', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(
        ev(DiplomaticEventType.interventionDoNothing),
        g,
        humanId,
      ),
      contains('did not intervene'),
    );
  });

  test('interventionProtest', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(
        ev(DiplomaticEventType.interventionProtest),
        g,
        humanId,
      ),
      contains('protested'),
    );
  });

  test('agreementsClearedOnWar', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(
        ev(DiplomaticEventType.agreementsClearedOnWar),
        g,
        humanId,
      ),
      contains('war'),
    );
  });

  test('callToArmsAccepted', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(
        ev(DiplomaticEventType.callToArmsAccepted),
        g,
        humanId,
      ),
      contains('joined the war'),
    );
  });

  test('callToArmsRefused', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(
        ev(DiplomaticEventType.callToArmsRefused),
        g,
        humanId,
      ),
      contains('refused call to arms'),
    );
  });

  test('ftpFormed', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(
        ev(DiplomaticEventType.ftpFormed),
        g,
        humanId,
      ),
      contains('free trade partnership'),
    );
  });

  test('ftpBroken', () {
    final g = minimalGame();
    expect(
      formatDiplomaticEvent(
        ev(DiplomaticEventType.ftpBroken, reason: 'war'),
        g,
        humanId,
      ),
      contains('ended (war)'),
    );
  });
}
